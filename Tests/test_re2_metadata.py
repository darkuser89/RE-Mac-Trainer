#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Synthetic malformed-image tests. No game launch or game-memory access."""
import json
import struct
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'script'))
from re2_metadata import Image, Database, InvalidImage


def fixture():
    data = bytearray(4096)
    struct.pack_into('<8I', data, 0, 0xfeedfacf, 0x100000c, 0, 2, 2, 96, 0, 0)
    struct.pack_into('<II16s', data, 32, 0x1b, 24, bytes(range(16)))
    struct.pack_into('<II16s4Q4I', data, 56, 0x19, 72, b'__DATA', 0x100000000, 4096, 0, 4096, 3, 3, 0, 0)
    base = 512
    data[base:base + 8] = b'TDB\0\x4a\0\0\0'
    for off in (8, 0x14, 0x18, 0x1c, 0x20, 0x24):
        struct.pack_into('<I', data, base + off, 1)
    for off, value in ((0x68,0x100),(0x70,0x150),(0x78,0x180),(0x80,0x18c),(0x88,0x1a0),(0x90,0x1a8),(0xd8,0x200)):
        struct.pack_into('<Q', data, base + off, value)
    pool = b'\0Sample\0app.test\0get_Value\0Value\0'
    struct.pack_into('<I', data, base + 0x54, len(pool))
    data[base + 0x200:base + 0x200 + len(pool)] = pool
    struct.pack_into('<II', data, base + 0x150, 1, 8)
    struct.pack_into('<I', data, base + 0x18c + 8, 0x10000011)
    struct.pack_into('<II', data, base + 0x1a8 + 4, 24, 27)
    return data


class MetadataTests(unittest.TestCase):
    def test_tdb71_initialized_is_not_type_count(self):
        data = fixture();base = 512
        struct.pack_into('<IIII',data,base,0x424454,71,0,1)
        for off in (0x10,0x14,0x18,0x1c,0x20):
            struct.pack_into('<I',data,base+off,1)
        for off,value in ((0x60,0x100),(0x68,0x150),(0x70,0x180),(0x78,0x18c),(0x80,0x1a0),(0x88,0x1a8),(0xd0,0x200)):
            struct.pack_into('<Q',data,base+off,value)
        struct.pack_into('<I',data,base+0x50,33)
        db=Database(Image(data),71)
        self.assertEqual(db.type_count,1)
        self.assertEqual(db.type_stride,72)
        self.assertEqual(db.names[0],'app.test.Sample')
        self.assertEqual(list(db.members())[0]['name'],'get_Value')
        struct.pack_into('<I',data,base+8,1)
        self.assertEqual(Database(Image(data),71).names,db.names)

    def test_tdb73_header_and_mac_stride_are_separate(self):
        data = fixture();base = 512
        struct.pack_into('<I', data, base + 4, 73)
        for off in (0x10, 0x14, 0x18, 0x1c, 0x20):
            struct.pack_into('<I', data, base + off, 1)
        for off,value in ((0x60,0x100),(0x68,0x150),(0x70,0x180),(0x78,0x18c),(0x80,0x1a0),(0x88,0x1a8),(0xd0,0x200)):
            struct.pack_into('<Q', data, base + off, value)
        struct.pack_into('<I', data, base + 0x50, 33)
        db = Database(Image(data), 73)
        self.assertEqual(db.type_stride, 72)
        self.assertEqual(db.names[0], 'app.test.Sample')
        self.assertEqual(list(db.members())[0]['name'], 'get_Value')
        with self.assertRaises(InvalidImage):Database(Image(data))
    def test_valid_fixture_and_method_name_flags(self):
        image = Image(fixture())
        self.assertEqual(image.virtual_address(512), 0x100000200)
        db = Database(image)
        self.assertEqual(db.names[0], 'app.test.Sample')
        method, field = list(db.members())
        self.assertEqual(method['name'], 'get_Value')
        self.assertEqual(field['name'], 'Value')
        self.assertEqual(field['metadataOffset'], 24)

    def test_truncated_headers(self):
        for length in (0, 4, 31, 40, 80, 127):
            with self.subTest(length=length), self.assertRaises(InvalidImage):
                Image(fixture()[:length])

    def test_bad_command(self):
        data = fixture();struct.pack_into('<I', data, 36, 7)
        with self.assertRaises(InvalidImage):Image(data)

    def test_non_arm64(self):
        data = fixture();struct.pack_into('<I', data, 4, 0x1000007)
        with self.assertRaises(InvalidImage):Image(data)

    def test_duplicate_database(self):
        data = fixture();data[3000:3008] = b'TDB\0\x4a\0\0\0'
        with self.assertRaises(InvalidImage):Database(Image(data))

    def test_oversize_table(self):
        data = fixture();struct.pack_into('<I', data, 512 + 8, 0xffffffff)
        with self.assertRaises(InvalidImage):Database(Image(data))

    def test_invalid_table_pointer(self):
        data = fixture();struct.pack_into('<Q', data, 512 + 0x78, 0xffffffffffffffff)
        with self.assertRaises(InvalidImage):Database(Image(data))

    def test_field_outside_table(self):
        data = fixture();struct.pack_into('<Q', data, 512 + 0x1a0, 2 << 19)
        with self.assertRaises(InvalidImage):list(Database(Image(data)).members())

    def test_unterminated_string(self):
        data = fixture();data[512 + 0x200 + 7] = 88
        struct.pack_into('<I', data, 512 + 0x54, 7)
        with self.assertRaises(InvalidImage):Database(Image(data))

    def test_twenty_reference_features_and_exact_native_profile(self):
        root = Path(__file__).resolve().parents[1]
        features = json.loads((root / 'Resources/RE2FeaturePlan.json').read_text())['features']
        self.assertEqual(len(features), 20)
        self.assertEqual(len({f['id'] for f in features}), 20)
        config = json.loads((root / 'Resources/TrainerConfig.json').read_text())
        profiles = {p['id']: p for p in config['profiles']}
        self.assertEqual(len(profiles), len(config['profiles']))
        re2 = profiles['re2-mac-1.0.2']
        self.assertEqual(re2['bundleIdentifier'], 'jp.co.capcom.RE2US')
        self.assertEqual(re2['uuids'], ['4C4C44ED-5555-3144-A15E-9285028AFD15'])
        self.assertEqual(re2['version'], '1.0.2')
        re3 = profiles['re3-mac-1.0.0']
        self.assertEqual(re3['bundleIdentifier'], 'jp.co.capcom.RE3US')
        self.assertEqual(re3['uuids'], ['4C4C4461-5555-3144-A174-EA43301DB10B'])
        self.assertFalse(set(re2['uuids']) & set(re3['uuids']))

    def test_declaring_type_outside_table(self):
        data = fixture()
        struct.pack_into('<Q', data, 512 + 0x100, 2 << 38)
        with self.assertRaises(InvalidImage):Database(Image(data))

    def test_live_debugger_reader_is_disabled_before_target_access(self):
        import re2_lldb_read
        class ForbiddenDebugger:
            def GetSelectedTarget(self):
                raise AssertionError('The disabled reader must not access a target')
        with self.assertRaisesRegex(RuntimeError, 'Live LLDB snapshots disabled'):
            re2_lldb_read.snapshot(ForbiddenDebugger(), '/missing/evidence', '/missing/output')


if __name__ == '__main__':unittest.main()
