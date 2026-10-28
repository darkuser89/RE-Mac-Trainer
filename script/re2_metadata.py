#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Read RE2 Mach-O/TDB metadata. Never attaches, launches, or writes to a game.

TDB format reference: https://github.com/praydog/REFramework/blob/master/shared/sdk/RETypeDB.hpp
This Mac build adds flags to method-name offsets. Values here are metadata,
not validated live addresses or a callable game ABI.
"""
import argparse
import json
import mmap
import plistlib
import struct
import uuid
from pathlib import Path


class InvalidImage(ValueError):
    pass


class Image:
    def __init__(self, data):
        self.data = data
        self.uuid = None
        self.segments = []
        if self.unpack('<I', 0)[0] != 0xfeedfacf:
            raise InvalidImage('Expected thin 64-bit Mach-O')
        _, cpu, _, kind, count, size, _, _ = self.unpack('<8I', 0)
        if cpu != 0x100000c or kind != 2 or count > 4096 or size > 1024 * 1024:
            raise InvalidImage('Expected arm64 executable with bounded load commands')
        self.bounds(32, size)
        offset = 32
        for _ in range(count):
            command, length = self.unpack('<II', offset)
            if length < 8 or offset + length > 32 + size:
                raise InvalidImage('Invalid load-command size')
            if command == 0x1b:
                if length != 24 or self.uuid:
                    raise InvalidImage('Invalid or repeated UUID command')
                self.uuid = str(uuid.UUID(bytes=bytes(data[offset + 8:offset + 24]))).upper()
            if command == 0x19:
                if length < 72:
                    raise InvalidImage('Truncated segment')
                name = bytes(data[offset + 8:offset + 24]).split(b'\0')[0].decode('ascii')
                address, vm_size, file_offset, file_size = self.unpack('<4Q', offset + 24)
                self.bounds(file_offset, file_size)
                self.segments.append((name, address, vm_size, file_offset, file_size))
            offset += length
        if offset != 32 + size or not self.uuid:
            raise InvalidImage('Incomplete load commands or missing UUID')

    def bounds(self, offset, size):
        if offset < 0 or size < 0 or offset > len(self.data) or size > len(self.data) - offset:
            raise InvalidImage('Out-of-bounds metadata')

    def unpack(self, fmt, offset):
        self.bounds(offset, struct.calcsize(fmt))
        return struct.unpack_from(fmt, self.data, offset)

    def u32(self, offset):
        return self.unpack('<I', offset)[0]

    def u64(self, offset):
        return self.unpack('<Q', offset)[0]

    def virtual_address(self, offset):
        for _, address, _, file_offset, file_size in self.segments:
            if file_offset <= offset < file_offset + file_size:
                return address + offset - file_offset
        raise InvalidImage('Metadata is outside file-backed segments')


class Database:
    def __init__(self, image, version=74):
        self.image = image
        if version not in (71, 73, 74):
            raise InvalidImage('Unsupported TDB version')
        tag = b'TDB\0' + struct.pack('<I', version)
        self.base = image.data.find(tag)
        if self.base < 0 or image.data.find(tag, self.base + 8) >= 0:
            raise InvalidImage(f'Expected one TDB version {version} header')
        self.version = version
        # TDB71 retains initialized at +8 and numTypes at +12. TDB73
        # replaces them with numTypes/start-of-generics; the later tables
        # have identical offsets. Both use 72-byte type rows on these Macs.
        delta = -4 if version in (71, 73) else 0
        table_delta = -8 if version in (71, 73) else 0
        self.type_stride = 72 if version in (71, 73) else 80
        image.bounds(self.base, 0xf0)
        self.type_count = image.u32(self.base + (12 if version == 71 else 8))
        self.type_impl_count = image.u32(self.base + 0x1c + delta)
        self.method_count = image.u32(self.base + 0x14 + delta)
        self.method_impl_count = image.u32(self.base + 0x24 + delta)
        self.field_count = image.u32(self.base + 0x18 + delta)
        self.field_impl_count = image.u32(self.base + 0x20 + delta)
        self.types = self.table(0x68 + table_delta, self.type_count, self.type_stride)
        self.type_impl = self.table(0x70 + table_delta, self.type_impl_count, 48)
        self.methods = self.table(0x78 + table_delta, self.method_count, 12)
        self.method_impl = self.table(0x80 + table_delta, self.method_impl_count, 12)
        self.fields = self.table(0x88 + table_delta, self.field_count, 8)
        self.field_impl = self.table(0x90 + table_delta, self.field_impl_count, 12)
        self.pool_size = image.u32(self.base + 0x54 + delta)
        self.pool = self.base + image.u64(self.base + 0xd8 + table_delta)
        image.bounds(self.pool, self.pool_size)
        self.names = {}
        self.leaf_names = {}
        self.declaring_types = {}
        for index in range(self.type_count):
            row = self.types + index * self.type_stride
            if image.u64(row) & 0x7ffff != index:
                raise InvalidImage('Type index validation failed')
            impl = (image.u64(row + 8) >> 38) & 0x3ffff
            if impl >= self.type_impl_count:
                raise InvalidImage('Type implementation index outside table')
            name, namespace = image.unpack('<II', self.type_impl + impl * 48)
            name, namespace = self.string(name), self.string(namespace)
            self.leaf_names[index] = name
            self.declaring_types[index] = (image.u64(row) >> 38) & 0x7ffff
            self.names[index] = f'{namespace}.{name}' if namespace else name
        resolved = {}
        def resolve(index, seen):
            if index in resolved:
                return resolved[index]
            if index in seen or len(seen) > 32:
                raise InvalidImage('Nested type declaration cycle')
            declaring = self.declaring_types[index]
            if declaring and declaring != index:
                if declaring >= self.type_count:
                    raise InvalidImage('Declaring type outside table')
                value = resolve(declaring, seen | {index}) + '.' + self.leaf_names[index]
            else:
                value = self.names[index]
            resolved[index] = value
            return value
        self.names = {index: resolve(index, set()) for index in self.names}

    def table(self, offset, count, stride):
        if not 0 < count <= 2000000:
            raise InvalidImage('Unreasonable table count')
        start = self.base + self.image.u64(self.base + offset)
        self.image.bounds(start, count * stride)
        return start

    def string(self, offset):
        offset &= 0xfffffff
        if offset >= self.pool_size:
            raise InvalidImage('String outside pool')
        start = self.pool + offset
        end = self.image.data.find(b'\0', start, min(start + 4096, self.pool + self.pool_size))
        if end < 0:
            raise InvalidImage('Unterminated metadata string')
        try:
            return bytes(self.image.data[start:end]).decode('utf-8')
        except UnicodeDecodeError as error:
            raise InvalidImage('Invalid UTF-8 metadata string') from error

    def members(self):
        im = self.image
        for index in range(self.method_count):
            owner, impl, encoded = im.unpack('<III', self.methods + index * 12)
            owner &= 0x7ffff
            impl &= 0x7ffff
            if owner >= self.type_count or impl >= self.method_impl_count:
                raise InvalidImage('Method index outside table')
            name = self.string(im.u32(self.method_impl + impl * 12 + 8))
            yield {'kind': 'method', 'type': self.names[owner], 'name': name,
                   'index': index, 'encodedOffset': encoded}
        for index in range(self.field_count):
            bits = im.u64(self.fields + index * 8)
            owner, impl = bits & 0x7ffff, (bits >> 19) & 0x7ffff
            if owner >= self.type_count or impl >= self.field_impl_count:
                raise InvalidImage('Field index outside table')
            row = self.field_impl + impl * 12
            name = self.string(im.u32(row + 8))
            yield {'kind': 'field', 'type': self.names[owner], 'name': name,
                   'index': index, 'metadataOffset': im.u32(row + 4) & 0x3ffffff}


def inspect(app, catalog):
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    executable = info.get('CFBundleExecutable', '')
    if not executable or '/' in executable or executable in ('.', '..'):
        raise InvalidImage('Invalid executable filename')
    with (app / 'Contents/MacOS' / executable).open('rb') as file:
        with mmap.mmap(file.fileno(), 0, access=mmap.ACCESS_READ) as data:
            image = Image(data)
            database = Database(image)
            members = list(database.members())
            results = []
            import re
            for feature in catalog['features']:
                patterns = [re.compile(pattern, re.I) for pattern in feature['metadataPatterns']]
                matches = [member for member in members if any(pattern.search(member['type'] + '.' + member['name']) for pattern in patterns)]
                results.append({'id': feature['id'], 'title': feature['title'],
                                'matchingMetadataEntries': len(matches), 'entries': matches[:12],
                                'ingameVerified': False, 'implemented': False})
            return {'bundleIdentifier': info.get('CFBundleIdentifier'),
                    'version': info.get('CFBundleShortVersionString'), 'executable': executable,
                    'architecture': 'arm64', 'uuid': image.uuid, 'tdbVersion': 74,
                    'tdbFileOffset': hex(database.base),
                    'tdbUnslidAddress': hex(image.virtual_address(database.base)),
                    'typeCount': database.type_count, 'methodCount': database.method_count,
                    'fieldCount': database.field_count, 'features': results,
                    'scope': 'Static metadata only; matching names do not establish cheat feasibility, live layout, or a callable ABI.'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    args = parser.parse_args()
    catalog = json.loads((Path(__file__).resolve().parents[1] / 'Resources/RE2FeaturePlan.json').read_text())
    try:
        print(json.dumps(inspect(args.app, catalog), ensure_ascii=False, indent=2))
    except (InvalidImage, OSError, ValueError, struct.error) as error:
        parser.exit(1, f'Inspection failed: {error}\n')
