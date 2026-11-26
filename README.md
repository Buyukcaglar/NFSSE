# NFSSE
<a href="https://recomplauncher.com"><picture><source media="(prefers-color-scheme: dark)" srcset="https://recomplauncher.com/assets/press/launcher/badge-light.svg"><img alt="Get it on RecompLauncher" src="https://recomplauncher.com/assets/press/launcher/badge-dark.svg" height="48"></picture></a>

Native ports of **The Need for Speed: Special Edition** (the 1996 Windows 95
version) for **Windows (64-bit)**, **macOS** (Apple silicon and Intel),
**PlayStation 3** and **PlayStation Vita**. They are made from the original game
program by static recompilation and run natively, with no emulator or
compatibility layer: Enhanced 3D at the display's resolution, a widescreen race,
a longer draw distance, controllers with analog steering, and force feedback.
The downloads contain no game data: you need your own copy of the game.

- **v1.4.1**, the latest ([release](https://github.com/Buyukcaglar/NFSSE/releases/tag/v1.4.1),
  [notes](docs/RELEASE_NOTES_v1.4.1.md)): with km/h on, the replay buttons
  and other race pictures are English again.
- **v1.4** ([release](https://github.com/Buyukcaglar/NFSSE/releases/tag/v1.4),
  [notes](docs/RELEASE_NOTES_v1.4.md)): speeds in km/h and distances in km
  (the game's own metric displays), and two widescreen fixes (top corners,
  sky). Windows, PS3 and PS Vita files; the macOS file follows (until then it
  is on v1.1).
- **v1.3** ([release](https://github.com/Buyukcaglar/NFSSE/releases/tag/v1.3),
  [notes](docs/RELEASE_NOTES_v1.3.md)): upscaled movies (a `VIDEO` folder next
  to the program replaces the game's 320x200 movies), the PlayStation 3 file
  with the v1.2 changes, and PS Vita fixes (Enhanced 3D speed, Exit). Windows,
  PS3 and PS Vita files; the macOS file follows (until then it is on v1.1).
- **4K upscaled movies** for Windows and macOS: the
  [NFSSE 4K Upscaled Video Pack](https://www.moddb.com/games/the-need-for-speed/downloads/nfsse-4k-upscaled-video-pack)
  on ModDB (all 26 movies, 2.1 GB). Unzip it next to `NFSSE.exe` (v1.3 or
  later); the macOS application plays them from its next version. For the
  consoles (v1.3 or later), the same movies re-encoded for their decoders:
  [PS3 1080p pack](https://www.moddb.com/games/the-need-for-speed/downloads/nfsse-ps3-1080p-upscaled-video-pack) (0.9 GB, its `VIDEO` folder to
  `/dev_hdd0/game/NFSSE0001/USRDIR/`) and
  [PS Vita 544p pack](https://www.moddb.com/games/the-need-for-speed/downloads/nfsse-ps-vita-544p-upscaled-video-pack) (0.2 GB, to
  `ux0:data/NFSSE/`).
- **v1.2** ([release](https://github.com/Buyukcaglar/NFSSE/releases/tag/v1.2),
  [notes](docs/RELEASE_NOTES_v1.2.md)): force feedback and rumble, and the PS
  Vita version at 960x544.
- **v1.1** ([release](https://github.com/Buyukcaglar/NFSSE/releases/tag/v1.1),
  [notes](docs/RELEASE_NOTES_v1.1.md)): widescreen race and a longer draw
  distance.
- **v1.0** ([release](https://github.com/Buyukcaglar/NFSSE/releases/tag/v1.0),
  [notes](docs/RELEASE_NOTES_v1.0.md)): the first native versions, with
  installation and controls.

## Play through a launcher (Windows)

The Windows version can also be installed and started by two launchers.
Neither launcher contains or downloads the game: both use your own copy.

- **[RecompLauncher](https://recomplauncher.com)**: install NFSSE there, pick
  your game folder once and press Play. The folder is your full copy of the
  English Windows 95 Special Edition, the CD or a folder with everything from
  it, the one that holds `NFS_WIN.EXE`, `FRONTEND` and `SIMDATA`. The launcher
  starts `NFSSE.exe "<folder>"`. Enhanced 3D, widescreen race, full screen, CRT
  scanlines and km/h are settings on the game's page there; saves, settings
  and the log are in `USER\` beside the program.
- **[sp00nznet's recomp-launcher](https://github.com/sp00nznet/recomp-launcher)**:
  an installer can be built from the `launcher/` folder of this repository.
  Until one is on a release, the same setup runs by hand from a copy of this
  repository: `powershell -ExecutionPolicy Bypass -File launcher\setup.ps1 -Game "<folder>"`.
  It downloads the newest Windows release into `play\` and writes
  `The Need for Speed SE (recomp).cmd`, which starts the program with your
  game folder.

The PS3 and PS Vita versions are not part of either launcher.

## Earlier: the compatibility patch kit (v0.2.2)

The rest of this page describes the earlier compatibility patch kit for the
original Windows game (v0.2.2), which stays available under
[its own release](https://github.com/Buyukcaglar/NFSSE/releases/tag/v0.2.2).

**v0.2.2** fixes player-name persistence and legacy save-space checks while
keeping settings and progress inside the game folder. The user confirmed the
play checks passed on 2026-10-07. See [Player persistence](docs/PLAYER_PERSISTENCE.md)
for save locations and validation details.

[![Build and validate](https://github.com/Buyukcaglar/NFSSE/actions/workflows/build.yml/badge.svg)](https://github.com/Buyukcaglar/NFSSE/actions/workflows/build.yml)

Modern Windows compatibility patch for **The Need for Speed Special Edition**, Windows version. It creates a portable installation from your own installation media, scales the original graphics in fullscreen or a movable window, and fixes the startup, video and menu problems investigated in this project.

[Patch kit](https://github.com/Buyukcaglar/NFSSE/releases/tag/v0.2.2) · [v0.2.2 release](https://github.com/Buyukcaglar/NFSSE/releases/tag/v0.2.2) · [Release notes](docs/RELEASE_NOTES_v0.2.2.md) · [User guide](docs/USER_GUIDE.md) · [Validation and limits](docs/VALIDATION.md) · [Report a problem](https://github.com/Buyukcaglar/NFSSE/issues/new/choose)

This release also retains the accepted Japanese Graphics fix and optional English/German/Japanese selection. Fresh installation uses your original media and a new, empty destination; Japanese also requires its original media. Existing v0.2.1 kit installations can be updated in place as described in the [user guide](docs/USER_GUIDE.md). The standard English installation remains the default. The original game engine, renderer, full window title and original icon are retained. I-Force remains reported working.

## Install and play

1. Download `NFSSE-v0.2.2-patch-kit.zip` from the [v0.2.2 release](https://github.com/Buyukcaglar/NFSSE/releases/tag/v0.2.2) and extract the complete ZIP.
2. Double-click `Install-NFSSE.cmd`.
3. Select the folder containing your original `NFS_WIN.EXE`, `FRONTEND`, `SIMDATA`, `GAMEDATA`, `REDIST` and `DIRECTX3`. Choose a new, empty destination folder outside your media and existing game folders.
4. Optionally enable the language-selector window. Supply your Japanese media folder to add Japanese; otherwise English/German are available and Japanese is disabled.
5. Double-click `NFSSE.exe` in the destination. Move that complete folder to relocate the installation.

The installer uses Windows PowerShell and the .NET Framework included with Windows. Players do not need Python, Visual Studio, a system-wide DirectX installation or administrator privileges. Keep the destination writable for settings, saves and the runtime log. Approximately 520 MB is required for standard game data, plus space for optional Japanese resources and backups.

This release supports one verified English media executable: 1,069,056 bytes, SHA-256 `ac72e59587b66f9a3bb2bdb83fa40b8eaac2d68a5ae47a041b026922f8d2594b`. The installer rejects other builds. The patch kit contains the new compatibility helper and the licensed cnc-ddraw renderer; users supply the original game, icon and legacy support DLLs from their own media.

## Included changes

- v0.2.2 saves a confirmed player name immediately and checkpoints settings/records on normal exit. Complete flushed writes preserve the previous configuration if saving fails.
- Modern 64-bit free-space checks replace the original checks that could incorrectly report a full disk. Names/settings/records use `GAMEDATA/CONFIG/CONFIG.DAT`; tournament Save/Load uses `GAMEDATA/SAVEGAME/*.SAV`. All paths remain relative to the game folder.
- v0.2.1 generates Japanese graphics archives that fit the original game's loading buffer. Their decoded artwork is unchanged. Fresh installation builds them from the user's verified media.
- The optional language selector opens language flags before play. German selects all eleven original German announcer recordings; English/Japanese use the English recordings. Languages share saves and settings.
- Borderless display scaling preserves each original mode's proportions and leaves the desktop resolution unchanged. Gameplay retains its original internal resolution.
- v0.1.5 displays `The Need for Speed: Special Edition` as the game window title.
- v0.1.3 makes Alt+Enter windowed mode movable through a standard title bar and border. Above a desktop height of 960 pixels, it fixes the client area at 1280×960; at 960 or below, the configured size is retained. The check uses height only and runs at each launch.
- v0.1.2 releases stale keyboard states after Alt+Tab and handles Alt+F4 directly. Its installer adds missing Alt+Enter/mouse settings to older configurations with an exact backup, preserving explicit custom values.
- Executable-relative paths and locally copied assets allow play without the physical CD.
- Race announcer clips are copied beside the executable, matching the original installer. Users of v0.1.0 can rerun the latest installer against their existing installation to add the missing clips.
- Startup fixes cover legacy memory reporting, VGA scratch pointers, privileged instructions and graphics initialization timing.
- Legacy DirectPlay providers load from the game folder.
- Buffered file reads, synchronized video presentation and periodic redraws address the observed video and menu failures.
- The original `NFSICONN.ICO` is embedded in the generated `NFSSE.exe`; v0.1.4 also assigns that embedded icon to the game window class for the title bar.
- Original I-Force code and `IFORCE.DLL` are retained. I-Force is reported working and the [backlog item](docs/BACKLOG.md) is closed with no further work planned.

Videos, menu clicks, attract mode and relocation were accepted with the earlier helper on Windows 11. The window presentation, title and icon are also visually accepted. The user confirmed the v0.2.2 persistence play checks passed. Separate focus/shortcut checks, exhaustive race/championship coverage, other hosts and multiplayer remain open. The [validation record](docs/VALIDATION.md) distinguishes automated checks, user acceptance and the I-Force working report.

## Project contents

| Location | Contents |
| --- | --- |
| `src/` | 32-bit compatibility helper and native language selector source |
| `Install-NFSSE.ps1`, `config/` | Media-validated installer, patch recipe, relative paths and graphics defaults |
| `tools/` | Build, release packaging, PE icon embedding and executable analysis |
| `tests/` | Persistence, input, window policy, language selection and resource conversion checks |
| `research/` | Static analysis, diagnostic variants, selected logs and measured validation results |
| `docs/` | User guide, build guide, technical notes, session history, validation and backlog |
| `licenses/` | Redistributed renderer's MIT license |

Start with [Building](docs/BUILDING.md) for development, [Technical notes](docs/TECHNICAL_NOTES.md) for patch details, and [Session history](docs/SESSION_HISTORY.md) for the investigation. [Third-party components](docs/THIRD_PARTY.md) lists provenance and redistribution boundaries.

The [language edition guide](docs/LANGUAGE_EDITION.md) documents the optional features and command-line installation. The user accepted the local three-language checks and subsequently confirmed the Japanese Graphics crash resolved on 2026-10-06. Native selection, Windows resource conversion and packaged installer/preservation checks pass. Original Japanese name/exit dialogs and race announcements remain English. The kit contains no original game executable, artwork, recordings or icon; game resources come from the user's media.

The new code and documentation are MIT-licensed. The original game remains subject to its original ownership and licensing. This is an independent preservation project, unaffiliated with Electronic Arts.
