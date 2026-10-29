#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Check release-history preservation without network or GitHub credentials."""
from pathlib import Path
import copy
import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'script'))
import publish_release as release

COMMIT = 'a' * 40
REPO = 'example/trainer'


class GitHubFixture:
    def __init__(self, head=COMMIT):
        self.head, self.calls = head, []
        self.refs = {'latest': {'object': {'type': 'commit', 'sha': 'b' * 40}}}
        self.releases = {'latest': {'html_url': 'old-release', 'draft': False,
                                   'assets': [{'name': 'old.zip', 'state': 'uploaded'}]}}

    def run(self, args, **kwargs):
        self.calls.append(args)
        if args[:2] == ['gh', 'api']:
            assert args[-2:] == ['--method', 'GET']
            path = args[2].removeprefix(f'repos/{REPO}/')
            if path == 'git/ref/heads/main':
                value = {'object': {'sha': self.head}}
            elif path.startswith('git/ref/tags/'):
                value = self.refs.get(path.removeprefix('git/ref/tags/'))
            elif path.startswith('releases/tags/'):
                value = self.releases.get(path.removeprefix('releases/tags/'))
            else:
                raise AssertionError(path)
            return subprocess.CompletedProcess(args, 0 if value else 1,
                                               json.dumps(value), '' if value else 'HTTP 404')
        assert args[:3] == ['gh', 'release', 'create'], args
        tag = args[3]
        assert tag not in self.releases
        self.refs[tag] = {'object': {'type': 'commit', 'sha': COMMIT}}
        self.releases[tag] = {'html_url': f'https://github.com/{REPO}/releases/tag/{tag}',
                              'draft': False, 'assets': [{'name': a, 'state': 'uploaded'} for a in release.ASSETS]}
        return subprocess.CompletedProcess(args, 0)


class PublishTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)
        self.info = {'version': '0.9.0', 'build': '78', 'commit': COMMIT,
                     'architecture': 'arm64', 'archive': release.ARCHIVE, 'minimumMacOS': '14.0'}
        (self.folder / release.ARCHIVE).write_bytes(b'packaging-fixture')
        (self.folder / 'release-info.json').write_text(json.dumps(self.info))
        (self.folder / 'SHA256SUMS').write_text(''.join(
            hashlib.sha256((self.folder / n).read_bytes()).hexdigest() + '  ' + n + '\n'
            for n in [release.ARCHIVE, 'release-info.json']))

    def test_new_release_preserves_old_release_and_rerun_is_read_only(self):
        github = GitHubFixture()
        old_refs, old_releases = copy.deepcopy(github.refs), copy.deepcopy(github.releases)
        with patch.object(release.subprocess, 'run', side_effect=github.run):
            url = release.publish(self.folder, REPO, COMMIT)
            count = len(github.calls)
            self.assertEqual(release.publish(self.folder, REPO, COMMIT), url)
        self.assertEqual(github.refs['latest'], old_refs['latest'])
        self.assertEqual(github.releases['latest'], old_releases['latest'])
        self.assertTrue(all(c[:2] == ['gh', 'api'] for c in github.calls[count:]))
        create = [c for c in github.calls if c[:3] == ['gh', 'release', 'create']]
        self.assertEqual(len(create), 1)
        self.assertIn('--latest', create[0])
        self.assertEqual(create[0][create[0].index('--target') + 1], COMMIT)

    def test_old_queued_commit_does_not_take_latest_marker(self):
        github = GitHubFixture(head='c' * 40)
        with patch.object(release.subprocess, 'run', side_effect=github.run):
            release.publish(self.folder, REPO, COMMIT)
        self.assertIn('--latest=false', github.calls[-1])

    def test_foreign_tag_is_never_moved(self):
        github = GitHubFixture()
        github.refs[release.release_tag(self.info, COMMIT)] = {'object': {'type': 'commit', 'sha': 'c' * 40}}
        with patch.object(release.subprocess, 'run', side_effect=github.run), self.assertRaises(ValueError):
            release.publish(self.folder, REPO, COMMIT)
        self.assertTrue(all(c[:2] == ['gh', 'api'] for c in github.calls))

    def test_existing_draft_is_not_overwritten(self):
        github = GitHubFixture()
        tag = release.release_tag(self.info, COMMIT)
        github.refs[tag] = {'object': {'type': 'commit', 'sha': COMMIT}}
        github.releases[tag] = {'draft': True, 'assets': []}
        with patch.object(release.subprocess, 'run', side_effect=github.run), self.assertRaises(ValueError):
            release.publish(self.folder, REPO, COMMIT)
        self.assertTrue(all(c[:2] == ['gh', 'api'] for c in github.calls))

    def test_corrupted_package_never_contacts_github(self):
        (self.folder / release.ARCHIVE).write_bytes(b'corrupt')
        with patch.object(release.subprocess, 'run') as run, self.assertRaises(ValueError):
            release.publish(self.folder, REPO, COMMIT)
        run.assert_not_called()

    def test_network_error_cannot_be_treated_as_missing_release(self):
        with patch.object(release.subprocess, 'run', return_value=subprocess.CompletedProcess([], 1, '', 'network unavailable')):
            with self.assertRaises(RuntimeError):
                release.publish(self.folder, REPO, COMMIT)

    def test_different_source_commits_have_different_tags(self):
        self.assertNotEqual(release.release_tag(self.info, COMMIT),
                            release.release_tag(self.info, 'b' * 40))


if __name__ == '__main__':
    unittest.main()
