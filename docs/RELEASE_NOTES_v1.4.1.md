# NFSSE v1.4.1 — English race pictures with km/h

v1.4.1 is a fix for [v1.4](RELEASE_NOTES_v1.4.md) of the **native ports** of
The Need for Speed: Special Edition.

**The downloads contain no game data. You need your own copy of the game**
(the CD, or a full copy of it): `NFS_WIN.EXE` (1,069,056 bytes, SHA-256
`ac72e59587b66f9a3bb2bdb83fa40b8eaac2d68a5ae47a041b026922f8d2594b`) with the
`FRONTEND`, `GAMEDATA` and `SIMDATA` folders. The English files are used.

**Files on this release:** Windows, PlayStation 3 and PS Vita. The macOS file
follows from the Mac; until then the macOS file of
[v1.1](https://github.com/Buyukcaglar/NFSSE/releases/tag/v1.1) stays
available.

## Fixed in v1.4.1

- **Replay buttons in German with "Speed in km/h" on**
  ([#6](https://github.com/Buyukcaglar/NFSSE/issues/6)). v1.4 loaded the
  game's German race pictures whole to get the "KM" label of the top bar, and
  with it the German replay buttons and message pictures. v1.4.1 keeps the
  English pictures and takes only the "KM" label from the German file.

Everything else is as in v1.4 (speeds in km/h, the widescreen fixes).

The Windows program was tested with this change (race, pause menu and
replay with km/h on); the PlayStation 3 and PS Vita files are built from the
same code and had not yet been run on the consoles when this release was
made. If one of them misbehaves, the v1.3 files stay available.

## Installation and controls

As before: see the [v1.0 notes](RELEASE_NOTES_v1.0.md) and the README file of
each download (`README.txt` in the Windows zip, `README-PS3.txt`,
`README-PSVita.txt`). To update, replace the program: unpack the Windows zip
over the old one, or install the PS3 / PS Vita file over the installed one.
The settings and the game files stay.

## Files

| File | For |
| --- | --- |
| `NFSSE-v1.4.1-Windows-x64.zip` | Windows 10 / 11, 64-bit |
| `NFSSE-v1.4.1-PS3-NFSSE0001-nodata.pkg` | PlayStation 3 with custom firmware or HEN |
| `NFSSE-v1.4.1-PSVita-nodata.vpk` | PS Vita / PlayStation TV with HENkaku / Enso |
| `README-PS3.txt`, `README-PSVita.txt` | installation and buttons of the console versions |
| `SHA256SUMS.txt` | checksums of the files above |

The Need for Speed is a trademark of Electronic Arts. This is a fan project,
not affiliated with or endorsed by Electronic Arts.
