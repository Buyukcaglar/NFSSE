# English, German and Japanese edition

Double-click **NFSSE.exe**. Select the English, German or Japanese flag to start
the game in that language. Close the selection window or press Escape to cancel.
Tab/arrows and Enter work too; keys 1, 2 and 3 select the displayed languages.

The selector appears on every launch. Quit the game before changing languages.
Saves, player names, controls, display and sound choices are shared. Keep the
whole game folder together when moving it. Normal play needs only Windows;
Python, PowerShell, source media and development tools are not needed.

`NFSSE-Game.exe` is the original accepted patched game, with its original icon,
compatibility helper and renderer unchanged. Use **NFSSE.exe** for normal play.
The selector verifies the chosen resources before starting it and prevents a
second selector from changing files while the game runs.

## Install optional features

Use the v0.2.1 PatchKit with your supported original English media and a new, empty destination folder outside your media and existing game folders. The default installation starts directly in English. Choose the language-selector option during installation, or run:

```powershell
.\Install-NFSSE.ps1 -SourceMedia "C:\Media\English" -Destination "C:\Games\NFSSE" -LanguageSelector -NonInteractive
```

English and German use resources already on that disc. All three flags appear; Japanese is disabled until its verified media is supplied:

```powershell
.\Install-NFSSE.ps1 -SourceMedia "C:\Media\English" -Destination "C:\Games\NFSSE" -JapaneseMedia "C:\Media\Japanese" -NonInteractive
```

`-JapaneseMedia` enables the selector automatically. The installer validates the original Japanese executable and 435 input files, then builds 436 compatible outputs using Windows' built-in C# compiler. No Python or downloaded conversion tools are needed.

v0.2.1 generates corrected Japanese graphics resources during installation from
the original media. The user confirmed that Graphics selection no longer
crashes. Follow the fresh-installation steps above; the completed installation
contains all resources required for normal play.

## Languages and voices

English uses the original English resources and race announcements. German
uses the original German menus, showroom, narration, dashboard, slides and
track previews, plus the engine's `GERMAN` setting for its dialogs, help, HUD
and police movies. All eleven German race-announcer recordings differ from
English; the selector installs the original German recordings beside the game
before starting it. Returning to English or Japanese restores English race
announcements. Recordings are copied unchanged, without transcoding.

Japanese retains the resource compatibility work checked in the prototype. Its
original eleven race-announcer files are identical to English. The original
Japanese executable also uses English for `ENTER NAME`, `Please Enter Name`
and `Exit to system ?`; these dialogs remain English. The engine has English
and German dialog/font branches only. This edition adds no Japanese text entry.

Seven graphics-option elements retain the original English/numeric labels, as
documented in the Japanese prototype. Artwork and recordings come from the
original media; the flags are drawn by the native Windows selector.

## Acceptance checks

The user reported the Japanese prototype checks looking OK, then confirmed
"Everything looks ok" for the local three-language integration on 2026-10-06.
The following focused checklist remains useful when installing on another host:

1. Double-click NFSSE.exe, check the three flags, then cancel. The game should
   stay closed.
2. Select English. Check a menu/showroom and a race announcement.
3. Quit, launch again, select German. Check German menus, name/exit dialogs,
   showroom narration, HUD and race announcements (position/final lap/best time).
4. Quit and select Japanese. Check the accepted Japanese menus/HUD/narration,
   English race announcements and the original English name/exit dialogs.
5. Switch back to English. Confirm your player/save, controls and display/sound
   choices remain available. Check the accepted title/icon and Alt+Enter.

Keep `portable-runtime.log` if a game problem occurs. Verification and successful
compilation are separate from these in-game checks.

## Repository development workflow

The following Python reference tools are for repository development; the release
installer does not require Python. From the repository root, with the supported
installation and both original media folders present:

```powershell
tools\build-language-launcher.cmd
tools\test-languages.cmd
python tools/build-language-edition.py
python tools/verify-language-edition.py
```

After verifying the new output, `python tools/install-language-edition.py`
updates the normal `NFSSE` installation. It requires that the existing files
still match the build's source snapshot. It backs up overwritten managed files,
the current language table/configuration and original announcers under
`build/language-install-backups`, preserves user data, and installs the public
selector last. `--edition`, `--game-root` and `--backup-root` select other paths.

The default output is `build/multilingual-game`. The builder requires a fresh
output and accepts `--base-game`, `--english-media`, `--japanese-media`,
`--launcher` and `--destination`. It preserves all base installation files and
user data in the new edition, except that NFSSE.exe becomes the selector while
its original bytes are preserved as NFSSE-Game.exe. Original media stay untouched.

`language-edition.json` and `LANG/language-edition.index` describe the installed
runtime/resources. The developer verifier exercises all three real selections
without starting the game. The original English installer/release remains
available. Use the v0.2.1 installer for fresh language-edition installations. The local complete
game and original recordings/artwork must not be included in a public patch kit.
