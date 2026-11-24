# NFSSE v1.1 — Widescreen race and a longer draw distance

v1.1 updates the **native ports** of The Need for Speed: Special Edition (first
released as [v1.0](RELEASE_NOTES_v1.0.md)): the game's own code, translated
for 64-bit Windows, macOS and the PlayStation 3 by static recompilation.

**The downloads contain no game data. You need your own copy of the game**
(the CD, or a full copy of it): `NFS_WIN.EXE` (1,069,056 bytes, SHA-256
`ac72e59587b66f9a3bb2bdb83fa40b8eaac2d68a5ae47a041b026922f8d2594b`) with the
`FRONTEND`, `GAMEDATA` and `SIMDATA` folders. The English files are used.

The macOS file of v1.1 follows; until then the macOS application of
[v1.0](https://github.com/Buyukcaglar/NFSSE/releases/tag/v1.0) stays available.

## New in v1.1

- **Widescreen race.** The race at 16:9: more road and scenery at both sides,
  the game's displays in the middle as before. The menus stay 4:3. While it is
  on, the camera skips the cockpit view (the bumper view is used instead). It
  can be switched at any time, also during a race, in both Original and
  Enhanced 3D, and the choice is remembered.
  - Windows: F8, or "Widescreen race" in the window's system menu; on a
    controller, the left stick pressed and held for a second.
  - PlayStation 3: L3 held for a second.
- **Longer draw distance.** At the high graphics detail setting the race draws
  the road and its scenery more than twice as far ahead as the original game
  (60 track sections instead of 28), so buildings, rocks and trees no longer
  appear out of nowhere close to the car. The medium and low settings are the
  original's.

## Downloads

| File | For |
| --- | --- |
| `NFSSE-v1.1-Windows-x64.zip` | Windows 10 or 11, 64-bit, Direct3D 11 |
| `NFSSE-v1.1-PS3-NFSSE0001-nodata.pkg` | PlayStation 3 with custom firmware |
| `README-PS3.txt` | Install steps and controls for the PS3 |
| `SHA256SUMS.txt` | Checksums of the files above |

Installation is as in v1.0: extract the ZIP and start `NFSSE.exe`, or install
the PKG over v1.0 (settings, best times and the game files in `USRDIR/GAME`
stay). `README.txt` in the ZIP and `README-PS3.txt` have the full key and
button lists.

## Checks

- The translated code was compared with a reference run of the original
  program call by call (start-up demo race and a scripted race): identical.
- Every track the menus offer was driven with the longer draw distance, in
  Original and Enhanced 3D.
- PS3, on a real console: whole races in both modes at v1.0's speed (33.4
  simulation steps per second), widescreen switched on and off during races,
  the pause menu, and a City race to its finish.
- Found before this release and fixed in it: on the open-road tracks (Coastal,
  Alpine, City) the longer draw distance ran past the end of the road's data
  shortly before the finish, and the race stopped there. Near the end of an
  open road the draw distance now ends with the road.

## Not in this version

- Network, modem and serial play.
- Languages other than English.
- Joysticks and wheels other than game controllers (XInput on Windows); force
  feedback.
