# Technical notes

## Supported image and disk patches

The original is a Watcom-built PE32 x86 image, preferred base `0x400000`, timestamp `0x31C4F35C`, entry RVA `0x8C802`. Its five sections have zero `VirtualSize` fields. The `.bss` section has no file-backed data; PE tooling must not treat its in-memory size as bytes present in the executable. The initial analysis is preserved in [research/static](../research/static/).

`config/patch-recipe.json` validates the entire original executable by SHA-256 and each overwrite by expected bytes. The two original-code disk edits are:

| File offset | Original bytes | Replacement | Purpose |
| --- | --- | --- | --- |
| `0x29825` | `66 83 3D 1E B3 52 00 00` | `E9 4C 00 00 00 90 90 90` | Skip the physical-CD path gates after installing local data |
| `0x3F68C` | `66 83 3D CC 5C 4C 00 00` | `E9 B8 00 00 00 90 90 90` | Skip the CD-dependent `By_R&T` write/car sabotage block |

A sixth `.nfspat` executable section at RVA `0x141000`, file offset `0x105000`, contains a 267-byte bootstrap padded to 512 bytes. The bootstrap preserves flags/registers, locates the image base, loads `NFSPortable.dll`, resolves `Initialize`, and jumps to the original entry point on success. Failure displays a specific message and exits. Relevant PE header fields are updated explicitly, with a zero checksum.

The icon builder appends a seventh `.rsrc` section at RVA `0x142000`, file offset `0x105200`, with 924 resource bytes padded to 1,024. It installs neutral-language `RT_ICON` image 1 and `RT_GROUP_ICON` group 1. The original 32×32, 16-color icon's DIB payload is unchanged. Missing directory plane/bit metadata is taken from the DIB header. Existing section contents remain byte-identical after icon insertion. The generated file is 1,070,592 bytes, image size `0x143000`.

## Runtime initialization

`src/NFSPortable.cpp` applies narrowly checked runtime edits to the supported executable and matching support DLLs. Important operations are:

| Operation | Verified location or behavior |
| --- | --- |
| Working directory | `GetModuleFileNameW` root followed by `SetCurrentDirectoryW` |
| Memory reporting | `GlobalMemoryStatus` IAT RVA `0x13135C`; cap legacy signed 32-bit comparisons |
| Initial window | IAT RVA `0x1311A0`, bounded initial size 640×480; fix 10,000-pixel initialization pushes at `0x7787D`/`0x77882`; v0.1.5 supplies `The Need for Speed: Special Edition` as the game caption |
| Window input | `RegisterClassA` IAT RVA `0x1311E0`; wrap only `EACLibWindow` with its verified dispatcher at RVA `0x9BB7C` |
| Window icon | Assign original embedded `RT_GROUP_ICON` 1 to the supported class using `LoadIconW` from the game module |
| VGA/debug scratch | Five verified `0xB0000`/`0xB00A0` references redirected to a private 64 KB allocation; similar physics constants remain intact |
| Privileged instructions | `CLI; RET; STI; RET` at RVA `0x8ED2A` becomes `NOP; RET; NOP; RET` |
| File reads | `CreateFileA` hooks remove `FILE_FLAG_NO_BUFFERING` for ordinary existing files while retaining overlapped behavior; `ReadFile` logs failures |
| Graphics initialization | Calls at `0x9C19A`, `0x9BDE0`, `0x9C1F7` synchronize the worker's graphics completion with the main thread using an event |
| DirectPlay | Validate original `DPLAY.dll` timestamp `0x31A17FF9`; redirect provider load call RVA `0x11E9` to executable-folder DLL paths |
| Movie presentation | Calls `0x42473` and `0x424A1` acquire/release the verified cnc-ddraw presentation critical section around frame/palette update |
| Window presentation | Query the current primary desktop with unhooked `EnumDisplaySettingsW`; enable the pinned renderer's border and select fixed 1280×960 client dimensions only for desktop height >960 |

The DirectPlay provider hook intercepts the call itself because a graphics wrapper can rebind imported `LoadLibraryA` slots. Recognized local providers are `dpwsock.dll`, `dpserial.dll`, `dpwsockx.dll` and `dpmodemx.dll`. These DLLs and their core DirectPlay companions are obtained from the user's media; system folders are not modified.

The graphics synchronization uses private internals of the exact bundled cnc-ddraw DLL: timestamp `0x676FAADF`, image size `0x6C000`, `InitializeCriticalSection` argument at `0x694A`, and critical section RVA `0x5F190`. These are verified before use. **This is a build-specific dependency**, not a stable upstream API. A different renderer build needs fresh analysis and runtime validation.

## Focus recovery and window shortcuts

The v0.1.2 prerelease wraps the game class procedure when it is registered. cnc-ddraw subsequently wraps that procedure, preserving its original display, mouse and Alt+Enter handling. No game code or renderer offsets are changed for this hook. A different class dispatcher is rejected.

The original keyboard-down handler at VA `0x49B954` sets a byte in the 128-entry scan-code table at `0x4C693C`; its key-up handler at `0x49BA1C` clears the corresponding byte. Both ordinary and system key messages use these handlers. Focus changes do not release those entries, so a key released outside the game can remain pressed. On `WM_KILLFOCUS` and `WM_SETFOCUS`, the helper calls the original procedure with release messages for scan codes 1–127, then clears high pressed-state bits in that window thread's keyboard state while retaining low toggle bits. It does not edit the table directly or send global keyboard input. This addresses a source-supported failure mechanism; the reported in-game Enter symptom still requires user confirmation.

The original handler consumes `WM_SYSKEYDOWN`, preventing the normal conversion of Alt+F4 to a close command. The helper catches F4 with the Alt context bit and calls `ExitProcess(0)`, matching the bundled renderer's default `SC_CLOSE` path. This is an immediate close; use the game's normal quit flow when saving progress is required. Ordinary F4 and normal Enter/character messages continue to the original dispatcher.

The older local configuration omitted `toggle_borderless=true`, which the renderer requires to leave its borderless fullscreen state through Alt+Enter. The installer adds missing `toggle_borderless` and `adjmouse` keys only to the global `[ddraw]` section. From v0.1.3 it also enables `border=true`, replacing the earlier borderless-window value. It preserves other explicit settings, comments and other sections, saves the original bytes as `ddraw.ini.before-input-update.bak` (with a numeric suffix if necessary), and is idempotent. It retains existing line endings and encoding, including ANSI comments and supported BOM encodings.

## Movable window and desktop-height sizing

The user reported that the v0.1.2 window lacked a border and could not be moved. The shipped `border=false` setting accounts for the missing title bar: upstream [dd_SetDisplayMode](https://github.com/FunkyFr3sh/cnc-ddraw/blob/v7.1.0.0/src/dd.c) strips the caption when disabled and adds `WS_OVERLAPPEDWINDOW` when enabled. Fullscreen presentation explicitly suppresses the border, so enabling it preserves borderless startup. Upstream sizes the client first, then calls `AdjustWindowRectEx` to add the title bar and frame.

The v0.1.3 helper reads the primary display's actual pixel height with `EnumDisplaySettingsW(NULL, ENUM_CURRENT_SETTINGS, ...)`. The bundled renderer hooks the ANSI query and `GetSystemMetrics`, but leaves the Unicode query intact. The check is strictly **height >960**; no width or 720-pixel cutoff is used. Above that threshold, the helper sets `g_config.window_rect.right/bottom` to 1280/960 and `resizable=false`. At or below it, existing width/height/resizable settings remain. The border is enabled in either case. Only presentation changes; the game's original rendering modes, video proportions and mouse scaling remain under cnc-ddraw's existing code.

The renderer reads configuration in [DllMain](https://github.com/FunkyFr3sh/cnc-ddraw/blob/v7.1.0.0/src/dllmain.c), before the executable bootstrap loads the helper. Consequently, writing the INI at that point would be too late. The policy instead updates the already-loaded settings before any game window or rendering thread starts. It does not persist these runtime overrides to the INI. This uses private fields of the pinned build, guarded by PE signature/machine/timestamp/image size, the configuration key strings, the relocated `MOV ECX` key references, the calls to `cfg_get_int`/`cfg_get_bool`, and the relocated `MOV [address], EAX` stores in [cfg_load](https://github.com/FunkyFr3sh/cnc-ddraw/blob/v7.1.0.0/src/config.c). All checks run before any settings are changed; mismatches reject initialization.

| Setting | Field RVA | Key-load RVA | Store RVA |
| --- | --- | --- | --- |
| Width | `0x58B88` | `0x1E0B7` | `0x1E0C3` |
| Height | `0x58B8C` | `0x1E0C8` | `0x1E0D4` |
| Border | `0x596FC` | `0x1E295` | `0x1E2A4` |
| Resizable | `0x59704` | `0x1E2BD` | `0x1E2CC` |

Regression checks map the hash-verified renderer using `DONT_RESOLVE_DLL_REFERENCES`, so its imports, DllMain, hooks and render loop do not execute. They exercise the production verifier and policy at 0, 720, 768, 959, 960, 961, 1080 and 1600 pixels, compare all mapped bytes outside the four fields, and reject a deliberately changed store operand before any writes. These checks establish the layout and height policy; title-bar dragging, mouse clicks and visible client dimensions still require user confirmation.

The user subsequently confirmed the v0.1.3 window-presentation visual task passed. That report and the separately reported title-bar icon issue are recorded in [Validation](VALIDATION.md).

## Title-bar icon

The original registration at VA `0x49BF82` calls `LoadIconA` with the game module and resource ID `0x7F00` (32512), then stores the result in `WNDCLASSA.hIcon` at `0x49BF8F`. The portable executable contains the original media icon as group 1, with no group 32512. The failed legacy lookup leaves the class without an icon, causing Windows to supply its generic icon, as described by the [WNDCLASS documentation](https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-wndclassa).

The v0.1.4 registration hook loads group 1 from the game module with `LoadIconW` and sets the copied class description's `hIcon` before registration. This is a shared resource icon with process lifetime; the caller's class structure is untouched. Missing resources fail registration with the loader's error rather than silently reverting to a generic icon. No icon pixels, resource IDs, executable bytes, window sizing or renderer hooks are changed. The existing class icon supplies the window caption through Windows' normal icon selection/scaling.

Native checks cover the production class assignment and resource/module selection with a fake loader; a separate resource-only mapping exercises the actual Windows icon lookup against the unchanged game executable. Neither creates a window or launches the game. The user subsequently confirmed the original icon and full window title visually with v0.1.5; see the separate user-acceptance record in [Validation](VALIDATION.md).

## Window title

The v0.1.5 caption change is confined to the existing `CreateWindowExA` hook: only class `EACLibWindow` receives `The Need for Speed: Special Edition` as its title. Other classes retain the original title argument. The game strings and executable bytes are not patched, and the icon and presentation hooks are unchanged.

## Relative data paths

The installer writes 19 null-padded, 80-byte ASCII records to `GAMEDATA/CONFIG/PATHS.DAT` (1,520 bytes). The executable selects its own folder as the process working directory before entering the game, making those relative records independent of shortcut or shell launch directory. Their full list is in the recipe and [path map](../research/static/portable_paths_map.json).

The installer copies original `FRONTEND`, `SIMDATA` and `GAMEDATA` trees into the destination. On reinstall it copies only missing tree files to preserve saves and settings, then refreshes the managed path table and compatibility components. No game-media binary is distributed by this repository or release.

Race speech uses a separate original installation step. The original `INFSW.EXE` copy tables map 11 English files from `FRONTEND/SPEECH` to bare filenames in the destination root. The game's loader at VA `0x4646CC` formats those names with `%s`; menu narration at `0x464788` instead prefixes the speech path. The v0.1.0 portable installer omitted the root copies, leaving the assets present under `FRONTEND/SPEECH` but unavailable to race announcements. From v0.1.1, `race_speech_files` in the recipe supplies the required names, the installer checks their presence before destination writes, and copies missing root clips without overwriting existing ones. The executable's speech triggers and loaders are unchanged.

## Video investigation and selected renderer settings

Video streaming originally encountered zero-byte unbuffered reads. Removing the unbuffered flag fixed the observed illegal-chunk abort. Later stalls occurred during graphics mode transitions; GDI rendering and single-CPU affinity avoided the observed deadlock. Synchronizing palette/frame presentation addressed concurrent access. It did not, by itself, eliminate every reported artifact.

The native EA clip decoder was compared with FFmpeg's `eatgv` decoder: all 333 captured indexed frames matched, and all 333 palettes matched. Inspected movie-to-surface copies also matched their source buffers. This evidence directed the final investigation toward presentation rather than replacing the decoder. `minfps=5` enabled periodic redraws, after which the user accepted both clean video playback and working menu clicks, including a relocated build without capture instrumentation.

`maintas=true` with an empty forced `aspect_ratio` preserves each original mode's proportions. This corrected the previously reported vertical video stretch. The game retains its native renderer, original art and original codecs; FFmpeg was used for comparison only.

## Scope and future work

No I-Force functionality is removed or newly implemented. The installer copies original `IFORCE.DLL`; USB compatibility remains [IFORCE-001](BACKLOG.md). Higher internal resolutions, networking modernization and broad Windows/device coverage are separate future work. Static correctness, compilation and user acceptance are recorded separately in [Validation](VALIDATION.md).
