# NFSSE user guide

This guide covers [v0.2.0, the latest full release](https://github.com/Buyukcaglar/NFSSE/releases/tag/v0.2.0). It adds optional English/German/Japanese language selection while retaining the accepted v0.1.5 compatibility runtime, window title and original icon. The user confirmed that the local three-language integration looks OK; automated installer checks are recorded separately.

For the optional English/German/Japanese flag selector, use the
[three-language edition guide](LANGUAGE_EDITION.md). Its NFSSE.exe opens the
language window, then starts the unchanged accepted engine as NFSSE-Game.exe.

## Optional languages

The standard installation starts directly in English. During interactive installation, choose the optional language selector to show English, German and Japanese flags before the game starts. English and German resources come from the supported English Special Edition media. To enable Japanese, also supply the supported Japanese media folder. Without that folder, the Japanese flag is disabled and marked "Not installed".

For unattended installation, add `-LanguageSelector` for English/German selection, or `-JapaneseMedia "C:\Media\Japanese"` to install Japanese and enable the selector. Add `-DisableLanguageSelector` to return an existing installation to direct English play. See the [language guide](LANGUAGE_EDITION.md) for complete commands and the original language/voice behavior.

Reinstalling preserves an enabled selector, the selected language, installed Japanese resources, saves and settings. Japanese media is not needed again unless its pack must be rebuilt. Disabling the selector retains that pack for later reuse. Managed language changes are backed up under the destination's `.patch-backups` folder. Installation uses only Windows' built-in tools; normal play needs neither PowerShell nor source media.

## Requirements

- Modern Windows capable of running 32-bit desktop applications. The development host was Windows 11 IoT Enterprise LTSC, x64, build 26100. Other Windows editions and ARM emulation have not been exercised.
- Your own supported English Special Edition installation media, extracted to a folder or accessible from a mounted disc.
- About 520 MB of writable destination space for the standard installation, plus space for optional Japanese resources and update backups.
- The complete release patch-kit ZIP, extracted before installation.

The supported original `NFS_WIN.EXE` has size **1,069,056 bytes** and SHA-256:

```text
ac72e59587b66f9a3bb2bdb83fa40b8eaac2d68a5ae47a041b026922f8d2594b
```

The media folder must contain `NFS_WIN.EXE`, `NFSICONN.ICO`, `IFORCE.DLL`, `FRONTEND`, `SIMDATA`, `GAMEDATA`, `REDIST/DIRECTX` and `DIRECTX3/DIRECTX`. The installer copies the needed DirectPlay files from those last two folders. Other base executables, modified executables and the DOS executable are not supported by this recipe. The optional Japanese pack uses separately verified Japanese media; it still runs the supported patched Windows engine.

## Installation

1. Download `NFSSE-v0.2.0-patch-kit.zip` from the [latest release](https://github.com/Buyukcaglar/NFSSE/releases/latest) and extract it to a folder.
2. Double-click `Install-NFSSE.cmd` inside the extracted kit. A console asks for the media folder and destination folder.
3. Enter the folder directly containing `NFS_WIN.EXE`. Choose a new destination outside the media folder, such as `C:\Games\NFSSE`.
4. Choose whether to enable the language selector; supply Japanese media if desired. Wait for the verified game data to be written, then close the installer after its success message.
5. Open the destination and double-click `NFSSE.exe`.

Python and Visual Studio are unnecessary for the release installer. It uses Windows PowerShell and its built-in C# compiler. It writes the chosen destination without changing the source media, installing services, registering DLLs, modifying the registry or enabling the Windows legacy DirectPlay feature.

For unattended installation, run this from the extracted kit in Windows PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install-NFSSE.ps1 -SourceMedia "D:\NFSSE-Media" -Destination "C:\Games\NFSSE" -NonInteractive
```

`SourceMedia` may also point to a mounted disc root. The installer validates the media executable, media icon, patch-kit file hashes and generated executable before copying game data. An unsupported build is rejected before destination files are written.

## Playing and moving the game

Launch `NFSSE.exe` directly. `Run-NFS.cmd` is an optional convenience: the executable's compatibility helper establishes its own working directory, so a desktop shortcut and double-click launch use the same executable-relative paths.

Once installed, all game assets and required legacy DLLs are local. The physical CD and source-media folder are no longer needed for normal play. To move the game, close it and move the **whole destination folder**, including `FRONTEND`, `SIMDATA`, `GAMEDATA`, `NFSPortable.dll`, `ddraw.dll`, the DirectPlay DLLs and configuration files. Keep it on a writable drive; saves and settings live in that folder.

Back up the entire `GAMEDATA` folder and root `nfs.cfg` before moving or reinstalling. To uninstall, close the game and remove the destination after preserving saves. No system-wide component needs uninstalling.

## Display and video

The default configuration scales the game's original image to a borderless fullscreen window while retaining the desktop mode. Gameplay uses its original 640×480 image with 4:3 proportions. Videos retain the proportions of their original mode, including 320×200 clips. Black margins are expected when the image and monitor proportions differ. This release does not add higher internal rendering resolutions or replace the original artwork or video decoder.

The tested combination in `ddraw.ini` is GDI rendering, `singlecpu=true`, `maintas=true`, an empty `aspect_ratio`, `minfps=5`, and `lock_surfaces=true`. Periodic redraws are needed for the observed menu and movie presentation problems. Keep these defaults when reporting a regression.

Alt+Enter switches between a bordered window and borderless fullscreen. Drag the title bar to move the window. Above a primary desktop height of **960 pixels**, the game area is fixed at **1280×960**, twice the 640×480 gameplay image. The title bar and border add to those dimensions. At exactly 960 pixels or below, the configured window size is retained (original mode size by default). Desktop width is not part of the check; the helper reads the current resolution at each launch. Resizing and maximizing are disabled for the fixed-size window; moving it remains available.

The defaults set `border=true`, `toggle_borderless=true` and `adjmouse=true`. The installer enables the border in older configurations and adds missing toggle/mouse keys. The helper applies the launch sizing policy in memory without rewriting the file. Borderless startup still fills the desktop and preserves each original mode's proportions. The user confirmed the v0.1.3 window-presentation visual task passed. Behavior on smaller desktops has separate automated policy checks.

From v0.1.4, the game window uses the original icon already embedded in `NFSSE.exe`, addressing the generic application icon on the title bar. This fix updates the helper; it does not replace the icon artwork or require an external icon file beside the game. The user visually confirmed the original title-bar icon with v0.1.5.

From v0.1.5, the title bar displays `The Need for Speed: Special Edition`. Restart the game after upgrading to apply the new title and icon binding.

The v0.1.2 helper releases stale keyboard states when the window loses or regains focus, addressing Enter becoming unavailable after Alt+Tab. Alt+F4 closes the game immediately. Use the in-game quit flow when you need to save progress normally.

Use the bundled **cnc-ddraw 7.1.0.0 DLL**. The helper synchronizes presentation through a verified location inside that exact build, so replacing `ddraw.dll` with another version requires a corresponding helper update.

## Configuration and reinstall

The installer creates a 19-record relative `GAMEDATA/CONFIG/PATHS.DAT`. Avoid editing it into absolute drive paths: relocation depends on those relative records and the executable setting its working directory.

The initial `nfs.cfg` is:

```powershell
"YESSOUND HIGHVIDEO ENGLISH NOREMOTE `r`n"
```

There is a trailing space before the line ending. Preserve it when editing because the legacy option parser expects token separation.

Running the installer again against a destination it created refreshes managed executable/runtime files and documentation. Enabled language features and the current selection are preserved unless explicitly disabled. Existing game files, saves and configuration settings are preserved; enabling or disabling language selection updates only the language routing and original race-announcer files. For `ddraw.ini`, v0.1.3 sets global `border=true` and adds missing `toggle_borderless` and `adjmouse` keys; your other settings and comments remain. If it changes the file, the original is saved beside it as `ddraw.ini.before-input-update.bak`, with a numeric suffix if that backup already exists. Explicit toggle/mouse values and other game sections are preserved. The helper always enables the window border; on desktops taller than 960 pixels it overrides width, height and resizing in memory for that launch. It refuses an unrelated nonempty destination or an executable with unrecognized modifications. Close the game before reinstalling. To restore graphics defaults, back up your `ddraw.ini`, remove that file, and rerun the installer.

To update a v0.1.0 installation, run the latest installer with the same source media and destination. It adds the 11 missing race announcer clips beside `NFSSE.exe`. Keep these root `.EAS` files when moving the game; race announcements load them directly from the game folder.

To apply the window-title and title-bar icon changes, run the v0.2.0 release installer with the same source media and destination. It includes the earlier announcer, window and keyboard fixes. Relaunch the game to apply the title and icon. The window-presentation visual task is already accepted; keyboard recovery, immediate exit and broader display coverage retain their separate validation checks.

## Troubleshooting

| Symptom | Action |
| --- | --- |
| Unsupported executable or icon | Confirm the selected folder contains unmodified supported English media. Compare its SHA-256; this release has no recipe for other builds. |
| Patch-kit integrity check fails | Extract the complete release ZIP again. Keep its folders together. |
| `DPLAY.dll` missing | Launch from the completed destination, and confirm the media included the required `REDIST` and `DIRECTX3` files. Rerun the installer. |
| Missing “best time”, “final lap” or finishing-position voices | Update with the latest installer. It adds `BESTTIME.EAS`, `BESTLAST.EAS`, `FINALLAP.EAS` and `FIRST.EAS` through `EIGHTH.EAS` beside `NFSSE.exe`. |
| Portable compatibility initialization failed | Keep `NFSPortable.dll`, the bundled `ddraw.dll`, and local DirectPlay DLLs beside `NFSSE.exe`. Read `portable-runtime.log` and report the first failing initialization step. |
| `dpserial.dll` service error | Confirm local `DPSERIAL.DLL` is present. The helper should log a local provider load; restore the matching support files with the installer. |
| `streamreader - ILLEGAL CHUNK SIZE` | Confirm the current helper is installed. Its buffered-read hook addresses the observed zero-byte legacy stream failure. Include the runtime log if it recurs. |
| Stalled video, corrupted presentation or menus ignoring clicks | Restore the default `ddraw.ini`, especially GDI, `singlecpu=true` and `minfps=5`; use the exact bundled renderer. Report which clip or menu failed. |
| Wrong video proportions | Keep `maintas=true` and `aspect_ratio=` empty so each original mode determines its proportions. |
| Windowed mode has no title bar or cannot be moved | Use the latest helper and installer, then drag the title bar after Alt+Enter. If the game captures the cursor, use Alt+Tab to switch away and back, or the renderer's Ctrl+Tab cursor-unlock shortcut. |
| Title bar shows a generic application icon | Use the latest helper, which assigns the original embedded icon to the window class. Restart the game after updating. |
| Window is smaller than 1280×960 | The fixed size applies only when the primary desktop's current height is greater than 960 pixels. Relaunch after changing desktop resolution and check the `Window presentation` entry in `portable-runtime.log`. |
| Alt+Enter does nothing in an older installation | Use the latest installer to add missing toggle settings, or set `toggle_borderless=true` in `[ddraw]`. An explicit custom hotkey or game-specific override can change the shortcut. |
| Enter stops working after Alt+Tab | Use the latest helper, which resets stale keyboard states on focus transitions. Report whether the issue remains after switching away and back several times. |
| Settings or saves do not persist | Use a writable destination outside protected system folders and close the game before backing up files. |

Open a [bug report](https://github.com/Buyukcaglar/NFSSE/issues/new/choose) with release version, Windows version, display setup, reproduction steps and `portable-runtime.log`. Review logs for personal folder names before attaching them. Do not attach original game files, video captures containing game assets or full process memory dumps.

## I-Force and multiplayer

Original I-Force code and `IFORCE.DLL` are preserved. The user reports I-Force working and requested no further work on it; the related backlog item is closed. The report does not specify the controller or wrapper configuration. Legacy multiplayer providers are made available locally for startup compatibility; network play, serial play and modem play have not been validated.
