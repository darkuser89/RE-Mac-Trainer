#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Read exact Mac RE4 TDB73 type/field identities and method signatures only.

Header/parameter format reference: praydog/REFramework shared/sdk/RETypeDB.hpp.
No game starts, debugger, memory writes, or assumptions about a live call ABI.
"""
import argparse,json,mmap,re,struct
from pathlib import Path
from re2_metadata import Image,Database,InvalidImage

def inspect_tdb73(app,patterns,bundle,executable,expected_uuid,version=73,extra_ids=()):
    import plistlib
    info=plistlib.loads((app/'Contents/Info.plist').read_bytes())
    if info.get('CFBundleIdentifier')!=bundle or info.get('CFBundleExecutable')!=executable:
        raise InvalidImage('Unexpected Mac game identity')
    with (app/'Contents/MacOS'/executable).open('rb') as f:
        with mmap.mmap(f.fileno(),0,access=mmap.ACCESS_READ) as mem:
            image=Image(mem)
            if image.uuid!=expected_uuid:raise InvalidImage('Unverified executable UUID')
            d=Database(image,version)
            ids={i for i,n in d.names.items() if any(re.search(p,n) for p in patterns)}
            if any(i not in d.names for i in extra_ids):raise InvalidImage('Requested type index outside table')
            ids.update(extra_ids)
            for i in list(ids):
                for _ in range(64):
                    parent=(image.u64(d.types+i*d.type_stride)>>19)&0x7ffff
                    if not parent or parent==i:break
                    ids.add(parent);i=parent
            names={d.names[i] for i in ids};pool=d.base+image.u64(d.base+0xd8);params=d.base+image.u64(d.base+0xa8)
            entries=[]
            for member in d.members():
                row=dict(member)
                if row['kind']=='method':
                    a,b,_=image.unpack('<III',d.methods+row['index']*12);p=((b>>19)<<13)|(a>>19)
                    row['ownerTypeIndex']=a&0x7ffff
                    if row['ownerTypeIndex'] not in ids:continue
                    impl=d.method_impl+(b&0x7ffff)*12
                    row['flags']=image.unpack('<H',impl+4)[0]
                    row['vtable']=image.unpack('<h',impl+2)[0]
                    count,invoke,ret=image.unpack('<HHI',pool+p)
                    if count>128:raise InvalidImage('Unreasonable parameter count')
                    indices=[ret]+list(image.unpack('<'+'I'*count,pool+p+8));signature=[]
                    for index in indices:
                        index&=0x3ffff
                        image.bounds(params+index*12,12)
                        t=image.u32(params+index*12+8)&0x7ffff
                        signature.append({'typeIndex':t,'type':d.names.get(t),'name':d.string(image.u32(params+index*12+4)&0x3fffffff)})
                    row['return']=signature[0];row['parameters']=signature[1:]
                else:
                    bits=image.u64(d.fields+row['index']*8);row['ownerTypeIndex']=bits&0x7ffff
                    if row['ownerTypeIndex'] not in ids:continue
                    t=(bits>>38)&0x7ffff;row['fieldTypeIndex']=t;row['fieldType']=d.names.get(t)
                    impl=d.field_impl+((bits>>19)&0x7ffff)*12
                    row['flags']=image.unpack('<H',impl+2)[0]>>1
                    row['initDataIndex']=(((bits>>57)&63)<<10)|((image.u32(impl+8)>>28)<<6)|(image.u32(impl+4)>>26)
                    if row['flags']&0x40:
                        count=image.u32(d.base+0x38);initial=d.base+image.u64(d.base+0xb8)
                        if row['initDataIndex']>=count:raise InvalidImage('Literal init-data index outside table')
                        offset=image.unpack('<i',initial+row['initDataIndex']*4)[0]
                        if offset>=0:
                            bytepool=d.base+image.u64(d.base+0xd8)
                            row['literalUInt32']=image.u32(bytepool+offset)
                entries.append(row)
            return {'uuid':image.uuid,'tdbVersion':version,'typeStride':d.type_stride,'database':{'address':image.virtual_address(d.base),'typeCount':d.type_count,'methodCount':d.method_count,'fieldCount':d.field_count,'typesOffset':d.types-d.base,'methodsOffset':d.methods-d.base},'types':d.names,'parents':{i:(image.u64(d.types+i*d.type_stride)>>19)&0x7ffff for i in ids},'members':entries,'scope':'Static metadata; no live effect or callable ABI verification.'}
def inspect(app,patterns):
    return inspect_tdb73(app,patterns,'jp.co.capcom.RE4US','Resident Evil 4','4C4C44CF-5555-3144-A161-D64EFB82E79F')

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('app',type=Path);p.add_argument('--type',action='append',required=True);a=p.parse_args()
    try:print(json.dumps(inspect(a.app,a.type),ensure_ascii=False))
    except (InvalidImage,OSError,ValueError,struct.error) as e:p.exit(1,f'{e}\n')
