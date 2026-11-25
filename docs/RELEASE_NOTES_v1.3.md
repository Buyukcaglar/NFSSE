# NFSSE v1.3 — Upscaled movies, the PlayStation 3 file, and PS Vita fixes

v1.3 updates the **native ports** of The Need for Speed: Special Edition: the
game's own code, translated by static recompilation into a 64-bit Windows
program, a macOS application, a PlayStation 3 program and a PlayStation Vita
program (earlier releases: [v1.2](RELEASE_NOTES_v1.2.md),
[v1.1](RELEASE_NOTES_v1.1.md), [v1.0](RELEASE_NOTES_v1.0.md)).

**The downloads contain no game data. You need your own copy of the game**
(the CD, or a full copy of it): `NFS_WIN.EXE` (1,069,056 bytes, SHA-256
`ac72e59587b66f9a3bb2bdb83fa40b8eaac2d68a5ae47a041b026922f8d2594b`) with the
`FRONTEND`, `GAMEDATA` and `SIMDATA` folders. The English files are used.

**Files on this release:** Windows, PlayStation 3 and PS Vita. The macOS file
follows from the Mac; until then the macOS file of
[v1.1](https://github.com/Buyukcaglar/NFSSE/releases/tag/v1.1) stays
available.

## New in v1.3

- **Upscaled movies.** When a folder named `VIDEO` next to the program holds
  MP4 files named like the game's movies (`EA.mp4`, `TITLE.mp4`,
  `ATTRACT1.mp4`, `NSX.mp4`, `WIN#1.mp4` and so on: the names in the game's
  `FRONTEND\MOVIE` folder), the program plays those instead of the game's own
  320x200 movies: as large as the window or screen allows at the movie's own
  shape, with their own sound. The buttons that skip a movie in the original
  still do (and skip the rest of the opening, as before). A movie without a
  file plays as the original.
  - **The 4K movies for Windows (and macOS):** the
    [NFSSE 4K Upscaled Video Pack](https://www.moddb.com/games/the-need-for-speed/downloads/nfsse-4k-upscaled-video-pack)
    on ModDB, all 26 movies AI-upscaled to 4K (2.1 GB). Unzip it next to
    `NFSSE.exe`. Windows decodes them (H.264 with AAC sound; a graphics card
    from the last ten years or so). The macOS application plays them from the
    version with its movie player, which follows from the Mac.
  - PlayStation 3: `/dev_hdd0/game/NFSSE0001/USRDIR/VIDEO/`, decoded by the
    console's video decoder: H.264 High profile up to level 4.1 and 1920x1088,
    with 16-bit PCM sound. The movies made for it:
    [NFSSE PS3 1080p Upscaled Video Pack](https://www.moddb.com/games/the-need-for-speed/downloads/nfsse-ps3-1080p-upscaled-video-pack)
    on ModDB (0.9 GB).
  - PS Vita: `ux0:data/NFSSE/VIDEO/`, decoded by the Vita's player: H.264 up
    to 960x544 with AAC sound. The movies made for it:
    [NFSSE PS Vita 544p Upscaled Video Pack](https://www.moddb.com/games/the-need-for-speed/downloads/nfsse-ps-vita-544p-upscaled-video-pack)
    on ModDB (0.2 GB).
- **PlayStation 3 file.** The v1.2 changes (the DUALSHOCK 3's motors play the
  game's force feedback effects) reach the PS3 with this release.
- **PS Vita fixes** after the first report from a real Vita: Enhanced 3D no
  longer makes the sound stutter and drop pictures as before (the game, the
  drawing and the sound now run on separate CPU cores; only the changed image
  rows are written to the GPU; in-between pictures are drawn only when there
  is time for them), and "Exit" in the game's first menu ends the program
  cleanly instead of with a crash report.
- **Windows:** the program's messages (for example the question for the game
  folder) no longer cut off their last line.

## Downloads

| File | For |
| --- | --- |
| `NFSSE-v1.3-Windows-x64.zip` | Windows 10 or 11, 64-bit, Direct3D 11 |
| `NFSSE-v1.3-PS3-NFSSE0001-nodata.pkg` | PlayStation 3 that runs homebrew |
| `NFSSE-v1.3-PSVita-nodata.vpk` | PS Vita or PlayStation TV that runs homebrew |
| `README-PS3.txt` | Install steps and buttons for the PS3 |
| `README-PSVita.txt` | Install steps and buttons for the PS Vita |
| `SHA256SUMS.txt` | Checksums of the files above |

Windows: extract the ZIP over the earlier version's folder (the `USER`
folder with settings and best times stays) and start `NFSSE.exe`. PS3:
install the package over the earlier one (`USRDIR/GAME` and `USRDIR/USER`
stay). PS Vita: install the VPK with VitaShell, also over v1.2
(`ux0:data/NFSSE` with the game files, settings and best times stays).
`README.txt` in the ZIP, `README-PS3.txt` and `README-PSVita.txt` have the full
key and button lists.

## Checks

- The translated code was compared with a reference run of the original
  program call by call (start-up demo race and a scripted race): identical.
  The movie player changes nothing in the game itself.
- Windows: the 4K movies play at their 15 pictures a second with their sound
  (332 of 333 pictures of the EA logo shown on time); Enter skips the opening
  and the menu follows.
- PlayStation 3, on a console: the 1080-row movies play on time (330 of 333
  and 509 of 512 pictures shown) with their sound; Cross skips the opening.
- PS Vita, in the Vita3K emulator: a movie from `VIDEO` with its sound, skipped
  by a button; the menu's Exit ends cleanly; the Enhanced 3D race.

**Not tried yet:** the PS Vita version's speed on a real Vita after the fixes,
and force feedback and rumble with a real wheel, joystick or controller.
Reports are welcome in the
[issues](https://github.com/Buyukcaglar/NFSSE/issues/new/choose).

## Not in this version

- Network, modem and serial play.
- Languages other than English.
- PS Vita: the touch screens; analog accelerator and brake.
