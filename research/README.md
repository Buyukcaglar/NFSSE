# Research archive

This directory contains the publishable evidence from the patch session. The working media, installed game, raw process dumps, frame/palette payloads, screenshots, full extracted string dumps, third-party executable caches and temporary builds remain local. These are either original-game content, private capture material or reproducible build/download outputs.

| Directory | Meaning |
| --- | --- |
| `static/` | Initial PE/import analysis, selected string references and bounded disassembly excerpts, portable path mapping and the DirectPlay call-site fix |
| `diagnostics/` | Historical helper variants and display/thread probes used to isolate failures |
| `logs/` | Selected runtime logs for redraw, palette/surface and thread-stall investigations |
| `validation/` | Asset identity, display modes, relocation, decoder/palette comparison, icon checks, input regression checks and installer results |
| `session-tools/` | Original local builder, including source for assembling the startup bootstrap; historical layout assumptions are documented |

`static/REPORT.txt` describes the **initial static-analysis stage**. Its statement that the executable had not been launched applies to that stage, and its initial dependency/patch recommendations are superseded by the active sources and [technical notes](../docs/TECHNICAL_NOTES.md). Workspace-specific path prefixes have been removed from the published records.

Diagnostic helper variants are experimental code, not supported runtime alternatives. They include instrumentation and temporary investigations; compile and use the active `src/NFSPortable.cpp` for a release. Comparison result JSON contains counts and differences, without original pixel or palette payloads. Zero differences in a sampled clip does not prove timing/audio or every clip.

The v0.1.2 input records distinguish production helper functions exercised with a fake game dispatcher from the packaged installer's media-dependent checks. Neither launches the game or proves in-game keyboard, display or exit behavior. That confirmation remains open in [Validation](../docs/VALIDATION.md).

The v0.1.3 window records cover the production height/border policy against the exact renderer mapped without imports or DllMain, and a packaged installer upgrade from `border=false`. These establish the guarded field layout, strictly greater-than-960 cutoff and file preservation. They do not run the renderer's display or message loop and do not prove visible window size, dragging or mouse behavior.

`window-user-acceptance.json` records the subsequent direct user confirmation that the v0.1.3 visual task passed. The title-bar icon was reported separately. `titlebar-icon-validation.json` covers the v0.1.4 class assignment and actual Windows resource lookup without a game launch or window creation. The icon's visible result still awaits confirmation; no screenshot or original icon payload is published.

The v0.1.5 window-title records distinguish the source-reviewed exact caption and helper build/regression checks from the packaged installer checks. Neither launches the game or supplies visual acceptance of the new caption.

Use `tools/analyze_nfs_win.py` against your own original executable to regenerate the full local static inventory. The active installer and patch recipe supersede the session's exploratory assembly/copy scripts. Read [Session history](../docs/SESSION_HISTORY.md) for how each observation affected the final implementation and [Validation](../docs/VALIDATION.md) for its limits.
