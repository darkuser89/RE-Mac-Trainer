#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
# Package the current checked build; never start or modify a game.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$(python3 - "$ROOT" "${MT_TRAINER_BUILD_DIR:-$ROOT/../RE2TrainerBuild}" <<'PY'
from pathlib import Path
import sys
source, build = (Path(s).expanduser().resolve() for s in sys.argv[1:])
if source == build or source in build.parents:
    raise SystemExit('Build folder must be outside source.')
print(build)
PY
)"
NAME="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["app"]["name"])' "$ROOT/Resources/TrainerConfig.json")"
APP="$BUILD/$NAME.app"
[[ -d "$APP" ]] || { echo 'Build the app first.' >&2; exit 1; }
STAGE="$(mktemp -d "$BUILD/.package.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
ZIP='Resident-Evil-Trainer-macOS-arm64.zip'
codesign --verify --deep --strict "$APP"
[[ "$(lipo -archs "$APP/Contents/MacOS/MacTrainer")" == arm64 ]]
ditto -c -k --sequesterRsrc --keepParent "$APP" "$STAGE/$ZIP"
mkdir "$STAGE/unpacked"
ditto -x -k "$STAGE/$ZIP" "$STAGE/unpacked"
codesign --verify --deep --strict "$STAGE/unpacked/$NAME.app"
"$STAGE/unpacked/$NAME.app/Contents/MacOS/MacTrainer" --check-launcher
python3 -B - "$ROOT" "$APP" "$STAGE" "$ZIP" "${MT_RELEASE_COMMIT:-}" <<'PY'
from pathlib import Path
import hashlib,json,plistlib,re,subprocess,sys,zipfile
root,app,stage=map(Path,sys.argv[1:4])
zip_name,commit=sys.argv[4:]
if not commit:
    result=subprocess.run(['git','-C',str(root),'rev-parse','--verify','HEAD'],capture_output=True,text=True)
    commit=result.stdout.strip() if result.returncode==0 else 'uncommitted'
if commit!='uncommitted' and not re.fullmatch(r'[0-9a-f]{40}',commit):
    raise SystemExit('Invalid source commit.')
config=json.loads((root/'Resources/TrainerConfig.json').read_text())['app']
info=plistlib.loads((app/'Contents/Info.plist').read_bytes())
assert info['CFBundleIdentifier']==config['bundleIdentifier']
assert info['CFBundleShortVersionString']==config['version']
assert info['CFBundleVersion']==config['build']
with zipfile.ZipFile(stage/zip_name) as archive:
    assert archive.testzip() is None
    assert f"{app.name}/Contents/MacOS/MacTrainer" in archive.namelist()
    assert all(not n.startswith('/') and '..' not in Path(n).parts for n in archive.namelist())
release={'name':config['name'],'version':config['version'],'build':config['build'],
         'commit':commit,'architecture':'arm64','minimumMacOS':info['LSMinimumSystemVersion'],
         'signing':'ad-hoc, not notarized','archive':zip_name}
(stage/'release-info.json').write_text(json.dumps(release,ensure_ascii=False,indent=2)+'\n')
names=[zip_name,'release-info.json']
(stage/'SHA256SUMS').write_text(''.join(hashlib.sha256((stage/n).read_bytes()).hexdigest()+'  '+n+'\n' for n in names))
print(json.dumps(release,ensure_ascii=False))
PY
mkdir -p "$BUILD/Release"
for asset in "$ZIP" release-info.json SHA256SUMS; do
    mv -f "$STAGE/$asset" "$BUILD/Release/$asset"
done
printf 'Verified release package: %s/Release/%s\n' "$BUILD" "$ZIP"
