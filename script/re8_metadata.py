#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Read exact Mac Village 1.1.8 TDB71 metadata without launching the game."""
import argparse,json,struct
from pathlib import Path
from re4_metadata import inspect_tdb73
from re2_metadata import InvalidImage

def inspect(app,patterns,extra_ids=()):
    return inspect_tdb73(app,patterns,'jp.co.capcom.VillageUS','Resident Evil Village',
                         '4C4C44EB-5555-3144-A1A1-B2C9A3FC8945',version=71,extra_ids=extra_ids)

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('app',type=Path);p.add_argument('--type',action='append',default=[]);p.add_argument('--id',type=int,action='append',default=[]);a=p.parse_args()
    try:print(json.dumps(inspect(a.app,a.type,a.id),ensure_ascii=False))
    except (InvalidImage,OSError,ValueError,struct.error) as e:p.exit(1,f'{e}\n')
