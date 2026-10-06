"""Upgrade a verified existing game to a built language edition, with backups."""
import argparse
import ctypes
from ctypes import wintypes
import datetime
import json
import os
from pathlib import Path
import shutil
import time
import uuid
from build_language_support import load_builder

ROOT = Path(__file__).resolve().parent.parent
builder = load_builder()


def replace_file(source, target):
    for attempt in range(21):
        try:
            os.replace(source, target)
            return
        except OSError as error:
            if getattr(error, 'winerror', 0) not in (5, 32, 33) or attempt == 20:
                raise
            time.sleep(0.025)


def install(edition, game, backup_root):
    edition, game, backup_root = (path.resolve() for path in (edition, game, backup_root))
    require, digest = builder.require, builder.digest
    require(edition != game and not edition.is_relative_to(game) and not game.is_relative_to(edition), 'Edition and destination overlap')
    require(not backup_root.is_relative_to(game) and not game.is_relative_to(backup_root), 'Backup root overlaps game')
    for folder in (edition, game):
        require(folder.is_dir() and not folder.is_symlink() and not folder.is_junction(), 'Linked or missing game folder')
        builder.snapshot(folder)  # Reject linked children before reading/writing.
    manifest = json.loads((edition / 'language-edition.json').read_text())
    baseline = json.loads((edition / 'LANG/base-game-snapshot.json').read_text())
    require(manifest['edition'] == 'three-language-1', 'Unknown edition')
    require(digest(edition / 'NFSSE.exe') == manifest['launcher_sha256'], 'Built selector changed')
    require(digest(edition / 'NFSSE-Game.exe') == baseline[manifest.get('base_engine_path', 'NFSSE.exe')], 'Game engine changed')
    require(digest(edition / 'LANG/language-edition.index') == manifest['index_sha256'], 'Built inventory changed')
    for relative, expected in baseline.items():
        require(digest(game / relative) == expected, f'Current game changed since build: {relative}; rebuild from it')
    managed = manifest['managed_files']
    require(len(managed) == len(set(managed)) and 'NFSSE.exe' in managed and 'NFSSE-Game.exe' in managed, 'Invalid managed inventory')
    for relative in managed:
        require(relative and ':' not in relative and '\\' not in relative and not relative.startswith('/')
                and all(part not in ('', '.', '..') for part in relative.split('/')), 'Unsafe managed path')
        source, target = edition / relative, game / relative
        require(source.is_file() and not source.is_symlink() and not source.is_junction(), 'Linked or missing built file')
        require(not target.exists() or relative in baseline, f'Unmanaged destination file would be overwritten: {relative}')
    kernel = ctypes.WinDLL('kernel32', use_last_error=True)
    kernel.CreateFileW.argtypes = [wintypes.LPCWSTR, wintypes.DWORD, wintypes.DWORD, ctypes.c_void_p,
                                  wintypes.DWORD, wintypes.DWORD, wintypes.HANDLE]
    kernel.CreateFileW.restype = wintypes.HANDLE
    kernel.CloseHandle.argtypes = [wintypes.HANDLE]
    invalid = ctypes.c_void_p(-1).value
    # Exclusive session guard. Hold the old executable while installing its
    # resources; close its handle for the final entry-point replacement.
    session = kernel.CreateFileW(str(game / '.language-session.lock'), 0xc0000000, 0, None, 4, 2, None)
    require(session != invalid, 'Close the game before updating languages')
    probe = kernel.CreateFileW(str(game / 'NFSSE.exe'), 0xc0000000, 4, None, 3, 0, None)
    if probe == invalid:
        kernel.CloseHandle(session)
        raise ValueError('Close the running game before updating languages')
    backup = backup_root / ('language-edition-' + datetime.datetime.now().strftime('%Y%m%d-%H%M%S') + '-' + uuid.uuid4().hex[:8])
    written = []
    temporary = []
    try:
        # Recheck after acquiring the guards before any backup or managed write.
        for relative, expected in baseline.items():
            if relative == 'NFSSE.exe':
                continue  # Kept open exclusively; its bytes were checked above.
            require(digest(game / relative) == expected, f'Game changed during update: {relative}')
        backup.mkdir(parents=True, exist_ok=False)
        # The exclusive probe permits copying through its open handle only.
        kernel.ReadFile.argtypes = [wintypes.HANDLE, ctypes.c_void_p, wintypes.DWORD, ctypes.POINTER(wintypes.DWORD), ctypes.c_void_p]
        buffer = ctypes.create_string_buffer((game / 'NFSSE.exe').stat().st_size)
        count = wintypes.DWORD()
        require(kernel.ReadFile(probe, buffer, len(buffer), ctypes.byref(count), None) and count.value == len(buffer), 'Could not back up engine')
        (backup / 'NFSSE.exe').write_bytes(buffer.raw)
        require(digest(backup / 'NFSSE.exe') == baseline['NFSSE.exe'], 'Locked engine changed during update')
        for relative in ['nfs.cfg', 'GAMEDATA/CONFIG/PATHS.DAT'] + [r['name'] for r in manifest['announcers']]:
            target = backup / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(game / relative, target)
        for relative in managed:
            if relative in baseline and relative != 'NFSSE.exe':
                target = backup / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(game / relative, target)
        # Install the public entry point last, when all resources are complete.
        order = [r for r in managed if r != 'NFSSE.exe'] + ['NFSSE.exe']
        for relative in order:
            target = game / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            temp = target.with_name(target.name + '.language-install-' + uuid.uuid4().hex + '.tmp')
            temporary.append(temp)
            shutil.copy2(edition / relative, temp)
            if relative == 'NFSSE.exe':
                kernel.CloseHandle(probe)
                probe = None
            replace_file(temp, target)
            written.append(relative)
        preserved = 0
        for relative, expected in baseline.items():
            if relative == manifest.get('base_engine_path', 'NFSSE.exe'):
                target = 'NFSSE-Game.exe'
            elif relative in managed:
                continue
            else:
                target = relative
            require(digest(game / target) == expected, f'Original file was not preserved: {relative}')
            preserved += 1
        record = {'installed': str(game), 'backup': str(backup), 'original_files_preserved': preserved,
                  'public_executable': str(game / 'NFSSE.exe'), 'engine_unchanged': True,
                  'game_launched': False, 'managed_files_added_or_updated': len(managed)}
        (backup / 'installation-result.json').write_text(json.dumps(record, indent=2) + '\n')
        print(json.dumps(record, indent=2))
        return record
    except Exception:
        for relative in reversed(written):
            target, saved = game / relative, backup / relative
            if saved.is_file():
                temp = target.with_name(target.name + '.language-rollback-' + uuid.uuid4().hex + '.tmp')
                shutil.copy2(saved, temp)
                replace_file(temp, target)
            else:
                target.unlink()
        raise
    finally:
        if probe is not None:
            kernel.CloseHandle(probe)
        kernel.CloseHandle(session)
        for path in temporary:
            if path.exists():
                path.unlink()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--edition', type=Path, default=ROOT / 'build/multilingual-game')
    parser.add_argument('--game-root', type=Path, default=ROOT / 'NFSSE')
    parser.add_argument('--backup-root', type=Path, default=ROOT / 'build/language-install-backups')
    args = parser.parse_args()
    try:
        install(args.edition, args.game_root, args.backup_root)
    except (OSError, ValueError) as error:
        parser.exit(1, f'Language update failed: {error}\n')


if __name__ == '__main__':
    main()
