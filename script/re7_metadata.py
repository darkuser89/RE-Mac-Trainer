#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Read exact Mac RE7 1.0.4 TDB73 declarations. No launch or memory writes."""
import argparse,json,struct
from pathlib import Path
from re4_metadata import inspect_tdb73
from re2_metadata import InvalidImage

def inspect(app,patterns):
    return inspect_tdb73(app,patterns,'jp.co.capcom.RE7US','RESIDENT EVIL 7 biohazard','4C4C4466-5555-3144-A1F6-0D461A1E2960')
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('app',type=Path);p.add_argument('--type',action='append',required=True);a=p.parse_args()
    try:print(json.dumps(inspect(a.app,a.type),ensure_ascii=False))
    except (InvalidImage,OSError,ValueError,struct.error) as e:p.exit(1,f'{e}\n')
