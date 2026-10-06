"""Build a complete native three-language edition from the user's own media.

The supported engine/helper/renderer are preserved. This tool never starts the
game; players only need Windows and the resulting complete installation.
"""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import uuid
from nfs_resources import Archive, compatible_graphics, compatible_hud, encode_qfs

ROOT = Path(__file__).resolve().parent.parent
GERMAN_PATHS = {2: 'frontend/gspeech/', 5: 'frontend/gart/', 10: 'simdata/gtrackfm/',
                12: 'simdata/gslides/', 16: 'simdata/gdash/', 18: 'frontend/gshow/'}
JP_PATHS = {2: 'lang/ja/speech/', 5: 'lang/ja/art/', 9: 'lang/ja/misc/',
            17: 'lang/ja/misc/', 18: 'lang/ja/show/'}


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def snapshot(root):
    result = {}
    for path in root.rglob('*'):
        require(not path.is_symlink() and not path.is_junction(), f'Linked input is unsupported: {path}')
        if path.is_file():
            result[path.relative_to(root).as_posix()] = digest(path)
    return result


def paths_for(recipe, language):
    paths = {row['index']: row['path'].lower() for row in recipe['paths']}
    paths.update(GERMAN_PATHS if language == 'German' else JP_PATHS if language == 'Japanese' else {})
    result = bytearray(1520)
    for index, path in paths.items():
        data = path.encode('ascii')
        require(len(data) < 80, 'Legacy path is too long')
        result[index * 80:index * 80 + len(data)] = data
    return bytes(result)


def japanese_pack(media, english, profile):
    files = {}
    for record in profile['files']:
        path = media / record['path']
        require(digest(path) == record['sha256'], f'Japanese input changed: {record["path"]}')
        files[record['target']] = path.read_bytes()
    jp_graphics = Archive((media / 'FRONTEND/ART/OPTION/GRAPHICS.QFS').read_bytes())
    en_graphics = Archive((english / 'FRONTEND/ART/OPTION/GRAPHICS.QFS').read_bytes())
    for context in ('OPTION', 'CHECK'):
        target = Archive((english / f'FRONTEND/ART/{context}/GRAPHICS.QFS').read_bytes())
        raw = compatible_graphics(jp_graphics, en_graphics)
        archive = Archive(raw)
        raw = archive.pack(target.order, archive.blobs)
        files[f'LANG/JA/ART/{context}/GRAPHICS.FSH'] = raw
        files[f'LANG/JA/ART/{context}/GRAPHICS.QFS'] = encode_qfs(raw)
    for name in ('MASKHI.FSH', 'MASKLO.FSH'):
        files[f'LANG/JA/MISC/{name}'] = compatible_hud(
            Archive((media / 'SIMDATA/MISC' / name).read_bytes()),
            Archive((english / 'SIMDATA/MISC' / name).read_bytes()))
    return files


def build(args):
    base, english, japanese, destination = (p.resolve() for p in
        (args.base_game, args.english_media, args.japanese_media, args.destination))
    require(not destination.exists(), 'Choose a new destination')
    for folder in (base, english, japanese):
        require(not destination.is_relative_to(folder) and not folder.is_relative_to(destination),
                'Destination overlaps an input folder')
        require(folder.is_dir() and not folder.is_symlink() and not folder.is_junction(), 'Input folder is linked or missing')
    recipe = json.loads((ROOT / 'config/patch-recipe.json').read_text())
    profile = json.loads((ROOT / 'config/japanese-resource-profile.json').read_text())
    require(digest(english / 'NFS_WIN.EXE') == recipe['source_sha256'], 'Unsupported English media')
    require(digest(english / 'NFSICONN.ICO') == recipe['icon_sha256'], 'Unexpected original icon')
    require(digest(japanese / 'NFS.EXE') == profile['japanese_executable_sha256'], 'Unsupported Japanese media')
    engine_name = 'NFSSE-Game.exe' if (base / 'language-edition.json').exists() else 'NFSSE.exe'
    for relative, expected in profile['runtime_sha256'].items():
        target = engine_name if relative == 'NFSSE.exe' else relative
        require(digest(base / target) == expected, f'Unsupported base runtime: {target}')
    for relative, expected in profile['english_resource_sha256'].items():
        require(digest(english / relative) == expected, f'English source changed: {relative}')
    before = snapshot(base)
    table = (base / 'GAMEDATA/CONFIG/PATHS.DAT').read_bytes().lower()
    require(table in [paths_for(recipe, language) for language in ('English', 'German', 'Japanese')], 'Custom base resource paths')
    require((base / 'nfs.cfg').read_bytes().split()[2] in (b'ENGLISH', b'GERMAN'), 'Unsupported base language setting')
    pack = japanese_pack(japanese, english, profile)
    for folder in ('FRONTEND', 'SIMDATA'):
        for source in (english / folder).rglob('*'):
            if source.is_file():
                relative = source.relative_to(english)
                require(digest(base / relative) == digest(source), f'Base asset differs from media: {relative}')
    announcers = []
    for name in recipe['race_speech_files']:
        en, de = english / 'FRONTEND/SPEECH' / name, english / 'FRONTEND/GSPEECH' / name
        require(digest(base / name) in (digest(en), digest(de)), f'Custom root announcer: {name}')
        require(digest(japanese / 'FRONTEND/SPEECH' / name) == digest(en), 'Japanese race speech differs unexpectedly')
        announcers.append({'name': name, 'english_sha256': digest(en), 'german_sha256': digest(de),
                          'different': digest(en) != digest(de)})
    require(all(row['different'] for row in announcers), 'German announcements need reassessment')
    stage = destination.with_name(destination.name + '.staging-' + uuid.uuid4().hex)
    stage.parent.mkdir(parents=True, exist_ok=True)
    try:
        shutil.copytree(base, stage)
        for path in stage.rglob('*'):
            if path.is_file():
                path.chmod(path.stat().st_mode | stat.S_IWRITE)
        shutil.copy2(base / engine_name, stage / 'NFSSE-Game.exe')
        managed = ['NFSSE.exe', 'NFSSE-Game.exe', 'LANGUAGE_EDITION.md', 'language-edition.json']
        for relative, data in pack.items():
            path = stage / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            managed.append(relative)
        language_paths = []
        for language in ('English', 'German', 'Japanese'):
            relative = f'LANG/{language}.paths'
            (stage / relative).write_bytes(paths_for(recipe, language))
            managed.append(relative)
            language_paths.append({'language': language, 'path': relative, 'sha256': digest(stage / relative)})
        powershell = Path(os.environ['SystemRoot']) / 'System32/WindowsPowerShell/v1.0/powershell.exe'
        subprocess.run([str(powershell), '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
                        str(ROOT / 'tools/Embed-LauncherIcon.ps1'), '-InputExecutable', str(args.launcher.resolve()),
                        '-OutputExecutable', str(stage / 'NFSSE.exe'), '-SourceIcon', str(english / 'NFSICONN.ICO')], check=True)
        shutil.copy2(ROOT / 'docs/LANGUAGE_EDITION.md', stage / 'LANGUAGE_EDITION.md')
        records = {}
        def add(group, path):
            relative = path.relative_to(stage).as_posix()
            records[group, relative] = digest(path)
        # Select-specific art, speech, dashboard, slides and track previews.
        for group, folders in {'E': ['FRONTEND/ART', 'FRONTEND/SHOW', 'FRONTEND/SPEECH', 'SIMDATA/DASH', 'SIMDATA/SLIDES', 'SIMDATA/ETRACKFM'],
                               'D': ['FRONTEND/GART', 'FRONTEND/GSHOW', 'FRONTEND/GSPEECH', 'SIMDATA/GDASH', 'SIMDATA/GSLIDES', 'SIMDATA/GTRACKFM'],
                               'J': ['LANG/JA']}.items():
            for folder in folders:
                for path in (stage / folder).rglob('*'):
                    if path.is_file():
                        add(group, path)
        for language, group in [('English', 'E'), ('German', 'D'), ('Japanese', 'J')]:
            add(group, stage / f'LANG/{language}.paths')
        for name in recipe['race_speech_files']:
            add('J', stage / 'FRONTEND/SPEECH' / name)
        # Original movies include German police clips; both engine branches use
        # the common movie path. Validate shared miscellaneous/HUD resources too.
        for folder in ('FRONTEND/MOVIE', 'SIMDATA/MISC'):
            for path in (stage / folder).rglob('*'):
                if path.is_file():
                    add('C', path)
        for name in ('NFSSE-Game.exe', 'NFSPortable.dll', 'ddraw.dll', 'IFORCE.DLL', 'DPLAY.dll',
                     'DPSERIAL.DLL', 'DPWSOCK.DLL', 'DPLAYX.DLL', 'DPWSOCKX.DLL', 'DPMODEMX.DLL'):
            add('C', stage / name)
        index = 'NFSSE-LANGUAGES-1\n' + ''.join(f'{group}\t{value}\t{path}\n'
            for (group, path), value in sorted(records.items()))
        (stage / 'LANG/language-edition.index').write_bytes(index.encode('ascii'))
        managed.append('LANG/language-edition.index')
        (stage / 'LANG/base-game-snapshot.json').write_text(json.dumps(before, indent=2) + '\n')
        managed.append('LANG/base-game-snapshot.json')
        manifest = {'schema': 1, 'edition': 'three-language-1', 'created_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                    'languages': language_paths, 'launcher_sha256': digest(stage / 'NFSSE.exe'),
                    'base_engine_path': engine_name,
                    'engine_sha256': digest(stage / 'NFSSE-Game.exe'), 'index_sha256': digest(stage / 'LANG/language-edition.index'),
                    'japanese_resource_count': len(pack), 'announcers': announcers,
                    'managed_files': managed, 'game_launched_by_builder': False,
                    'japanese_prototype_user_report': 'Checks looking OK, 2026-10-06',
                    'new_selector_and_german_gameplay_user_check': 'pending',
                    'icon_payloads': 'original media, unchanged',
                    'saves_settings': 'shared; only nfs.cfg language token changes when selected',
                    'japanese_engine_branch': 'ENGLISH', 'german_engine_branch': 'GERMAN'}
        (stage / 'language-edition.json').write_text(json.dumps(manifest, indent=2) + '\n')
        require(snapshot(base) == before, 'Base game changed during build')
        stage.rename(destination)
    except Exception:
        print(f'Incomplete output retained: {stage}')
        raise
    print(f'Created: {destination / "NFSSE.exe"}; original game and media preserved. No game launched.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base-game', type=Path, default=ROOT / 'NFSSE')
    parser.add_argument('--english-media', type=Path, default=ROOT / 'install')
    parser.add_argument('--japanese-media', type=Path, default=ROOT / 'japanese')
    parser.add_argument('--launcher', type=Path, default=ROOT / 'build/NFSSE-Language.exe')
    parser.add_argument('--destination', type=Path, default=ROOT / 'build/multilingual-game')
    args = parser.parse_args()
    try:
        build(args)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        parser.exit(1, f'Language edition build failed: {error}\n')


if __name__ == '__main__':
    main()
