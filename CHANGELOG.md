# Changelog

## 1.4.1 — English race pictures with km/h, 2026-11-26

- With "Speed in km/h" on, the replay buttons and other race pictures were
  German (#6): v1.4 loaded the game's German picture file whole. Now the
  English pictures stay and only the "KM" label comes from the German file.
- Windows, PS3 and PS Vita files (the console files not yet run on the
  consoles); the macOS file follows from the Mac.

## 1.4 — Speeds in km/h, and widescreen fixes, 2026-11-26

- Speeds in km/h and distances in km through the game's own metric displays
  (race bar, track lengths, results and records), texts still English:
  "Speed in km/h" in the Windows system menu, L1 + R1 held on the PS3,
  Select + Triangle on the PS Vita; remembered.
- Widescreen race: no more garbage in the top corners from the second race
  on; the sky is no longer a third too tall.
- Windows, PS3 and PS Vita files (the console files not yet run on the
  consoles); the macOS file follows from the Mac.
- Windows file replaced in place (2026-11-26): `NFSSE-v1.4-Windows-x64.zip`
  now also holds `NFSSE/recomplauncher.json` for RecompLauncher (3,070,559
  bytes, SHA-256
  `e31487557adf0b14c75a177728b7cd13addeb3f55175b4e90d93bd94a2d3c160`);
  `NFSSE.exe` in it is byte-identical, `SHA256SUMS.txt` was replaced to
  match. The PS3 and PS Vita files are unchanged.

## 1.3 — Upscaled movies, the PlayStation 3 file, and PS Vita fixes, 2026-11-25

- A `VIDEO` folder next to the program with MP4 files named like the game's
  movies replaces the game's 320x200 movies (own shape, own sound, the same
  skip buttons): Windows (Media Foundation), PS3 (the console's decoder), PS
  Vita (its player). The 4K movies for Windows and macOS are the
  [NFSSE 4K Upscaled Video Pack](https://www.moddb.com/games/the-need-for-speed/downloads/nfsse-4k-upscaled-video-pack)
  on ModDB; for the consoles the
  [PS3 1080p](https://www.moddb.com/games/the-need-for-speed/downloads/nfsse-ps3-1080p-upscaled-video-pack) and
  [PS Vita 544p](https://www.moddb.com/games/the-need-for-speed/downloads/nfsse-ps-vita-544p-upscaled-video-pack) packs.
- The PlayStation 3 file, with the v1.2 changes (DUALSHOCK 3 rumble).
- PS Vita: Enhanced 3D without stuttering sound and dropped pictures (separate
  CPU cores, fewer GPU writes, in-between pictures only when there is time);
  the menu's Exit ends cleanly. Updated PS Vita file (2026-11-26): Enhanced 3D
  at nearly full speed on a real Vita, far fewer sound gaps.
- Windows: messages no longer cut off their last line.
- Windows, PS3 and PS Vita files; the macOS file follows from the Mac.

## 1.2 — Force feedback and rumble, and the PlayStation Vita version, 2026-11-25

- The game's I-Force force feedback effects (steering weight from the tyres'
  grip, jolts, rough surfaces, a tumbling car) on today's devices: Windows
  wheels and force feedback joysticks through DirectInput (also as inputs) and
  XInput rumble, with a system menu switch and `nfsse.ini` settings; the PS3's
  DUALSHOCK 3; a DUALSHOCK 3 or 4 on a PlayStation TV.
- The PS Vita version (960x544, Enhanced 3D, widescreen race) is part of the
  release.
- Windows and PS Vita files; the PS3 file follows after a test on the console,
  the macOS file from the Mac.

## 1.1 — Widescreen race and a longer draw distance, 2026-11-24

- Widescreen race (16:9; F8 or the system menu on Windows, the left stick held
  on a controller, L3 held on the PS3): more road and scenery at the sides,
  menus 4:3, the cockpit view skipped while it is on; switchable at any time
  in Original and Enhanced 3D, remembered.
- At the high detail setting the race draws 60 track sections ahead instead
  of the original 28. On the open roads the distance ends with the road's data
  near the finish (a test build stopped there on City).
- Windows and PlayStation 3 files; the macOS file (universal, signed and
  notarized) added the same afternoon.
- PlayStation Vita file added on 2026-11-25: a native PS Vita program (VPK for
  homebrew systems, title ID NFSSE0001) at the screen's 960x544, with Enhanced
  3D, the widescreen race, the system's keyboard and messages; game files in
  `ux0:data/NFSSE/GAME`. Tried in the Vita3K emulator, not yet on a Vita.

## 1.0 — Native Windows (64-bit) and PlayStation 3 versions, 2026-11-22

- First release of the native ports: the game as a 64-bit Windows program
  (Direct3D 11, WASAPI) and as a PlayStation 3 program, made from the original
  Windows 95 game program by static recompilation. Ready-made downloads without
  game data; the player supplies the original game files.
- Enhanced 3D (F9 on Windows, R3 on the PS3): the race's 3D scene at the
  window's or display's resolution with in-between pictures; the original
  picture stays available at any moment.
- Windows: keyboard, mouse in the menus, XInput controllers with analog
  steering, borderless full screen, optional CRT scanlines, saves in a `USER`
  folder next to the program.
- PlayStation 3: 1080p, analog steering, the system's on-screen keyboard.
- macOS, added to the release on 2026-11-22: a universal application (Apple
  silicon and Intel, macOS 11 or later; Metal, Core Audio) with the Windows
  version's functions: Enhanced 3D (Command-E or F9), native full screen,
  optional CRT scanlines, mouse in the menus, game controllers with analog
  steering, saves in `~/Library/Application Support/NFSSE`. Signed with a
  Developer ID and notarized by Apple.
- Not included: network, modem and serial play; languages other than English.
- The compatibility patch kit (0.2.2 and earlier) is unchanged and stays
  available under its own release tags.
- 2026-11-23, Windows and PlayStation 3 files replaced (version unchanged): in Enhanced 3D other cars
  no longer jitter (the in-between pictures moved them but not the camera). The macOS file follows.
- 2026-11-23, second update, Windows file (version unchanged): in Enhanced 3D the opponent no longer
  slides sideways while the camera turns (the camera's turn was left out of the in-between pictures near
  straight-ahead headings); the program checks the game copy before it starts and names what is missing or
  different instead of closing without a word; the game's own file errors are explained; messages and the
  folder picker follow the Windows dark or light theme. The PlayStation 3 and macOS files follow.
- 2026-11-23, evening, PlayStation 3 and Windows files (version unchanged): the PlayStation 3 version has
  the same two changes, with the system's message dialog. Fixed on both: when the program was closed
  during its start (PS button, Quit Game), it no longer opens a message while it ends; on the PlayStation 3
  that left the game unable to start again until the console restarted. The macOS file follows.
- 2026-11-23, evening, macOS file (version unchanged): all of the above. In Enhanced 3D other cars and
  the opponent no longer jitter; the application checks the game copy before it starts, says what is
  missing or different and lets you choose another folder or start anyway; the game's own file errors
  are explained in macOS alerts.

## 0.2.2 — Portable player persistence, 2026-10-07

- Save a confirmed player name immediately, and checkpoint the original
  configuration/records block on the game's normal exit and Alt+F4.
- Replace configuration files only after a complete flushed write; preserve
  previous data and report save failures.
- Replace six legacy save-space checks that truncate disk sizes with a 64-bit
  query for the executable-relative game folder. Original tournament/replay
  formats and Save/Load controls remain in use.
- Update language-selector/runtime integrity pins and retain configuration and
  the previous helper in update backups. All player storage remains portable.
- Add native original-serializer/reload, separate-process exit/restart,
  failure-preservation, relocation and media-independent CI checks. Automated
  persistence checks do not establish full in-game race completion.
- Record the user's successful persistence play checks on 2026-10-07. Package
  the exact tested helper with updated save-location, update and backup guides.

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
