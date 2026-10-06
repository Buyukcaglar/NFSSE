# Validation record

Release: **v0.1.1**, 2026-10-06. Evidence describes the specific tested media and host; it is not a guarantee for every Windows version, video driver or input device.

## Compilation and static checks

- Active x86 helper source compiles with MSVC, `/MT /O2 /W4 /EHsc`.
- PowerShell installer parses and the C# icon tool compiles with Windows' built-in tooling.
- The reference builder reproduces the exact accepted executable with embedded icon: SHA-256 `a962a27077a31748f860160dc84699cc46fe03b2c3d04287d07a0c88479c9ddd`.
- Windows resource lookup and shell icon extraction find the embedded original icon; its image payload is unchanged.
- All 1,228 compared `FRONTEND` and `SIMDATA` files match original media. Original `IFORCE.DLL` also matches.
- All 11 race announcer clips copied beside `NFSSE.exe` match their original `FRONTEND/SPEECH` files.
- The relative path table contains 19 valid records.
- All 333 indexed frames and palettes of the sampled EA movie match the independent FFmpeg reference. Sampled surface copies show no differing pixels.

Machine-readable records are in [research/validation](https://github.com/Buyukcaglar/NFSSE/tree/main/research/validation). These checks support specific byte/data conclusions; they do not certify all video timing, audio or gameplay.

## Runtime and user acceptance

Development host: Windows 11 IoT Enterprise LTSC x64, build 26100, two 2560×1600 displays at 60 Hz. Display probes before startup and from the relocated run recorded unchanged desktop modes.

The user confirmed these outcomes during the session:

- All observed intro videos play without the earlier stalls.
- Video proportions look correct, without vertical stretching.
- The final redraw configuration resolves the visible block/mixed-frame artifacts.
- Main-menu clicks work and reach Control Central.
- Attract-mode gameplay runs without the reported problems.
- A relocated build without video-capture instrumentation keeps both clean videos and working menus.
- Double-clicking `NFSSE.exe` works directly.

The renderer settings accepted for these observations were GDI, single CPU, maintained mode proportions, locked surfaces and `minfps=5`. The release additionally declares mouse adjustment and borderless toggle configuration explicitly; final Alt+Enter testing did not finish.

## Release installer checks

The installer checks source and output hashes and kit integrity during installation. Tests passed for fresh installation, identity of all 1,228 copied FRONTEND/SIMDATA files and 11 root race speech files, exact generated executable, relative paths, and preservation of existing saves/configuration on reinstall. Reinstall restored missing announcer clips and preserved an existing modified clip. An unrelated nonempty destination, unsupported media, missing required announcer clips and a damaged patch kit were rejected without writing game files. The original executable remained unchanged. Results are recorded in [installer-validation.json](https://github.com/Buyukcaglar/NFSSE/blob/main/research/validation/installer-validation.json). Installation tests do not launch the game or repeat the accepted visual gates.

An installation made with the published v0.1.0 kit was upgraded to v0.1.1. The upgrade added all 11 missing root clips with hashes matching the source and preserved 1,250 existing game and configuration files, including save/settings sentinels, the executable and runtime DLLs. Refreshed documentation and the installation record were excluded from that preservation count. See [race-speech-upgrade-validation.json](https://github.com/Buyukcaglar/NFSSE/blob/main/research/validation/race-speech-upgrade-validation.json). The original installer tables and game loaders establish the missing-copy diagnosis; race voice playback still awaits user verification.

## Outstanding checks

- Complete manual race, save/reload cycle and comprehensive audio/video coverage.
- Exit and Alt+Enter behavior in the final release configuration; the final interactive check was stopped before completion.
- Multiplayer, serial/modem links and contemporary USB I-Force devices.
- Other Windows builds, display drivers, multi-monitor arrangements, ARM emulation and non-English or different media executables.

The original I-Force path is retained, but no force-feedback hardware claim is made. See [Backlog](https://github.com/Buyukcaglar/NFSSE/blob/main/docs/BACKLOG.md).
