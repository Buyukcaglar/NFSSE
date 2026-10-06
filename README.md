# NFSSE

[![Build and validate](https://github.com/Buyukcaglar/NFSSE/actions/workflows/build.yml/badge.svg)](https://github.com/Buyukcaglar/NFSSE/actions/workflows/build.yml)

Modern Windows compatibility patch for **The Need for Speed Special Edition**, Windows version. It creates a portable installation from your own installation media, scales the original graphics in fullscreen or a movable window, and fixes the startup, video and menu problems investigated in this project.

[Latest patch kit](https://github.com/Buyukcaglar/NFSSE/releases/latest) · [v0.2.1 release](https://github.com/Buyukcaglar/NFSSE/releases/tag/v0.2.1) · [User guide](docs/USER_GUIDE.md) · [Validation and limits](docs/VALIDATION.md) · [Report a problem](https://github.com/Buyukcaglar/NFSSE/issues/new/choose)

**v0.2.1 fixes opening Graphics in Japanese** while retaining optional English/German/Japanese language selection. Install from your original media into a new, empty destination folder; Japanese also requires its original installation media. The user confirmed that Graphics selection no longer crashes. The standard English installation remains the default. The game engine, accepted compatibility helper, renderer, full window title and original icon are unchanged. I-Force remains reported working.

## Install and play

1. Download `NFSSE-v0.2.1-patch-kit.zip` from the [latest release](https://github.com/Buyukcaglar/NFSSE/releases/latest) and extract the complete ZIP.
2. Double-click `Install-NFSSE.cmd`.
3. Select the folder containing your original `NFS_WIN.EXE`, `FRONTEND`, `SIMDATA`, `GAMEDATA`, `REDIST` and `DIRECTX3`. Choose a new, empty destination folder outside your media and existing game folders.
4. Optionally enable the language-selector window. Supply your Japanese media folder to add Japanese; otherwise English/German are available and Japanese is disabled.
5. Double-click `NFSSE.exe` in the destination. Move that complete folder to relocate the installation.

The installer uses Windows PowerShell and the .NET Framework included with Windows. Players do not need Python, Visual Studio, a system-wide DirectX installation or administrator privileges. Keep the destination writable for settings, saves and the runtime log. Approximately 520 MB is required for standard game data, plus space for optional Japanese resources and backups.

This release supports one verified English media executable: 1,069,056 bytes, SHA-256 `ac72e59587b66f9a3bb2bdb83fa40b8eaac2d68a5ae47a041b026922f8d2594b`. The installer rejects other builds. The patch kit contains the new compatibility helper and the licensed cnc-ddraw renderer; users supply the original game, icon and legacy support DLLs from their own media.

## Included changes

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

Videos, menu clicks, attract mode and relocation were accepted with the earlier helper on Windows 11. The v0.1.3 window-presentation visual task is accepted on the user's setup; the title and icon are also visually accepted. Separate nonvisual input/exit checks remain open. A complete manual race, save/reload cycle and multiplayer remain unverified. The [validation record](docs/VALIDATION.md) distinguishes these checks and the I-Force working report.

## Project contents

| Location | Contents |
| --- | --- |
| `src/` | 32-bit compatibility helper and native language selector source |
| `Install-NFSSE.ps1`, `config/` | Media-validated installer, patch recipe, relative paths and graphics defaults |
| `tools/` | Build, release packaging, PE icon embedding and executable analysis |
| `tests/` | Media-independent input, window policy, language selection and resource conversion checks |
| `research/` | Static analysis, diagnostic variants, selected logs and measured validation results |
| `docs/` | User guide, build guide, technical notes, session history, validation and backlog |
| `licenses/` | Redistributed renderer's MIT license |

Start with [Building](docs/BUILDING.md) for development, [Technical notes](docs/TECHNICAL_NOTES.md) for patch details, and [Session history](docs/SESSION_HISTORY.md) for the investigation. [Third-party components](docs/THIRD_PARTY.md) lists provenance and redistribution boundaries.

The [language edition guide](docs/LANGUAGE_EDITION.md) documents the optional features and command-line installation. The user accepted the local three-language checks and subsequently confirmed the Japanese Graphics crash resolved on 2026-10-06. Native selection, Windows resource conversion and packaged installer/preservation checks pass. Original Japanese name/exit dialogs and race announcements remain English. The kit contains no original game executable, artwork, recordings or icon; game resources come from the user's media.

The new code and documentation are MIT-licensed. The original game remains subject to its original ownership and licensing. This is an independent preservation project, unaffiliated with Electronic Arts.
