#!/usr/bin/env python3
"""Exercise the native macOS executable and inspect real ZIP data."""
import os
from pathlib import Path
import resource
import signal
import subprocess
import sys
import tempfile
import unittest
import zipfile

ENGINE = Path(sys.argv.pop(1)).resolve()
RULES = ENGINE.parent / 'CleanZip.rules.txt'


class MacTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='clean-zip-test-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.source = self.base / 'Türkçe project [2]'
        self.source.mkdir()
        self.output = Path(str(self.source) + '.zip')

    def file(self, name, content=b'fixture'):
        path = self.source / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
        return path

    def run_zip(self, *args, ok=True, **kwargs):
        result = subprocess.run([str(ENGINE), '--path', str(self.source), *map(str, args)],
                                capture_output=True, text=True, **kwargs)
        if ok:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout)
        return result

    def test_all_default_rules_unicode_hidden_and_data(self):
        expected = {'package.json': b'{"name":"test"}', 'package-lock.json': b'lock',
                    'src/Türkçe [1] !.ts': 'şİğ'.encode(), '.env': b'SAMPLE=value',
                    'src/NORMAL.JS': b'source', 'src/app.min.js.ts': b'source',
                    'src/binance/index.ts': b'source', 'docs/manual.docx.md': b'docs',
                    'schema.sql': b'CREATE TABLE example;', 'data.csv': b'a,b',
                    'src/empty.txt': b'', 'src/random.txt': os.urandom(1024 * 1024)}
        for name, data in expected.items():
            self.file(name, data)
        for line in RULES.read_text().splitlines():
            if not line or line.startswith('#'):
                continue
            kind, value = line.split(':', 1)
            if kind == 'd': self.file('excluded/' + value.upper() + '/source.ts')
            elif kind == 'e': self.file('excluded/asset' + value.upper())
            elif kind == 's': self.file('excluded/generated' + value.upper())
            elif kind == 'f': self.file('excluded/' + value.upper())
        self.file('excluded/native.so.1')
        (self.source / 'linked-file.ts').symlink_to(self.source / 'package.json')
        (self.source / 'linked-dir').symlink_to(self.source / 'src', target_is_directory=True)
        os.mkfifo(self.source / 'pipe')
        self.run_zip()
        with zipfile.ZipFile(self.output) as archive:
            self.assertEqual(set(archive.namelist()), set(expected))
            self.assertIsNone(archive.testzip())
            for name, data in expected.items(): self.assertEqual(archive.read(name), data)
            self.assertTrue(archive.getinfo('src/Türkçe [1] !.ts').flag_bits & 0x800)
        self.assertIn(b'PK\x06\x06', self.output.read_bytes())  # ZIP64 end of central directory

    def test_scan_manifest_and_empty_selection(self):
        self.file('source.ts')
        manifest = self.base / 'selected.txt'
        self.run_zip('--scan-only', '--manifest', manifest)
        self.assertEqual(manifest.read_text(), 'source.ts\n')
        self.assertFalse(self.output.exists())
        (self.source / 'source.ts').unlink()
        self.file('asset.PNG')
        self.output.write_bytes(b'old archive')
        self.run_zip()
        self.assertEqual(self.output.read_bytes(), b'old archive')

    def test_same_manifest_target_and_hardlink_preserve_archive(self):
        self.file('source.ts')
        self.run_zip()
        previous = self.output.read_bytes()
        self.run_zip('--manifest', self.output, '--scan-only', ok=False)
        self.assertEqual(self.output.read_bytes(), previous)
        alias = self.base / 'alias.txt'
        os.link(self.output, alias)
        self.run_zip('--manifest', alias, ok=False)
        self.assertEqual(self.output.read_bytes(), previous)

    def test_source_targets_and_symlinks_rejected(self):
        self.file('source.ts')
        self.run_zip('--output', self.source / 'inside.zip', ok=False)
        self.run_zip('--manifest', self.source / 'inside.txt', ok=False)
        alias = self.base / 'alias'
        alias.symlink_to(self.source, target_is_directory=True)
        self.run_zip('--output', alias / 'inside.zip', ok=False)
        outside = self.base / 'outside.txt'
        outside.write_bytes(b'preserve')
        self.output.symlink_to(outside)
        self.run_zip(ok=False)
        self.assertEqual(outside.read_bytes(), b'preserve')

    def test_mid_write_failure_preserves_archive_and_cleans_stage(self):
        self.file('large.txt', os.urandom(2 * 1024 * 1024))
        self.output.write_bytes(b'previous archive')
        def limit_output():
            signal.signal(signal.SIGXFSZ, signal.SIG_IGN)
            resource.setrlimit(resource.RLIMIT_FSIZE, (1024, 1024))
        self.run_zip(ok=False, preexec_fn=limit_output)
        self.assertEqual(self.output.read_bytes(), b'previous archive')
        self.assertEqual(list(self.base.glob(self.output.name + '.*')), [])

    def test_bad_rules_and_missing_source_preserve_archive(self):
        self.file('source.ts')
        self.output.write_bytes(b'previous')
        rules = self.base / 'bad.rules'
        rules.write_text('z:invalid\n')
        self.run_zip('--rules', rules, ok=False)
        self.run_zip('--path', self.base / 'missing', ok=False)
        self.assertEqual(self.output.read_bytes(), b'previous')

    def test_modified_timestamp_preserved(self):
        path = self.file('source.ts')
        timestamp = 1700000000
        os.utime(path, (timestamp, timestamp))
        self.run_zip()
        with zipfile.ZipFile(self.output) as archive:
            import time
            expected = time.localtime(timestamp)
            actual = archive.getinfo('source.ts').date_time
            self.assertEqual(actual[:5], tuple(expected[:5]))
            self.assertLessEqual(abs(actual[5] - expected.tm_sec), 1)

    def test_newline_filename_and_manifest_failure(self):
        self.file('line\nbreak.ts')
        self.run_zip()
        with zipfile.ZipFile(self.output) as archive:
            self.assertEqual(archive.namelist(), ['line\nbreak.ts'])
        manifest = self.base / 'selected.txt'
        manifest.write_text('previous')
        self.run_zip('--manifest', manifest, ok=False)
        self.assertEqual(manifest.read_text(), 'previous')
        self.assertEqual(list(self.base.glob('selected.txt.*')), [])


unittest.main(verbosity=2)
