"""Verify media provenance and resource semantics without launching the game."""
import argparse
import datetime
import hashlib
import json
from pathlib import Path
from nfs_resources import Archive, GRAPHICS_ENGLISH_ENTRIES, decode_qfs

ROOT = Path(__file__).resolve().parent.parent


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--game-root', type=Path, default=ROOT / 'build/japanese-prototype')
    parser.add_argument('--base-game', type=Path, default=ROOT / 'NFSSE')
    parser.add_argument('--english-media', type=Path, default=ROOT / 'install')
    parser.add_argument('--japanese-media', type=Path, default=ROOT / 'japanese')
    parser.add_argument('--output', type=Path, default=ROOT / 'research/validation/japanese-prototype-assets.json')
    args = parser.parse_args()
    game, base, english, japanese = args.game_root, args.base_game, args.english_media, args.japanese_media
    profile = json.loads((ROOT / 'config/japanese-resource-profile.json').read_text())
    manifest = json.loads((game / 'japanese-prototype.json').read_text())
    snapshot = json.loads((game / 'base-game-snapshot.json').read_text())
    require(manifest['profile'] == profile['id'], 'Unexpected prototype profile')
    for name, expected in profile['runtime_sha256'].items():
        require(digest(game / name) == expected == digest(base / name), f'Runtime changed: {name}')
    for entry in manifest['resource_files']:
        require(digest(game / entry['path']) == entry['sha256'], f'Resource changed: {entry["path"]}')
    edited = {'LANG/JA/ART/CHECK/GRAPHICS.FSH', 'LANG/JA/ART/CHECK/GRAPHICS.QFS',
              'LANG/JA/ART/OPTION/GRAPHICS.QFS', 'LANG/JA/MISC/MASKHI.FSH', 'LANG/JA/MISC/MASKLO.FSH'}
    unchanged_imports = 0
    for entry in profile['files']:
        require(digest(japanese / entry['path']) == entry['sha256'], 'Japanese source changed')
        if entry['target'] not in edited:
            require(digest(game / entry['target']) == entry['sha256'], 'Imported resource differs from media')
            unchanged_imports += 1
    jp_graphics = Archive((japanese / 'FRONTEND/ART/OPTION/GRAPHICS.QFS').read_bytes())
    en_graphics = Archive((english / 'FRONTEND/ART/OPTION/GRAPHICS.QFS').read_bytes())
    graphics_records = []
    for folder in ('OPTION', 'CHECK'):
        raw = (game / f'LANG/JA/ART/{folder}/GRAPHICS.FSH').read_bytes()
        result = Archive(raw)
        expected_order = Archive((english / f'FRONTEND/ART/{folder}/GRAPHICS.QFS').read_bytes()).order
        require(result.order == expected_order, 'Graphics directory order changed')
        require(decode_qfs((game / f'LANG/JA/ART/{folder}/GRAPHICS.QFS').read_bytes()) == raw, 'QFS/FSH differ')
        for tag in result.order:
            expected = en_graphics if tag in GRAPHICS_ENGLISH_ENTRIES else jp_graphics
            require(result.blobs[tag] == expected.blobs[tag], f'Graphics blob changed: {tag!r}')
        require(jp_graphics.blobs[b'!pal'] == en_graphics.blobs[b'!pal'] == result.blobs[b'!pal'], 'Palette changed')
        graphics_records.append({'context': folder, 'entries': len(result.order),
                                 'unchanged_japanese_blobs': len(result.order) - 7,
                                 'unchanged_english_control_blobs': 7, 'palette_exact': True})
    hud_records = []
    for name in ('MASKHI.FSH', 'MASKLO.FSH'):
        original = Archive((english / 'SIMDATA/MISC' / name).read_bytes())
        source = Archive((japanese / 'SIMDATA/MISC' / name).read_bytes())
        result = Archive((game / 'LANG/JA/MISC' / name).read_bytes())
        require(result.order == original.order, 'HUD directory order changed')
        for tag in result.order:
            require(result.blobs[tag] == source.blobs[tag], f'HUD pixels/metadata changed: {tag!r}')
        hud_records.append({'archive': name, 'entries': len(result.order),
                            'pixels_and_placement_exact': True,
                            'extra_entries_omitted': len(set(source.order) - set(result.order))})
    require((game / 'GAMEDATA/CONFIG/PATHS.DAT').read_bytes() == (game / 'LANG/Japanese.paths').read_bytes(), 'Japanese is not selected')
    en = (game / 'LANG/English.paths').read_bytes()
    ja = (game / 'LANG/Japanese.paths').read_bytes()
    changed = [n for n in range(19) if en[n * 80:(n + 1) * 80] != ja[n * 80:(n + 1) * 80]]
    require(changed == [2, 5, 9, 17, 18], 'Shared data routing changed')
    require((game / 'nfs.cfg').read_bytes().split()[2] == b'ENGLISH', 'Engine language changed')
    preserved = 0
    for relative, expected in snapshot.items():
        require(digest(base / relative) == expected, f'Original installation changed: {relative}')
        if relative != 'GAMEDATA/CONFIG/PATHS.DAT':
            require(digest(game / relative) == expected, f'Cloned original file changed: {relative}')
            preserved += 1
    police_identity = all(digest(japanese / f'FRONTEND/MOVIE/COP{n}.TGV') ==
                          digest(japanese / f'FRONTEND/MOVIE/GCOP{n}.TGV') for n in range(1, 4))
    require(police_identity, 'Police movie identity changed')
    result = {'profile': profile['id'], 'checked_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
              'game_launched': False, 'runtime_components_identical': 3,
              'original_installation_files_unchanged': len(snapshot), 'cloned_original_files_unchanged': preserved,
              'japanese_imports_exact': unchanged_imports, 'output_resource_files': len(manifest['resource_files']),
              'graphics': graphics_records, 'hud': hud_records, 'changed_path_records': changed,
              'shared_path_records_unchanged': 14, 'police_movies_identical': police_identity,
              'resource_pixels_synthesized_or_resampled': False, 'speech_transcoded': False,
              'runtime_visual_audio_acceptance': 'pending user test'}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(f'Asset provenance passed: {unchanged_imports} exact imports, 2 graphics contexts, 2 HUD archives; {len(snapshot)} original files preserved.')


if __name__ == '__main__':
    main()
