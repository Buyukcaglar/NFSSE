"""Exercise the extracted optional-feature PatchKit without starting the game."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
from build_language_support import load_builder

ROOT = Path(__file__).resolve().parent.parent
builder = load_builder()


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--kit', type=Path, required=True)
    ap.add_argument('--english-media', type=Path, default=ROOT / 'install')
    ap.add_argument('--japanese-media', type=Path, default=ROOT / 'japanese')
    ap.add_argument('--output-root', type=Path, required=True)
    args = ap.parse_args()
    kit, english, japanese, output = (p.resolve() for p in (args.kit, args.english_media, args.japanese_media, args.output_root))
    builder.require(not output.exists(), 'Use a new test output folder')
    output.mkdir(parents=True)
    shell = Path(os.environ['SystemRoot']) / 'System32/WindowsPowerShell/v1.0/powershell.exe'
    recipe = json.loads((kit / 'config/patch-recipe.json').read_text())
    profile = json.loads((kit / 'config/japanese-resource-profile.json').read_text())
    checks = []
    def run(name, game, options=(), success=True):
        with (output / (name + '.log')).open('w', encoding='utf-8') as log:
            result = subprocess.run([str(shell), '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', str(kit / 'Install-NFSSE.ps1'),
                                     '-SourceMedia', str(english), '-Destination', str(game), '-NonInteractive', *options], stdout=log, stderr=subprocess.STDOUT)
        builder.require((result.returncode == 0) == success, f'{name} returned {result.returncode}; inspect its log')
        checks.append(name)
        print(f'Passed: {name}', flush=True)
    def select(game, language):
        subprocess.run([str(ROOT / 'build/LanguageEditionCheck.exe'), str(game), language], check=True, stdout=subprocess.DEVNULL)
    game = output / 'game'
    run('fresh-english-german-option', game, ['-LanguageSelector'])
    builder.require(builder.digest(game / 'NFSSE-Game.exe') == recipe['final_executable_sha256'], 'Engine changed')
    index = (game / 'LANG/language-edition.index').read_text()
    builder.require('\nJ\t' not in index, 'Japanese became available without media')
    select(game, '--verify')
    save = game / 'GAMEDATA/SAVEGAME/feature-test.sav'; save.write_bytes(b'PLAYER SAVE SENTINEL')
    config_dat = game / 'GAMEDATA/CONFIG/CONFIG.DAT'; config_dat.write_bytes(b'PLAYER SETTINGS SENTINEL')
    config = game / 'nfs.cfg'; config.write_bytes(b'NOSOUND LOWVIDEO ENGLISH NOREMOTE \r\n')
    ddraw = game / 'ddraw.ini'; ddraw.write_bytes(ddraw.read_bytes() + b'\r\n; USER DISPLAY CHOICE\r\n')
    user_hashes = {p: builder.digest(p) for p in (save, config_dat, ddraw)}
    select(game, 'German')
    state = ['nfs.cfg', 'GAMEDATA/CONFIG/PATHS.DAT'] + recipe['race_speech_files']
    before_state = {p: (game / p).read_bytes() for p in state}
    run('reinstall-preserves-enabled-feature-and-german-selection', game)
    builder.require(all((game / p).read_bytes() == b for p, b in before_state.items()), 'Reinstall changed selected language')
    run('add-japanese-option', game, ['-JapaneseMedia', str(japanese)])
    builder.require(all((game / p).read_bytes() == b for p, b in before_state.items()), 'Japanese addition changed current language')
    expected = builder.japanese_pack(japanese, english, profile)
    for path, data in expected.items():
        builder.require((game / path).read_bytes() == data, f'Windows installer differs from reference: {path}')
    builder.require(len(expected) == 436, 'Unexpected Japanese resource count')
    for language in ('English', 'German', 'Japanese'):
        select(game, language)
        builder.require((game / 'GAMEDATA/CONFIG/PATHS.DAT').read_bytes() == builder.paths_for(recipe, language), 'Wrong path routing')
        folder = 'GSPEECH' if language == 'German' else 'SPEECH'
        for name in recipe['race_speech_files']:
            builder.require((game / name).read_bytes() == (english / 'FRONTEND' / folder / name).read_bytes(), f'Wrong voice: {language}/{name}')
    run('reinstall-preserves-japanese-without-source-media-argument', game)
    builder.require((game / 'GAMEDATA/CONFIG/PATHS.DAT').read_bytes() == builder.paths_for(recipe, 'Japanese'), 'Japanese selection was lost')
    for target, replacement, name in [
        (game / 'LANG/JA/SPEECH/NSXGEN16.EAS', b'CUSTOM RESOURCE', 'damaged-japanese-preserved'),
        (game / 'GAMEDATA/CONFIG/PATHS.DAT', b'CUSTOM PATHS', 'custom-paths-preserved'),
        (game / 'FIRST.EAS', b'CUSTOM AUDIO', 'custom-announcer-preserved')]:
        data = target.read_bytes(); target.write_bytes(replacement)
        before = builder.snapshot(game)
        run(name, game, success=False)
        builder.require(builder.snapshot(game) == before, f'{name} wrote to the destination')
        target.write_bytes(data)
    select(game, 'German')
    run('disable-selector-restores-direct-english-play', game, ['-DisableLanguageSelector'])
    builder.require(builder.digest(game / 'NFSSE.exe') == recipe['final_executable_sha256'], 'Direct executable was not restored')
    builder.require(config.read_bytes() == b'NOSOUND LOWVIDEO ENGLISH NOREMOTE \r\n', 'Disable changed other choices')
    for name in recipe['race_speech_files']:
        builder.require((game / name).read_bytes() == (english / 'FRONTEND/SPEECH' / name).read_bytes(), 'Disable left German announcements')
    run('reenable-preserves-installed-japanese-pack', game, ['-LanguageSelector'])
    select(game, 'Japanese')
    builder.require(all(builder.digest(p) == h for p, h in user_hashes.items()), 'User saves/settings changed')
    invalid = output / 'unsupported-japanese'; invalid.mkdir(); (invalid / 'NFS.EXE').write_bytes(b'WRONG BUILD')
    rejected = output / 'rejected-japanese-output'
    run('unsupported-japanese-before-destination-write', rejected, ['-JapaneseMedia', str(invalid)], success=False)
    builder.require(not rejected.exists(), 'Invalid Japanese input created destination files')
    result = {'version': '0.2.0', 'checked_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'passed': True,
              'game_launched': False, 'selector_ui_launched': False, 'shell': 'Windows PowerShell 5.1',
              'python_required_by_installer': False, 'cases': checks, 'japanese_outputs_match_python_reference': len(expected),
              'german_announcer_files_selected': 11, 'shared_saves_settings_preserved': True,
              'engine_helper_renderer_unchanged': True, 'invalid_or_custom_inputs_rejected_before_destination_write': True}
    (output / 'language-installer-validation.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
