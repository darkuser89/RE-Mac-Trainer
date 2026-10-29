#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Create a versioned release; never edit/delete releases, assets or tag refs."""
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile

ARCHIVE = 'Resident-Evil-Trainer-macOS-arm64.zip'
ASSETS = (ARCHIVE, 'release-info.json', 'SHA256SUMS')


def api(repo, path, optional=False):
    result = subprocess.run(['gh', 'api', f'repos/{repo}/{path}', '--method', 'GET'],
                            capture_output=True, text=True)
    if result.returncode:
        if optional and 'HTTP 404' in result.stderr:
            return None
        raise RuntimeError(result.stderr.strip() or 'GitHub read failed.')
    return json.loads(result.stdout)


def release_tag(info, commit):
    version, build = info['version'], info['build']
    if not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+(?:[-+][A-Za-z0-9.-]+)?', version):
        raise ValueError('Invalid version.')
    if not re.fullmatch(r'[0-9]+', build) or not re.fullmatch(r'[0-9a-f]{40}', commit):
        raise ValueError('Invalid build or source commit.')
    return f'v{version}-build.{build}-{commit[:12]}'


def publish(folder, repo, commit):
    folder = Path(folder).resolve()
    if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', repo):
        raise ValueError('Invalid repository.')
    info = json.loads((folder / 'release-info.json').read_text())
    tag = release_tag(info, commit)
    if info['commit'] != commit or info['architecture'] != 'arm64' or info['archive'] != ARCHIVE:
        raise ValueError('Release metadata does not match the source/build.')
    checks = [line.split() for line in (folder / 'SHA256SUMS').read_text().splitlines()]
    if len(checks) != 2 or any(len(row) != 2 for row in checks):
        raise ValueError('Invalid checksums.')
    if {row[1] for row in checks} != {ARCHIVE, 'release-info.json'}:
        raise ValueError('Unexpected checksum files.')
    for digest, name in checks:
        if hashlib.sha256((folder / name).read_bytes()).hexdigest() != digest:
            raise ValueError(f'Checksum mismatch: {name}')
    ref = api(repo, f'git/ref/tags/{tag}', optional=True)
    if ref and (ref['object']['type'] != 'commit' or ref['object']['sha'] != commit):
        raise ValueError('Tag already exists at another target; refusing to move it.')
    existing = api(repo, f'releases/tags/{tag}', optional=True)
    if existing:
        uploaded = {a['name'] for a in existing.get('assets', []) if a.get('state') == 'uploaded'}
        if not ref or existing.get('draft') or not set(ASSETS).issubset(uploaded):
            raise ValueError('Existing release is incomplete; it will not be modified automatically.')
        print(f"Already published, unchanged: {existing['html_url']}")
        return existing['html_url']
    head = api(repo, 'git/ref/heads/main')['object']['sha']
    title = f"Resident Evil Trainer {info['version']} · Build {info['build']} · {commit[:7]}"
    notes = (
        f"Geprüfter Build für Apple Silicon und macOS {info['minimumMacOS']}+.\n\n"
        f"Quellstand: {commit}\n\n"
        "ZIP entpacken und Resident Evil Trainer.app öffnen. ⌘ + ^ öffnet das Overlay samt Mausbedienung.\n\n"
        "Enthält RE2, RE3, RE4, RE7 und Village einschließlich Rose. Spielversionen und Bedienung stehen im README.\n\n"
        "Ad-hoc signiert, nicht Apple-notarisiert. GitHub prüft Regressionen und Verpackung; dort werden keine Spiele gestartet.\n\n"
        "Dieses Release und seine Downloads werden vom Workflow nicht überschrieben. SHA256SUMS prüft ZIP und Buildinformationen.\n"
    )
    with tempfile.TemporaryDirectory(prefix='trainer-release-') as tmp:
        notes_file = Path(tmp) / 'notes.md'
        notes_file.write_text(notes)
        # Creation is the only write operation. No force, upload, edit or delete.
        subprocess.run(['gh', 'release', 'create', tag, *(str(folder / a) for a in ASSETS),
                        '--repo', repo, '--target', commit, '--title', title,
                        '--notes-file', str(notes_file),
                        '--latest' if head == commit else '--latest=false'], check=True)
    return f'https://github.com/{repo}/releases/tag/{tag}'


if __name__ == '__main__':
    try:
        if len(sys.argv) != 2:
            raise ValueError('Usage: publish_release.py release-folder')
        print(publish(sys.argv[1], os.environ['GH_REPO'], os.environ['TRAINER_COMMIT']))
    except (KeyError, ValueError, RuntimeError, OSError, subprocess.CalledProcessError) as error:
        raise SystemExit(str(error)) from error
