# NFSSE v1.4.3 — a switch for the stick's widescreen hold, a clean Quit (Windows)

v1.4.3 is an update of the **Windows version** of the native ports of The
Need for Speed: Special Edition. The PlayStation 3, PS Vita and macOS
versions are unchanged: this release carries the v1.4.2 PlayStation 3 and
PS Vita files as they were, and the macOS file stays on
[v1.4.1](https://github.com/Buyukcaglar/NFSSE/releases/tag/v1.4.1).

**The downloads contain no game data. You need your own copy of the game**
(the CD, or a full copy of it): `NFS_WIN.EXE` (1,069,056 bytes, SHA-256
`ac72e59587b66f9a3bb2bdb83fa40b8eaac2d68a5ae47a041b026922f8d2594b`) with the
`FRONTEND`, `GAMEDATA` and `SIMDATA` folders. The English files are used.

## New in v1.4.3 (Windows)

- **The left stick's widescreen switch can be turned off**
  ([#8](https://github.com/Buyukcaglar/NFSSE/issues/8)). On a controller,
  holding the left stick in for a second switches the widescreen race, and
  the same button is the horn: a long horn switched widescreen, and with
  widescreen on the cockpit view is left out. The new item "Left stick held
  switches widescreen" in the window's system menu (`stick_widescreen` in
  `USER\nfsse.ini`, also a setting in RecompLauncher) turns that switch off.
  It is on by default, as before. F8 and the menu still switch widescreen.
- **Quitting no longer ends in an error now and then**
  ([#10](https://github.com/Buyukcaglar/NFSSE/issues/10)). When Quit was
  chosen in the game, the program ended from the game's own thread while
  the sound and controller were still running, and Windows could report an
  access violation. Now the program's main thread ends it in order, as the
  PS Vita version already does.

The Windows program was tested by quitting through the game's menu (it ends
cleanly, settings written) and by switching the new setting; the stick hold
itself was not tried on a controller for this release, and the rare error at
Quit was not seen in the tests before or after the change.

## Installation and controls

As before: see the [v1.0 notes](https://github.com/Buyukcaglar/NFSSE/blob/main/docs/RELEASE_NOTES_v1.0.md) and the README file of
each download (`README.txt` in the Windows zip, `README-PS3.txt`,
`README-PSVita.txt`). To update on Windows, unpack the zip over the old one.
The settings and the game files stay. Players of v1.4.2 on the PlayStation 3
or PS Vita have nothing to update.

## Files

| File | For |
| --- | --- |
| `NFSSE-v1.4.3-Windows-x64.zip` | Windows 10 / 11, 64-bit |
| `NFSSE-v1.4.2-PS3-NFSSE0001-nodata.pkg` | PlayStation 3 with custom firmware or HEN (unchanged from v1.4.2) |
| `NFSSE-v1.4.2-PSVita-nodata.vpk` | PS Vita / PlayStation TV with HENkaku / Enso (unchanged from v1.4.2) |
| `README-PS3.txt`, `README-PSVita.txt` | installation and buttons of the console versions (v1.4.2) |
| `SHA256SUMS.txt` | checksums of the files above |

The Need for Speed is a trademark of Electronic Arts. This is a fan project,
not affiliated with or endorsed by Electronic Arts.
