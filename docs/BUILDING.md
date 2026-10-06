# Building and packaging

## Compatibility helper

Install Visual Studio C++ Build Tools with MSVC x86/x64 tools and a Windows SDK. From the repository root:

```cmd
tools\build-runtime.cmd
```

The script finds Visual Studio with `vswhere`, selects the **x86** environment and creates `build/NFSPortable.dll`. It uses `/MT` to link the C runtime statically. The game and all loaded DLLs are 32-bit; a 64-bit helper cannot be used. `src/NFSPortable.def` exports the startup function by its expected name.

Run `tools\test-input.cmd` for media-independent focus/Enter/Alt+F4, game-class icon assignment, window-height policy, renderer-layout and configuration migration checks. These use a fake game dispatcher, thread-local keyboard state and a hash-verified cnc-ddraw DLL mapped without initialization. The renderer test downloads the pinned archive into `build/window-test-renderer` if absent; it does not require game media. No game, renderer initialization or desktop keyboard input occurs. CI runs these checks too. In-game display and input acceptance remains a separate user check.

The GitHub Actions workflow builds the helper on Windows and checks PowerShell parsing and C# icon-tool compilation. It does not contain game media and cannot prove game behavior or run the complete media-dependent installation.

## Patch-kit release

After building, run in Windows PowerShell:

```powershell
.\tools\package-release.ps1 -Version 0.1.4
```

This downloads the exact [cnc-ddraw 7.1.0.0 archive](https://github.com/FunkyFr3sh/cnc-ddraw/releases/tag/v7.1.0.0), checks its hash and the renderer DLL hash, then creates the kit ZIP and `SHA256SUMS.txt` under `build/releases`. A fresh output root is required for repeated packaging; it will not overwrite an existing staging directory.

For an existing archive or an explicitly selected helper:

```powershell
.\tools\package-release.ps1 -Version 0.1.4 -RuntimeDll "C:\Builds\NFSPortable.dll" -CncArchive "C:\Downloads\cnc-ddraw.zip" -OutputRoot "C:\Builds\NFSSE-release"
```

The published v0.1.0 and v0.1.1 kits use the same helper binary accepted during the session. The v0.1.2 prerelease adds focus/shortcut fixes; v0.1.3 adds the window border and height-based sizing. The user accepted the v0.1.3 window-presentation visual task. v0.1.4 binds the embedded original icon to the game window class; its visible icon result remains pending. Rebuilding the same source with another compiler or timestamp may produce a different DLL hash; compilation alone does not validate its gameplay behavior. The kit manifest records whichever helper is packaged. The original game executable is generated only by the installer from the user's verified media.

Pinned input hashes:

| Input | SHA-256 |
| --- | --- |
| cnc-ddraw archive | `0b13ab89a64c9918189b1dadd449ef6ed3cb3b7b19cabd96d8adbd95505bb908` |
| cnc-ddraw DLL | `85e0f7d530dfda134793a57cb3e76b0287dcc96892ee57162dd68f47283b03a9` |
| Previously accepted v0.1.0/v0.1.1 helper DLL | `04db8cdb915baec95e9db51ad8a30370cbc8e58bcb48707154a4341e9574a29e` |
| v0.1.2 prerelease helper DLL | `ab8be11d0d3278a6c5aa098bfb5f9201caf260d43894c304950c671a69647326` |
| v0.1.3 prerelease helper DLL | `8b0a3556fc84af570e1f9330ab8006a1e9d16890d5c8aebec49350e0ef7c4c19` |
| v0.1.4 prerelease helper DLL | `32f777353b2637997a4ccb869e2359a73845aac5bc30d02ac6dd2c050d905a61` |
| Generated game executable including icon | `a962a27077a31748f860160dc84699cc46fe03b2c3d04287d07a0c88479c9ddd` |

## Media-dependent verification

Extract the resulting kit and run `Install-NFSSE.ps1` with your own supported media and a new destination. Check its generated executable hash against the table, verify the 19 relative path records, and compare copied `FRONTEND`/`SIMDATA` files with your source. Reinstall after adding a test save and changing configuration, then confirm these files survive. See [Validation](VALIDATION.md) for the checks performed for the first release.

Use a separate destination for development. Keep the supported original executable untouched. Runtime acceptance requires checking videos, menu input, gameplay and display behavior after changes to the helper or graphics configuration.

The media-dependent installation checks can be reproduced without launching the game:

```powershell
.\tools\test-installer.ps1 -Kit "C:\Builds\NFSSE-release\NFSSE-v0.1.4-patch-kit" -SourceMedia "C:\Media"
```

This creates a fresh ignored test directory, checks copied asset hashes, exercises reinstall preservation and rejected-input cases, and writes a JSON result. It leaves the test outputs in place for inspection.

## Analysis and icon reference tools

The optional Python tools use `pefile` and `capstone`:

```powershell
python -m pip install pefile capstone
python tools\analyze_nfs_win.py "C:\Media\NFS_WIN.EXE" "build\analysis"
```

Run the analyzer with `--help` for its exact interface. It writes local inventories, cross-references and disassembly from your media. `tools/icon_resources.py` is the Python reference implementation of icon embedding; `tools/IconResources.cs` provides the same operation to the installer using Windows' built-in compiler. Neither tool requires changing the original icon pixels.

The checked-in recipe contains expected/replacement bytes, a new bootstrap section and path strings. Its expected final hash prevents accidental distribution of a different patch. Update the recipe, hash expectations, technical notes and validation together if a new source build is added.
