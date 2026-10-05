# NFSSE

[![Build and validate](https://github.com/Buyukcaglar/NFSSE/actions/workflows/build.yml/badge.svg)](https://github.com/Buyukcaglar/NFSSE/actions/workflows/build.yml)

Modern Windows compatibility patch for **The Need for Speed Special Edition**, Windows version. It creates a portable installation from your own installation media, scales the original graphics in a borderless window, and fixes the startup, video and menu problems investigated in this project.

[Download the patch kit](https://github.com/Buyukcaglar/NFSSE/releases/latest) · [User guide](docs/USER_GUIDE.md) · [Validation and limits](docs/VALIDATION.md) · [Report a problem](https://github.com/Buyukcaglar/NFSSE/issues/new/choose)

## Install and play

1. Download `NFSSE-v0.1.0-patch-kit.zip` from Releases and extract the complete ZIP.
2. Double-click `Install-NFSSE.cmd`.
3. Select the folder containing your original `NFS_WIN.EXE`, `FRONTEND`, `SIMDATA`, `GAMEDATA`, `REDIST` and `DIRECTX3`. Choose a separate destination folder.
4. Double-click `NFSSE.exe` in the destination. Move that complete folder to relocate the installation.

The installer uses Windows PowerShell and the .NET Framework included with Windows. Players do not need Python, Visual Studio, a system-wide DirectX installation or administrator privileges. Keep the destination writable for settings, saves and the runtime log. Approximately 520 MB is required for the copied game data.

This release supports one verified English media executable: 1,069,056 bytes, SHA-256 `ac72e59587b66f9a3bb2bdb83fa40b8eaac2d68a5ae47a041b026922f8d2594b`. The installer rejects other builds. The patch kit contains the new compatibility helper and the licensed cnc-ddraw renderer; users supply the original game, icon and legacy support DLLs from their own media.

## Included changes

- Borderless display scaling preserves each original mode's proportions and leaves the desktop resolution unchanged. Gameplay retains its original internal resolution.
- Executable-relative paths and locally copied assets allow play without the physical CD.
- Startup fixes cover legacy memory reporting, VGA scratch pointers, privileged instructions and graphics initialization timing.
- Legacy DirectPlay providers load from the game folder.
- Buffered file reads, synchronized video presentation and periodic redraws address the observed video and menu failures.
- The original `NFSICONN.ICO` is embedded in the generated `NFSSE.exe`.
- Original I-Force code and `IFORCE.DLL` are retained. Modern USB device support is deferred; see the [backlog](docs/BACKLOG.md).

Videos, menu clicks, attract mode and relocation were accepted during the development session on Windows 11. A complete manual race, save/reload cycle, multiplayer and modern force-feedback hardware remain unverified. Read the [validation record](docs/VALIDATION.md) before interpreting this as broad compatibility certification.

## Project contents

| Location | Contents |
| --- | --- |
| `src/` | Active 32-bit compatibility helper source |
| `Install-NFSSE.ps1`, `config/` | Media-validated installer, patch recipe, relative paths and graphics defaults |
| `tools/` | Build, release packaging, PE icon embedding and executable analysis |
| `research/` | Static analysis, diagnostic variants, selected logs and measured validation results |
| `docs/` | User guide, build guide, technical notes, session history, validation and backlog |
| `licenses/` | Redistributed renderer's MIT license |

Start with [Building](docs/BUILDING.md) for development, [Technical notes](docs/TECHNICAL_NOTES.md) for patch details, and [Session history](docs/SESSION_HISTORY.md) for the investigation. [Third-party components](docs/THIRD_PARTY.md) lists provenance and redistribution boundaries.

The new code and documentation are MIT-licensed. The original game remains subject to its original ownership and licensing. This is an independent preservation project, unaffiliated with Electronic Arts.
