# Changelog

## 0.2.1 — Japanese graphics-menu stability, 2026-10-06

- Replace literal-only RefPack encoding with bounded backreference compression.
  The old 507,348-byte Japanese graphics file exceeded the original loader's
  503,876-byte allocation and corrupted its memory sentinel. Both graphics
  contexts retain byte-identical decoded archives and original artwork.
- Build the corrected Japanese resources during fresh installation from the
  user's original English and Japanese media. Use a new destination folder.
  The accepted game engine, compatibility helper and renderer are retained.
- Add large-resource, in-place workspace and Windows conversion regressions,
  plus an isolated check using the original game's exact
  decompressor. On 2026-10-06 the user confirmed no crash on Graphics selection.

## 0.2.0 — Optional language editions, 2026-10-06

- Open a native English/German/Japanese flag window from NFSSE.exe and start the
  unchanged accepted engine as NFSSE-Game.exe after selection. Preserve its
  original icon, helper, renderer, shared saves and other settings.
- Select the original German resource paths and engine branch, including all
  eleven distinct German race-announcer recordings. Restore English recordings
  for English/Japanese. Keep original Japanese name/exit dialogs in English.
- Carry forward the source-derived Japanese compatibility resources after the
  user reported the prototype checks looking OK. Add selection/integrity,
  rollback, damaged-pack recovery and backed-up update checks. The native
  selector and German gameplay checks were confirmed looking OK by the user.
- Integrate the selector into the PatchKit as an optional feature. The standard
  English installation stays the default; original English media supplies German,
  and user-supplied Japanese media adds Japanese. Windows PowerShell/.NET builds
  the verified resources without Python or additional player tools.
- Preserve enabled features and selections on reinstall. Explicitly disabling the
  selector backs up language state and restores direct English play. All 436 C#
  Japanese outputs match the reference; basic and optional installer tests pass.

## 0.1.5 — 2026-10-06

- Set the game window title to `The Need for Speed: Special Edition` through the existing window-creation hook. Other window classes retain their supplied captions. The executable, original icon, game data, renderer and accepted window-sizing policy are unchanged.
- Include the earlier title-bar icon fix and record the user's accepted window-presentation visual task. The user visually confirmed the full caption and original icon with v0.1.5; build, existing regression and patch-kit installer checks pass.
- Promote the unchanged patch kit to the latest full release at the user's request. Record I-Force as reported working and close IFORCE-001 with no further implementation planned.

## 0.1.4 — Prerelease, 2026-10-06

- Bind the original embedded icon to the game window class so the title bar uses the game icon. The legacy code requested nonexistent group 32512; the installer embeds the original media icon as group 1. The executable, icon artwork and renderer are unchanged.
- Record the user's successful visual confirmation of v0.1.3's movable window and desktop-height sizing task. The title-bar icon was reported separately and still awaits confirmation of this fix.
- Extend class-registration regression checks to verify the icon resource/module, unchanged unrelated classes and caller-owned structures, and missing-resource rejection. The original embedded icon loads through the Windows resource API without starting the game.

## 0.1.3 — Prerelease, 2026-10-06

- Give the Alt+Enter window a standard Windows title bar and border so it can be dragged. Older `border=false` configurations are upgraded with an exact backup; other settings and game sections are preserved.
- At each launch, read the primary desktop's current pixel height. Above 960 pixels, use a fixed 1280×960 window client area (2× the 640×480 gameplay image); at 960 or below, retain the configured smaller size. Desktop width does not affect this decision. Borderless fullscreen startup and original mode proportions remain unchanged.
- Apply the policy to verified settings in the exact bundled cnc-ddraw build before window initialization. No game executable, assets or renderer binary changes are needed, and the runtime policy does not rewrite `ddraw.ini`.
- Add cutoff and renderer-layout regression checks. The user subsequently confirmed the window-presentation visual task passed on 2026-10-06; the title-bar icon was reported as a separate issue addressed in v0.1.4.

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
