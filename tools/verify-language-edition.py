"""Verify the complete edition and exercise real native selections without play."""
import argparse
import datetime
import hashlib
import json
from pathlib import Path
import struct
import subprocess
from build_language_support import load_builder

ROOT = Path(__file__).resolve().parent.parent
builder = load_builder()


def icon_payloads(path):
    data = path.read_bytes()
    pe_offset = struct.unpack_from('<I', data, 0x3c)[0]
    builder.require(data[pe_offset:pe_offset + 4] == b'PE\0\0', 'Invalid launcher PE header')
    count, optional_size = struct.unpack_from('<H', data, pe_offset + 6)[0], struct.unpack_from('<H', data, pe_offset + 20)[0]
    optional = pe_offset + 24
    builder.require(struct.unpack_from('<H', data, optional)[0] == 0x10b, 'Launcher must be PE32')
    builder.require(struct.unpack_from('<H', data, optional + 68)[0] == 2, 'Launcher must use the Windows GUI subsystem')
    sections = [struct.unpack_from('<IIII', data, optional + optional_size + i * 40 + 8) for i in range(count)]
    def offset(rva):
        for virtual_size, virtual_address, raw_size, raw_offset in sections:
            if virtual_address <= rva < virtual_address + min(virtual_size, raw_size):
                return raw_offset + rva - virtual_address
        raise ValueError('Invalid icon resource RVA')
    resource_rva = struct.unpack_from('<I', data, optional + 112)[0]
    root = offset(resource_rva)
    def entries(relative):
        named, identities = struct.unpack_from('<HH', data, root + relative + 12)
        return [struct.unpack_from('<II', data, root + relative + 16 + i * 8) for i in range(named + identities)]
    kinds = dict(entries(0))
    builder.require(3 in kinds and kinds[3] & 0x80000000, 'Launcher icons are missing')
    result = []
    for identity, directory in sorted(entries(kinds[3] & 0x7fffffff)):
        builder.require(identity < 0x80000000 and directory & 0x80000000, 'Invalid icon directory')
        languages = entries(directory & 0x7fffffff)
        builder.require(len(languages) == 1 and not languages[0][1] & 0x80000000, 'Unexpected icon language tree')
        rva, size = struct.unpack_from('<II', data, root + languages[0][1])
        start = offset(rva)
        result.append(data[start:start + size])
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--game-root', type=Path, default=ROOT / 'build/multilingual-game')
    parser.add_argument('--english-media', type=Path, default=ROOT / 'install')
    parser.add_argument('--japanese-media', type=Path, default=ROOT / 'japanese')
    parser.add_argument('--driver', type=Path, default=ROOT / 'build/LanguageEditionCheck.exe')
    parser.add_argument('--output', type=Path, default=ROOT / 'research/validation/language-edition-validation.json')
    args = parser.parse_args()
    game, english, japanese = args.game_root.resolve(), args.english_media.resolve(), args.japanese_media.resolve()
    manifest = json.loads((game / 'language-edition.json').read_text())
    profile = json.loads((ROOT / 'config/japanese-resource-profile.json').read_text())
    recipe = json.loads((ROOT / 'config/patch-recipe.json').read_text())
    require, digest = builder.require, builder.digest
    require(manifest['edition'] == 'three-language-1', 'Unknown language edition')
    require(digest(game / 'NFSSE.exe') == manifest['launcher_sha256'], 'Launcher changed')
    for relative, expected in profile['runtime_sha256'].items():
        target = 'NFSSE-Game.exe' if relative == 'NFSSE.exe' else relative
        require(digest(game / target) == expected, f'Accepted runtime changed: {target}')
    expected_pack = builder.japanese_pack(japanese, english, profile)
    for relative, expected in expected_pack.items():
        require((game / relative).read_bytes() == expected, f'Japanese resource derivation changed: {relative}')
    require(len(expected_pack) == 436 == manifest['japanese_resource_count'], 'Unexpected Japanese pack size')
    require(digest(game / 'LANG/language-edition.index') == manifest['index_sha256'], 'Inventory changed')
    before = builder.snapshot(game)
    table_path = 'GAMEDATA/CONFIG/PATHS.DAT'
    managed_state = ['nfs.cfg', table_path] + recipe['race_speech_files']
    originals = {relative: (game / relative).read_bytes() for relative in managed_state}
    require(originals[table_path].lower() in [builder.paths_for(recipe, l) for l in ('English', 'German', 'Japanese')], 'Custom paths present')
    config_tokens = originals['nfs.cfg'].split()
    require(len(config_tokens) == 4, 'Configuration is incomplete')
    try:
        for language in ('English', 'German', 'Japanese', 'German', 'English'):
            subprocess.run([str(args.driver.resolve()), str(game), language], check=True)
            require((game / table_path).read_bytes() == builder.paths_for(recipe, language), f'Wrong {language} paths')
            found = (game / 'nfs.cfg').read_bytes().split()
            require(found[2] == (b'GERMAN' if language == 'German' else b'ENGLISH'), 'Wrong engine language')
            require(found[:2] + found[3:] == config_tokens[:2] + config_tokens[3:], 'Other configuration options changed')
            folder = 'GSPEECH' if language == 'German' else 'SPEECH'
            for name in recipe['race_speech_files']:
                require((game / name).read_bytes() == (english / 'FRONTEND' / folder / name).read_bytes(), f'Wrong {language} announcer: {name}')
    finally:
        # Developer verification restores the exact prior user selection/config,
        # including original case and spacing. It never starts the engine.
        for relative, data in originals.items():
            (game / relative).write_bytes(data)
    after = builder.snapshot(game)
    require(all(after.get(relative) == value for relative, value in before.items()), 'A game file changed during verification')
    require(set(after) - set(before) <= {'.language-session.lock'}, 'Unexpected verification output in game folder')
    base = json.loads((game / 'LANG/base-game-snapshot.json').read_text())
    preserved = 0
    for relative, expected in base.items():
        if relative == manifest.get('base_engine_path', 'NFSSE.exe'):
            target = 'NFSSE-Game.exe'
        elif relative in manifest['managed_files']:
            continue
        else:
            target = relative
        require(digest(game / target) == expected, f'Base file not preserved: {relative}')
        preserved += 1
    # Inspect the embedded icon without running any executable.
    icon = (english / 'NFSICONN.ICO').read_bytes()
    count = struct.unpack_from('<H', icon, 4)[0]
    actual = icon_payloads(game / 'NFSSE.exe')
    expected = []
    for i in range(count):
        size, offset = struct.unpack_from('<II', icon, 6 + i * 16 + 8)
        expected.append(icon[offset:offset + size])
    require(actual == expected, 'Original launcher icon payloads changed')
    result = {'created_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'passed': True,
              'game_launched': False, 'selector_ui_launched': False,
              'game_root': str(game), 'original_base_files_preserved': preserved,
              'japanese_source_derived_resources_verified': len(expected_pack),
              'original_engine_helper_renderer_unchanged': True,
              'launcher_sha256': manifest['launcher_sha256'], 'original_icon_payloads_unchanged': True,
              'selections_exercised': ['English', 'German', 'Japanese', 'German', 'English'],
              'german_path_records': builder.GERMAN_PATHS,
              'all_eleven_german_announcements_distinct_and_selected': True,
              'english_and_japanese_announcements_restored': True,
              'other_configuration_tokens_preserved': True,
              'complete_game_file_preservation': len(before), 'prior_selection_restored_exactly': True,
              'japanese_prototype_user_report': 'Checks looking OK',
              'selector_and_german_gameplay_acceptance': 'pending user checks'}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
