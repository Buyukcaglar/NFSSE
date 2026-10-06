# Changelog

## 0.1.3 — Prerelease, 2026-10-06

- Give the Alt+Enter window a standard Windows title bar and border so it can be dragged. Older `border=false` configurations are upgraded with an exact backup; other settings and game sections are preserved.
- At each launch, read the primary desktop's current pixel height. Above 960 pixels, use a fixed 1280×960 window client area (2× the 640×480 gameplay image); at 960 or below, retain the configured smaller size. Desktop width does not affect this decision. Borderless fullscreen startup and original mode proportions remain unchanged.
- Apply the policy to verified settings in the exact bundled cnc-ddraw build before window initialization. No game executable, assets or renderer binary changes are needed, and the runtime policy does not rewrite `ddraw.ini`.
- Add cutoff and renderer-layout regression checks. Window dragging, size, mouse selection and display transitions await in-game confirmation.

## 0.1.2 — Prerelease, 2026-10-06

- Release stale game scan-code states and window-thread pressed-key states on focus loss/gain, addressing Enter becoming unavailable after Alt+Tab. Keyboard toggle settings are retained and no desktop-wide input is synthesized.
- Handle Alt+F4 before the original game consumes the system-key message, matching cnc-ddraw's immediate process-close behavior.
- Add missing Alt+Enter borderless-toggle and mouse-adjustment settings to older installations, with an exact configuration backup. Explicit settings, other game sections, saves and game data are preserved.
- Add regression checks for focus recovery, normal Enter, Alt+F4, and configuration migration. In-game keyboard, display and exit acceptance remains pending.

## 0.1.1 — 2026-10-06

- Fix missing race announcements by copying the 11 original announcer clips from `FRONTEND/SPEECH` beside `NFSSE.exe`, matching the original Windows installer.
- Reinstall adds missing announcer clips while preserving existing game files, saves and settings. Missing source clips are rejected before any destination write.
- Add installer checks for the root announcer clips, repair on reinstall, preservation and missing-media rejection. The game executable and compatibility helper are unchanged.
- In-race voice playback remains pending user verification; this release validates installation and file identity.

## 0.1.0 — 2026-10-05

- Initial public compatibility patch kit for the verified English Windows Special Edition media.
- Executable-relative portable installation with local assets and support DLLs; physical CD no longer required after installation.
- Borderless scaling without desktop resolution changes, preserving original mode proportions.
- Verified modern-startup fixes, local DirectPlay provider loading and buffered stream reads.
- Synchronized video presentation, GDI/single-CPU defaults and periodic redraws for the accepted video/menu behavior.
- Embedded original application icon in the locally generated executable.
- Sources, patch recipe, diagnostics, analysis, validation records, build workflow and user guide.
- Original I-Force retained; modern USB support deferred as IFORCE-001.

See [Validation](docs/VALIDATION.md) for exercised behavior and outstanding checks.
