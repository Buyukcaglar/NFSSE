# Validation record

Latest full release: **v0.2.0**, 2026-10-06. The user confirmed the local three-language integration with "Everything looks ok" and authorized optional PatchKit integration and publication. The accepted v0.1.5 engine/helper/renderer are retained. Earlier window-presentation, title and icon confirmations remain recorded separately. Automated checks below validate specific files and behavior; collective user confirmation does not establish every frame, audio sample, multiplayer path or Windows host.

## v0.2.0 optional PatchKit checks

The extracted kit passed the standard installer checks and ten optional-language cases in Windows PowerShell 5.1. Checks cover fresh English/German selection, adding Japanese, preserving German selection on reinstall, preserving Japanese without its source folder, disabling to direct English play, and re-enabling the retained Japanese pack. Modified Japanese assets, custom path tables, custom announcers and an unsupported Japanese executable were rejected before destination writes. Shared saves and settings survived.

All 436 installed Japanese outputs are byte-identical to the Python reference builder. All eleven original German root announcers are selected for German; English and Japanese restore the original English recordings. The engine, compatibility helper and renderer retain their accepted hashes. The C# converter passed 33 synthetic reference cases, including malformed inputs and offset/size bounds. Native selection tests also cover unavailable Japanese selection, rollback and session locking. These automated checks launch neither the game nor selector UI.

Records: [standard installer](https://github.com/Buyukcaglar/NFSSE/blob/main/research/validation/patchkit-basic-v0.2.0.json), [optional languages](https://github.com/Buyukcaglar/NFSSE/blob/main/research/validation/patchkit-languages-v0.2.0.json), and [local user acceptance](https://github.com/Buyukcaglar/NFSSE/blob/main/research/validation/language-user-acceptance.json). The release contains our code, resource profiles and cnc-ddraw; original game executables, icons, artwork and audio are generated or copied only from the user's media.

## Compilation and static checks

The local three-language edition builds its native selector without warnings.
Production-function tests cover all three path/config choices, original race
voices, idempotence, configuration/save preservation, rejected custom/damaged
data, English recovery from a damaged German pack, failed-write rollback and
exclusive session locking. Real media-dependent selections passed English →
German → Japanese → German → English without starting the game or selector UI.
All 436 Japanese resource outputs and the original engine/helper/renderer/icon
payloads were verified; all 1,262 base files were preserved, with the original
executable retained as NFSSE-Game.exe. The backed-up updater passed on a separate
installation copy. See `research/validation/language-edition-validation.json`
and the [edition guide](LANGUAGE_EDITION.md). The user reported the Japanese
prototype checks looking OK and subsequently confirmed the local three-language
integration. These results and the new optional installer are included in v0.2.0;
the published v0.1.5 ZIP remains unchanged.

- Active x86 helper source compiles with MSVC, `/MT /O2 /W4 /EHsc`.
- PowerShell installer parses and the C# icon tool compiles with Windows' built-in tooling.
- The reference builder reproduces the exact accepted executable with embedded icon: SHA-256 `a962a27077a31748f860160dc84699cc46fe03b2c3d04287d07a0c88479c9ddd`.
- Windows resource lookup and shell icon extraction find the embedded original icon; its image payload is unchanged.
- All 1,228 compared `FRONTEND` and `SIMDATA` files match original media. Original `IFORCE.DLL` also matches.
- All 11 race announcer clips copied beside `NFSSE.exe` match their original `FRONTEND/SPEECH` files.
- The relative path table contains 19 valid records.
- All 333 indexed frames and palettes of the sampled EA movie match the independent FFmpeg reference. Sampled surface copies show no differing pixels.

Machine-readable records are in [research/validation](https://github.com/Buyukcaglar/NFSSE/tree/main/research/validation). These checks support specific byte/data conclusions; they do not certify all video timing, audio or gameplay.

## v0.1.2 prerelease checks

The updated x86 helper builds with MSVC without warnings. Native regression checks exercise its actual class-registration and window-procedure functions with a fake game dispatcher: missing releases are recovered on focus loss and gain, normal Enter/character/release messages pass through, lock-key toggle bits survive, unrelated classes remain untouched, unexpected game dispatchers are rejected, and an Alt+F4 test process exits with code 0. These checks do not load the game or renderer and do not prove the reported in-game symptom resolved.

Configuration checks passed for legacy global-section migration, preservation of explicit values and other game sections, exact backups, repeated upgrades, ANSI comments, and UTF-8/UTF-16 BOM files. The packaged installer passed fresh installation, the existing preservation/rejection checks, an actual legacy display-config upgrade with backup, and idempotent reinstall. See [input-shortcut-validation.json](https://github.com/Buyukcaglar/NFSSE/blob/main/research/validation/input-shortcut-validation.json) and [input-installer-validation.json](https://github.com/Buyukcaglar/NFSSE/blob/main/research/validation/input-installer-validation.json). The game executable, original assets and bundled renderer retain their previous hashes. No v0.1.2 game launch or visual check was performed.

## v0.1.3 window presentation checks

The helper builds without MSVC warnings, and the earlier focus/Enter/Alt+F4 tests still pass. Window tests map the exact hash-verified cnc-ddraw binary without resolving imports or running DllMain. The production configuration verifier and policy pass for desktop heights 0, 720, 768, 959, 960, 961, 1080 and 1600: the border is always enabled; only heights greater than 960 select 1280×960 and disable resizing; lower heights retain configured size/resizability. All renderer bytes outside those four settings remain unchanged, including fullscreen state. A changed configuration-store operand is rejected before writes. No game, renderer initialization, rendering loop, display-mode change or desktop input is involved.

Configuration checks cover replacement of global `border=false` with `border=true`, missing border/toggle/mouse keys, inline comments, exact backups, other-section and preference preservation, repeated upgrades and encoding. The packaged installer passes fresh installation, legacy-border upgrade, idempotence and existing preservation/rejection cases. See [window-presentation-validation.json](https://github.com/Buyukcaglar/NFSSE/blob/main/research/validation/window-presentation-validation.json) and [window-installer-validation.json](https://github.com/Buyukcaglar/NFSSE/blob/main/research/validation/window-installer-validation.json). No game launch or automated visual check was performed for this change.

The user reported a missing border and inability to move the v0.1.2 window. After the v0.1.3 update, they stated that visual confirmation for the task passed, with the missing title-bar application icon reported separately. This accepts the window-presentation visual task on the observed setup. The existing local runtime log records desktop height 1600 and a 1280×960 client area. It does not add separate user coverage for smaller desktops, other hosts, nonvisual keyboard/exit behavior or a complete race. See [window-user-acceptance.json](https://github.com/Buyukcaglar/NFSSE/blob/main/research/validation/window-user-acceptance.json). The supplied screenshot remains local.

## v0.1.4 title-bar icon checks

The helper compiles without warnings, and the existing focus, shortcut, window-policy and configuration tests pass. The production registration hook is exercised with a fake icon loader and registrar: it loads group 1 from the game module, assigns that handle to the game class, preserves the caller-owned class structure and unrelated classes, and rejects a missing icon. A separate Windows resource-only mapping confirms `LoadIconW` loads the original embedded group 1 and cannot load the legacy request for group 32512. The game executable, original icon and renderer hashes are unchanged. See [titlebar-icon-validation.json](https://github.com/Buyukcaglar/NFSSE/blob/main/research/validation/titlebar-icon-validation.json).

No game launch or automated visual check was performed during the icon-fix checks. The user subsequently confirmed the original icon visually with v0.1.5, as recorded below. The earlier window-presentation acceptance remains recorded separately.

## v0.1.5 window-title checks

The x86 helper compiles without warnings and the existing input, icon-registration, renderer-policy and configuration checks pass. Source review confirms the exact requested caption, `The Need for Speed: Special Edition`, is substituted only for the supported `EACLibWindow` class before calling the existing window-creation function. Other title arguments pass through. The packaged installer passes its installation, preservation and rejection checks with the updated helper. See [window-title-validation.json](https://github.com/Buyukcaglar/NFSSE/blob/main/research/validation/window-title-validation.json) and [window-title-installer-validation.json](https://github.com/Buyukcaglar/NFSSE/blob/main/research/validation/window-title-installer-validation.json).

No automated game launch or visual check was performed for the caption change. After installing helper version 7, the user stated “Visually confirmed” for the current title/icon task. The local runtime log identifies helper version 7, matching the installed v0.1.5 helper hash. This accepts the full window title and original title-bar icon on the observed setup. See [window-title-user-acceptance.json](https://github.com/Buyukcaglar/NFSSE/blob/main/research/validation/window-title-user-acceptance.json). The accepted v0.1.3 window-presentation task remains accepted; no broader gameplay, input/exit or host coverage is inferred.

## Earlier accepted runtime observations

Development host: Windows 11 IoT Enterprise LTSC x64, build 26100, two 2560×1600 displays at 60 Hz. Display probes before startup and from the relocated run recorded unchanged desktop modes.

The user confirmed these outcomes during the session:

- All observed intro videos play without the earlier stalls.
- Video proportions look correct, without vertical stretching.
- The final redraw configuration resolves the visible block/mixed-frame artifacts.
- Main-menu clicks work and reach Control Central.
- Attract-mode gameplay runs without the reported problems.
- A relocated build without video-capture instrumentation keeps both clean videos and working menus.
- Double-clicking `NFSSE.exe` works directly.

The renderer settings accepted for these earlier observations were GDI, single CPU, maintained mode proportions, locked surfaces and `minfps=5`. The later v0.1.3 window-presentation visual acceptance is recorded above; it does not replace the earlier evidence or infer broader input/device coverage.

## Release installer checks

The installer checks source and output hashes and kit integrity during installation. Tests passed for fresh installation, identity of all 1,228 copied FRONTEND/SIMDATA files and 11 root race speech files, exact generated executable, relative paths, and preservation of existing saves/configuration on reinstall. Reinstall restored missing announcer clips and preserved an existing modified clip. An unrelated nonempty destination, unsupported media, missing required announcer clips and a damaged patch kit were rejected without writing game files. The original executable remained unchanged. Results are recorded in [installer-validation.json](https://github.com/Buyukcaglar/NFSSE/blob/main/research/validation/installer-validation.json). Installation tests do not launch the game or repeat the accepted visual gates.

An installation made with the published v0.1.0 kit was upgraded to v0.1.1. The upgrade added all 11 missing root clips with hashes matching the source and preserved 1,250 existing game and configuration files, including save/settings sentinels, the executable and runtime DLLs. Refreshed documentation and the installation record were excluded from that preservation count. See [race-speech-upgrade-validation.json](https://github.com/Buyukcaglar/NFSSE/blob/main/research/validation/race-speech-upgrade-validation.json). The original installer tables and game loaders establish the missing-copy diagnosis; race voice playback still awaits user verification.

## I-Force working report

On 2026-10-06, the user stated that I-Force was reported working and requested no further work on that front. [IFORCE-001](BACKLOG.md) and its GitHub issue are closed with no additional implementation planned. The original I-Force code and copied `IFORCE.DLL` remain unchanged. See [iforce-user-report.json](../research/validation/iforce-user-report.json).

This is a user-supplied working report; no controller model or wrapper configuration was specified, and no independent force-feedback hardware check was performed during this task. I-Force is removed from the active follow-up list.

## Outstanding checks

- Complete manual race, save/reload cycle and comprehensive audio/video coverage.
- Input/exit checks: Enter after repeated Alt+Tab, Alt+F4 from both presentation modes, and unchanged desktop mode after exit. These have automated regression evidence but no separate user confirmation; the window-presentation visual task is already accepted.
- Smaller desktops and broader display-transition/host coverage still require separate runtime checks. The v0.1.3 window-presentation task and v0.1.5 full title/original-icon visual task are accepted on the observed setup.
- Multiplayer and serial/modem links.
- Other Windows builds, display drivers, multi-monitor arrangements, ARM emulation and non-English or different media executables.

See [Backlog](https://github.com/Buyukcaglar/NFSSE/blob/main/docs/BACKLOG.md) for the remaining follow-ups.
