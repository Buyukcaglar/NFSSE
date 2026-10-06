# Japanese resource prototype

This is an experimental English/Japanese resource selector for the supported
patched English game. It preserves the v0.1.5 executable, compatibility helper
and renderer. On 2026-10-06 the user reported the prototype checks looking OK.
The completed local selection workflow is now the
[English/German/Japanese edition](LANGUAGE_EDITION.md); this document records the
earlier two-language prototype and its resource derivations.

## Play the local prototype

The development build is under `build/japanese-prototype`:

- Double-click `Play-Japanese.cmd` to select Japanese resources and play.
- Double-click `Play-English.cmd` to restore English resources and play.
- `Select-Language.cmd` changes the selection without starting the game.
- Direct `NFSSE.exe` launch uses the last selected language. Japanese is selected
  when the prototype is built.

Close this prototype before switching. Saves, controls, sound/video choices and
graphics settings are shared between its two languages. The normal installation
and original media remain separate. Keep the complete prototype folder together
when moving it. The launchers use Windows' built-in PowerShell; Python is needed
only to build the prototype.

## What is included

The prototype imports hash-verified Japanese art, showroom, narration and HUD
resources into `LANG/JA`. Five of the nineteen records in `PATHS.DAT` select
these directories. Config/save/replay paths, cars, tracks, music, sound banks,
dashboards and race announcer files retain their existing paths and bytes.
`nfs.cfg` stays on the `ENGLISH` engine branch; it has no Japanese resource option.

The graphics screen is derived from the original Japanese `OPTION/GRAPHICS.QFS`.
Its palette is byte-identical to the English OPTION palette. Four missing auto
detail controls and three 320×200 labels come from the English OPTION resource,
with their original pixels and metadata. This derived screen is used for both
OPTION and CHECK contexts. It avoids palette conversion and matches each English
directory order. Those seven controls retain their original English/numeric text.
The archives use lossless RefPack encoding with backreferences; no artwork is generated or
resampled.

The earlier literal-only encoder made these files larger than the game's
decoded-size-plus-1024-byte loading workspace and caused the reported Japanese
graphics-menu sentinel crash. The repaired encoder checks both that allocation
and every in-place decoding boundary. The decoded archives remain byte-identical.

Both HUD archives retain all original Japanese entry blobs requested by the
English engine, in the English directory order. The 67 extra low-resolution
Japanese entries are omitted. Pixels and placement metadata are unchanged.
Their visible geometry still needs testing, especially in the low resolution.

Further inspection found that the Japanese media's `GCOP1–3` files are identical
to its English `COP1–3` files. Police movies therefore use the existing English
paths; no different Japanese police recording is claimed. The 41 changed
narration files are copied without transcoding. Their codec is already present
in other English-media clips. The user subsequently reported the prototype
checks looking OK; individual audio samples were not independently auditioned.
All eleven race-announcer clips are identical between these media sets.

Some dialogs, help and fonts remain English/German in the original media.
This prototype does not add Japanese text entry or IME support.

## Focused user checks

1. Open the main menu, options and a car showroom. Confirm Japanese labels,
   navigation, mouse hit regions and narration.
2. Open graphics settings from both the menu and a paused race. Exercise auto
   detail choices, 640×480 and 320×200. Check text, clipping and mouse selection.
3. Drive a race. Check Japanese camera/HUD labels, pause/replay controls, warning
   screens, police movies and race announcements.
4. Save and quit normally. Use `Play-English.cmd`, load the same save and verify
   English resources. Quit, return to Japanese and confirm the same settings.
5. Check the already accepted window sizing, scaling, title/icon and Alt+Enter.

Record the first failing screen/action and retain `portable-runtime.log` if a
problem occurs. Static resource checks do not establish these runtime results.

## Rebuild and verify

From the repository root, with the current accepted English installation and
both original media folders present:

```powershell
python tools/build-japanese-prototype.py
```

Use `--base-game`, `--english-media`, `--japanese-media` and `--destination` for
other locations. The destination must be new and outside all three inputs.
The builder rejects unsupported runtimes, modified resource inputs and custom
base path tables before copying. An incomplete staging folder is retained for
diagnosis on failure; it never replaces an existing destination.

```powershell
python -m unittest discover -s tests -p test_nfs_resources.py
powershell -NoProfile -ExecutionPolicy Bypass -File tools/test-japanese-prototype.ps1 -GameRoot build/japanese-prototype
python tools/verify-japanese-prototype.py
```

The integration check switches languages without launching the game, exercises
integrity/configuration/locking rejection, checks writable-data preservation and
leaves Japanese selected. Only the prototype's path table and its first-switch
backup are managed by the selector. Custom path edits are refused and preserved.
English selection remains available if a Japanese resource has been modified.

`japanese-prototype.json` records output hashes and every derived resource.
`base-game-snapshot.json` records the cloned installation's file hashes.
The asset verifier checks exact media imports, original entry blobs and palettes,
English/Japanese routing, unchanged runtime components and the original game
snapshot. The local prototype passed six resource unit tests and the selection
and provenance checks; see `research/validation/japanese-prototype-validation.json`
and `research/validation/japanese-prototype-assets.json`. No game was launched.
No original executables, artwork, recordings or generated game folders are
included in the repository or a public patch kit. This prototype does not change
the released installer's supported media list.
