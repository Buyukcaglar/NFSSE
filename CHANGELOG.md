# Changelog

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
