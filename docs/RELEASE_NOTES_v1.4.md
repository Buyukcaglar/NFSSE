# NFSSE v1.4 — Speeds in km/h, and widescreen fixes

v1.4 updates the **native ports** of The Need for Speed: Special Edition: the
game's own code, translated by static recompilation into a 64-bit Windows
program, a macOS application, a PlayStation 3 program and a PlayStation Vita
program (earlier releases: [v1.3](RELEASE_NOTES_v1.3.md),
[v1.2](RELEASE_NOTES_v1.2.md), [v1.1](RELEASE_NOTES_v1.1.md),
[v1.0](RELEASE_NOTES_v1.0.md)).

**The downloads contain no game data. You need your own copy of the game**
(the CD, or a full copy of it): `NFS_WIN.EXE` (1,069,056 bytes, SHA-256
`ac72e59587b66f9a3bb2bdb83fa40b8eaac2d68a5ae47a041b026922f8d2594b`) with the
`FRONTEND`, `GAMEDATA` and `SIMDATA` folders. The English files are used.

**Files on this release:** Windows, PlayStation 3 and PS Vita. The macOS file
follows from the Mac; until then the macOS file of
[v1.1](https://github.com/Buyukcaglar/NFSSE/releases/tag/v1.1) stays
available.

## New in v1.4

- **Speeds in km/h** ([#5](https://github.com/Buyukcaglar/NFSSE/issues/5)).
  The game's own metric displays can be switched on: the race's speed in km/h
  and its distance in km (with the game's own "KM" bar), the tracks' lengths
  in km, and the speeds of the results and records in km/h. The texts stay
  English. The choice is remembered; changed during a race it counts from the
  next race. The dials of the cockpit view are the cars' own and do not
  change.
  - Windows: "Speed in km/h" in the window's system menu (the icon in the
    title bar, or Alt+Space); `kmh=1` in `nfsse.ini`.
  - PlayStation 3: L1 and R1 held together for a second.
  - PS Vita: Select + Triangle.
- **Widescreen race fixes.** From the second race of a session on, the top
  corners of the picture could show garbage; and the sky was drawn a third
  too tall while widescreen was on. Both are fixed (all versions).

The Windows program was tested with these changes; the PlayStation 3 and PS
Vita files are built from the same code and had not yet been run on the
consoles when this release was made. If one of them misbehaves, the v1.3
files stay available.

## Installation and controls

As before: see the [v1.0 notes](RELEASE_NOTES_v1.0.md) and the README file of
each download (`README.txt` in the Windows zip, `README-PS3.txt`,
`README-PSVita.txt`). The upscaled movie packs of
[v1.3](RELEASE_NOTES_v1.3.md) work with v1.4 unchanged.

## Files

| File | For |
| --- | --- |
| `NFSSE-v1.4-Windows-x64.zip` | Windows 10 / 11, 64-bit |
| `NFSSE-v1.4-PS3-NFSSE0001-nodata.pkg` | PlayStation 3 with custom firmware or HEN |
| `NFSSE-v1.4-PSVita-nodata.vpk` | PS Vita / PlayStation TV with HENkaku / Enso |
| `README-PS3.txt`, `README-PSVita.txt` | installation and buttons of the console versions |
| `SHA256SUMS.txt` | checksums of the files above |

The Need for Speed is a trademark of Electronic Arts. This is a fan project,
not affiliated with or endorsed by Electronic Arts.
