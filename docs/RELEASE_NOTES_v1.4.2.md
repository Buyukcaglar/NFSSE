# NFSSE v1.4.2 — wheel forces on mirrored tracks, damaged game files named

v1.4.2 is an update of [v1.4.1](RELEASE_NOTES_v1.4.1.md) of the **native
ports** of The Need for Speed: Special Edition. Both changes concern the
Windows version; the PlayStation 3 and PS Vita files are rebuilt from the
same code and otherwise as v1.4.1.

**The downloads contain no game data. You need your own copy of the game**
(the CD, or a full copy of it): `NFS_WIN.EXE` (1,069,056 bytes, SHA-256
`ac72e59587b66f9a3bb2bdb83fa40b8eaac2d68a5ae47a041b026922f8d2594b`) with the
`FRONTEND`, `GAMEDATA` and `SIMDATA` folders. The English files are used.

**Files on this release:** Windows, PlayStation 3 and PS Vita. The macOS file
follows from the Mac; until then use the macOS file of
[v1.4.1](https://github.com/Buyukcaglar/NFSSE/releases/tag/v1.4.1).

## New in v1.4.2

- **Force feedback on mirrored tracks (Windows, wheels and force feedback
  joysticks).** On a mirrored track the game runs the race unmirrored and
  mirrors the picture and the steering, but its force feedback code does not
  know about it. So the sideways forces pushed the wrong way there: in a bend
  the wheel was turned into the bend instead of resisting. This is the
  original game's behaviour with its I-Force driver. Now the sideways part of
  every effect (tyre forces, hits from the left or right, the road's shaking)
  is turned round on a mirrored track. Normal tracks are unchanged; rumble
  pads have no direction and are unchanged too.
- **Damaged game files are named (Windows).** Until now the game copy was
  checked for missing files and sizes only. A file of the right size with
  wrong content, as a scratched disc or a faulty disc image gives, went
  unnoticed until the game hung or failed where it used it
  ([#4](https://github.com/Buyukcaglar/NFSSE/issues/4): Coastal hung while
  loading because of one unreadable CD sector in `CL1.TRI`). At the first
  start with a game copy the program now reads all its files once and compares
  them with the original's checksums. Damaged files are named, and you can
  choose another folder, start anyway or quit. The result is remembered
  (`gamecopy.chk` in the `USER` folder) until a file of the copy changes, so
  later starts are as fast as before.

The force feedback change was measured with the game's own forces in a test
race (on a mirrored track every sample pushed with the steering before, and
against it now), not on a wheel. The Windows program was tested with an
intact and a damaged game copy. The PlayStation 3 and PS Vita files had not
yet been run on the consoles when this release was made; if one of them
misbehaves, the v1.4.1 files stay available.

## Installation and controls

As before: see the [v1.0 notes](RELEASE_NOTES_v1.0.md) and the README file of
each download (`README.txt` in the Windows zip, `README-PS3.txt`,
`README-PSVita.txt`). To update, replace the program: unpack the Windows zip
over the old one, or install the PS3 / PS Vita file over the installed one.
The settings and the game files stay.

## Files

| File | For |
| --- | --- |
| `NFSSE-v1.4.2-Windows-x64.zip` | Windows 10 / 11, 64-bit |
| `NFSSE-v1.4.2-PS3-NFSSE0001-nodata.pkg` | PlayStation 3 with custom firmware or HEN |
| `NFSSE-v1.4.2-PSVita-nodata.vpk` | PS Vita / PlayStation TV with HENkaku / Enso |
| `README-PS3.txt`, `README-PSVita.txt` | installation and buttons of the console versions |
| `SHA256SUMS.txt` | checksums of the files above |

The Need for Speed is a trademark of Electronic Arts. This is a fan project,
not affiliated with or endorsed by Electronic Arts.
