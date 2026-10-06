# Patch-session history

This record summarizes the investigation that produced v0.1.0. Earlier diagnostics and logs are historical experiments; the active implementation is `src/NFSPortable.cpp`.

1. **Media analysis.** The input was confirmed as installation-media content. PE imports and code references identified a 32-bit Windows build and dependencies including the original DirectPlay and I-Force files. The initial launch failed with missing `DPLAY.dll`.
2. **Portable layout.** Needed assets and support DLLs were copied locally. The 19-entry path table was corrected and made relative. A bootstrap/helper established an executable-relative working directory, avoiding reliance on a CMD launch directory.
3. **Modern startup.** Silent startup and helper-initialization failures led to verified fixes for signed memory totals, legacy VGA/debug pointers, privileged interrupt instructions, absurd initial window dimensions and an initialization race between the main and graphics worker threads.
4. **DirectPlay providers.** The game attempted to load `dpserial.dll` from the Windows system directory. Redirecting its verified provider-load call to bundled local DLLs removed that startup dependency without writing to system folders.
5. **Streaming abort.** The reported `streamreader - ILLEGAL CHUNK SIZE 0 BUFFERSIZE 900000` failure was traced through legacy unbuffered file access. Retaining overlapped reads while removing `FILE_FLAG_NO_BUFFERING` corrected the observed failure.
6. **Videos and display transitions.** The user reported corrupted blocks/mixed frames and stalls on the second video, including when videos were smaller. Renderer experiments and thread inspection led to cnc-ddraw GDI rendering with single-CPU affinity. Videos subsequently played without stalling. Automatic per-mode proportions corrected vertical stretching; attract mode was accepted.
7. **Presentation versus decoding.** Palette synchronization alone still left user-visible artifacts. Diagnostic captures compared native decoding with FFmpeg: the sampled 333 EA frames and palettes matched, as did inspected surface copies. Original codecs and artwork were preserved.
8. **Periodic redraws.** Menus initially appeared unresponsive. `minfps=5` enabled periodic presentation; the user confirmed menu clicks working and then clean videos. A relocated run without capture instrumentation retained both outcomes.
9. **Direct launch and icon.** Direct double-click launch was confirmed. The original media icon was embedded using appended PE resources and verified through Windows resource and shell APIs without changing icon pixels.
10. **Public patch kit.** The installation-media executable, assets and original support DLLs remain local inputs. The repository publishes original patch sources, a validated recipe, diagnostic sources, selected analysis/results, documentation and a release installer that generates the accepted executable locally.

Original I-Force support was explicitly retained. Modern USB device support was moved to a low-priority backlog item at the user's request, with no implementation attempted.

Final exit and Alt+Enter interaction checks were interrupted and remain open. Compilation, data comparisons and accepted visual results have distinct evidence boundaries; see [Validation](VALIDATION.md).

On 2026-10-06 the user authorized changes for Enter after Alt+Tab, Alt+Enter window mode and direct Alt+F4 close, followed by a GitHub/documentation update. The v0.1.2 helper wraps the supported game class procedure, releases stale scan-code and thread keyboard states on focus transitions, and handles the close shortcut before the game consumes it. The installer adds missing display-toggle keys with a configuration backup. Native regression and installer checks passed, and the local game was updated with backups. v0.1.2 is published as a prerelease while in-game confirmation remains pending; v0.1.1 remains the latest stable release.
