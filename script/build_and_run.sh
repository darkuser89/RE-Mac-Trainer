#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:---build-only}"
case "$MODE" in --build-only|--update-only|run) ;; *) echo 'Usage: build_and_run.sh [--build-only|--update-only|run]'; exit 2;; esac
BUNDLE_ID="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["app"]["bundleIdentifier"])' "$ROOT/Resources/TrainerConfig.json")"
NAME="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["app"]["name"])' "$ROOT/Resources/TrainerConfig.json")"
BUILD="$(python3 - "$ROOT" "${MT_TRAINER_BUILD_DIR:-$ROOT/../RE2TrainerBuild}" "$NAME" "$BUNDLE_ID" <<'CHECK'
from pathlib import Path
import re,sys
source,build=map(lambda s:Path(s).expanduser().resolve(),sys.argv[1:3])
name,bundle=sys.argv[3:]
if source==build or source in build.parents:raise SystemExit('Build folder must be outside source.')
if not name or any(c in name for c in '/\\\n\r'):raise SystemExit('Invalid app name.')
if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9.-]+',bundle):raise SystemExit('Invalid bundle identifier.')
print(build)
CHECK
)"
mkdir -p "$BUILD"
APP="$BUILD/$NAME.app"
if [[ -d "$APP" ]]; then
    ID="$(plutil -extract CFBundleIdentifier raw "$APP/Contents/Info.plist")"
    [[ "$ID" == "$BUNDLE_ID" ]] || { echo 'Unexpected bundle at build target.' >&2; exit 1; }
fi
STAGE="$(mktemp -d "$BUILD/.stage.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
CANDIDATE="$STAGE/$NAME.app"
mkdir -p "$CANDIDATE/Contents/MacOS" "$CANDIDATE/Contents/Resources"
FLAGS=(-arch arm64 -mmacosx-version-min=14.0 -fobjc-arc -O1 -Wall -Wextra -Werror "-ffile-prefix-map=$ROOT=." -I"$ROOT/Sources")
ENGINE=("$ROOT/Sources/GameProfile.m" "$ROOT/Sources/MemoryAccess.m" "$ROOT/Sources/RE2Engine.m" "$ROOT/Sources/RE4Engine.m" "$ROOT/Sources/RE7Engine.m" "$ROOT/Sources/RE8Engine.m")
CORE=("$ROOT/Sources/LocalControl.m" "$ROOT/Sources/CheatPreferences.m" "$ROOT/Sources/TrainerFeatures.m" "$ROOT/Sources/RE4Features.m" "$ROOT/Sources/RE7Features.m" "$ROOT/Sources/GameAdapter.m" "$ROOT/Sources/GameBridge.m" "$ROOT/Sources/RE2Adapter.m" "$ROOT/Sources/RE3Adapter.m" "$ROOT/Sources/RE4Adapter.m" "$ROOT/Sources/RE7Adapter.m" "$ROOT/Sources/RE2Ownership.m" "$ROOT/Sources/RE7Ownership.m" "$ROOT/Sources/RE8Ownership.m" "$ROOT/Sources/RE8Adapter.m" "$ROOT/Sources/RE8Features.m")
UI=("$ROOT/Sources/TrainerMaterial.m" "$ROOT/Sources/Overlay.m" "$ROOT/Sources/OverlaySettings.m" "$ROOT/Sources/OverlayShortcuts.m")
FRAMEWORKS=(-framework AppKit -framework Security -framework QuartzCore -framework Carbon)
python3 -B "$ROOT/Tests/test_re2_metadata.py"
xcrun clang "${FLAGS[@]}" -framework Foundation -dynamiclib "$ROOT/Sources/RE2ReadOnlyProbe.m" "$ROOT/Sources/RE4ReadOnlyProbe.m" "$ROOT/Sources/RE7ReadOnlyProbe.m" "$ROOT/Sources/RE8ReadOnlyProbe.m" -install_name @rpath/RE2ReadOnlyProbe.dylib -o "$CANDIDATE/Contents/Resources/RE2ReadOnlyProbe.dylib"
codesign --force --sign - --timestamp=none "$CANDIDATE/Contents/Resources/RE2ReadOnlyProbe.dylib"
xcrun clang "${FLAGS[@]}" "${FRAMEWORKS[@]}" -dynamiclib "${ENGINE[@]}" -install_name @rpath/TrainerOverlay.dylib -o "$CANDIDATE/Contents/Resources/TrainerOverlay.dylib"
codesign --force --sign - --timestamp=none "$CANDIDATE/Contents/Resources/TrainerOverlay.dylib"
xcrun clang "${FLAGS[@]}" "${FRAMEWORKS[@]}" -dynamiclib "${CORE[@]}" "${UI[@]}" "$ROOT/Sources/Runtime.m" "$CANDIDATE/Contents/Resources/TrainerOverlay.dylib" -Wl,-rpath,@loader_path -install_name @rpath/RE2TrainerRuntime.dylib -o "$CANDIDATE/Contents/Resources/RE2TrainerRuntime.dylib"
codesign --force --sign - --timestamp=none "$CANDIDATE/Contents/Resources/RE2TrainerRuntime.dylib"
# The ad-hoc hardened launcher cannot load an ad-hoc private dylib under
# library validation. Link its own backend statically; keep protections intact.
xcrun clang "${FLAGS[@]}" "${FRAMEWORKS[@]}" -framework UniformTypeIdentifiers "${ENGINE[@]}" "${CORE[@]}" "${UI[@]}" "$ROOT/Sources/RE2ProbeLaunch.m" "$ROOT/Sources/Launcher.m" -o "$CANDIDATE/Contents/MacOS/MacTrainer"
cp "$ROOT/Resources/TrainerConfig.json" "$CANDIDATE/Contents/Resources/TrainerConfig.json"
cp "$ROOT/LICENSE" "$CANDIDATE/Contents/Resources/LICENSE"
python3 - "$ROOT/Resources/TrainerConfig.json" "$CANDIDATE/Contents/Info.plist" <<'PLIST'
from pathlib import Path
import json,plistlib,sys
app=json.loads(Path(sys.argv[1]).read_text())["app"]
Path(sys.argv[2]).write_bytes(plistlib.dumps({'CFBundleIdentifier':app['bundleIdentifier'],'CFBundleExecutable':'MacTrainer','CFBundleName':app['name'],'CFBundlePackageType':'APPL','CFBundleShortVersionString':app['version'],'CFBundleVersion':app['build'],'LSMinimumSystemVersion':'14.0','NSPrincipalClass':'NSApplication','NSHighResolutionCapable':True}))
PLIST
if [[ -f "$ROOT/Resources/AppIcon.png" ]]; then
    ICONSET="$STAGE/AppIcon.iconset"; mkdir -p "$ICONSET"
    for spec in '16:icon_16x16' '32:icon_16x16@2x' '32:icon_32x32' '64:icon_32x32@2x' '128:icon_128x128' '256:icon_128x128@2x' '256:icon_256x256' '512:icon_256x256@2x' '512:icon_512x512' '1024:icon_512x512@2x'; do
        size="${spec%%:*}"
        sips --resampleHeightWidth "$size" "$size" -s format png "$ROOT/Resources/AppIcon.png" --out "$ICONSET/${spec#*:}.png" >/dev/null
    done
    iconutil --convert icns "$ICONSET" --output "$CANDIDATE/Contents/Resources/AppIcon.icns"
    plutil -insert CFBundleIconFile -string AppIcon.icns "$CANDIDATE/Contents/Info.plist"
fi
codesign --force --sign - --options runtime --timestamp=none "$CANDIDATE"
codesign --verify --deep --strict "$CANDIDATE"
"$CANDIDATE/Contents/MacOS/MacTrainer" --check-launcher
xcrun clang "${FLAGS[@]}" "${FRAMEWORKS[@]}" "${ENGINE[@]}" "${CORE[@]}" "${UI[@]}" "$ROOT/Tests/Fixtures/TestAdapter.m" "$ROOT/Tests/RE7OwnershipTests.m" "$ROOT/Tests/LocalControlTests.m" "$ROOT/Tests/PresentationTests.m" "$ROOT/Tests/TestMain.m" -I"$ROOT/Tests/Fixtures" -o "$STAGE/TemplateTests"
"$STAGE/TemplateTests" "$ROOT/Resources/TrainerConfig.json"
# Fresh processes exercise each real bundle-selected catalog without games.
FIXTURE="$STAGE/PresentationFixture.app"
mkdir -p "$FIXTURE/Contents/MacOS"
mv "$STAGE/TemplateTests" "$FIXTURE/Contents/MacOS/TemplateTests"
for profile in jp.co.capcom.RE2US jp.co.capcom.RE3US jp.co.capcom.RE4US jp.co.capcom.RE7US jp.co.capcom.VillageUS; do
    python3 - "$FIXTURE/Contents/Info.plist" "$profile" <<'FIXTURE_PLIST'
from pathlib import Path
import plistlib,sys
Path(sys.argv[1]).write_bytes(plistlib.dumps({'CFBundleIdentifier':sys.argv[2],'CFBundleExecutable':'TemplateTests','CFBundlePackageType':'APPL'}))
FIXTURE_PLIST
    "$FIXTURE/Contents/MacOS/TemplateTests" --presentation
done
python3 - "$CANDIDATE" "$APP" "$STAGE/previous.app" <<'INSTALL'
from pathlib import Path
import os,sys,shutil,plistlib
candidate,target,previous=map(Path,sys.argv[1:])
if target.exists():os.rename(target,previous)
try:os.rename(candidate,target)
except BaseException:
 if previous.exists():os.rename(previous,target)
 raise
if previous.exists():shutil.rmtree(previous)
# Product renamed after adding RE3. Retire only our verified legacy build bundle.
legacy=target.parent/'Resident Evil 2 Trainer.app'
if legacy!=target and legacy.is_dir():
 info=plistlib.loads((legacy/'Contents/Info.plist').read_bytes())
 current=plistlib.loads((target/'Contents/Info.plist').read_bytes())
 if info.get('CFBundleIdentifier')==current.get('CFBundleIdentifier')=='local.mactrainer.re2':shutil.rmtree(legacy)
INSTALL
printf 'Build and tests successful: %s\n' "$APP"
if [[ "$MODE" == run ]]; then open -n "$APP"; fi
