# NFSSE v1.0 — Native Windows (64-bit) and PlayStation 3 versions

v1.0 is the first release of the **native ports**: The Need for Speed: Special
Edition as a 64-bit Windows program and as a PlayStation 3 program. They need
no compatibility layer, no DirectX 3 runtime and no installer.

Both are made from the original Windows 95 game program by static
recompilation: the game's own code, translated for the new machines. They are
not an emulator and not a rewrite, so the physics, the opponents, the menus
and the timing are the game's own.

**The downloads contain no game data. You need your own copy of the game**
(the CD, or a full copy of it): `NFS_WIN.EXE` (1,069,056 bytes, SHA-256
`ac72e59587b66f9a3bb2bdb83fa40b8eaac2d68a5ae47a041b026922f8d2594b`) with the
`FRONTEND`, `GAMEDATA` and `SIMDATA` folders. The English files are used.

## Downloads

| File | For |
| --- | --- |
| `NFSSE-v1.0-Windows-x64.zip` | Windows 10 or 11, 64-bit, Direct3D 11 |
| `NFSSE-v1.0-PS3-NFSSE0001-nodata.pkg` | PlayStation 3 with custom firmware |
| `README-PS3.txt` | Install steps and controls for the PS3 |
| `SHA256SUMS.txt` | Checksums of the files above |

## Windows

1. Extract the ZIP to any folder you can write to and start `NFSSE.exe`.
2. On the first start, choose the folder of your game copy. The program
   remembers it. It does not ask when the game's files are next to `NFSSE.exe`
   or in a folder named `GAME` next to it.

Nothing is written into your game copy. Settings, best times, replays, saved
tournaments and the log go to a `USER` folder next to `NFSSE.exe`.

| Key | Function |
| --- | --- |
| Arrow keys | Steer, accelerate, brake; move in the menus |
| Enter / Escape | Select / back; Escape pauses a race |
| Space, A / Z, C, H | Handbrake, gear up / down, camera, horn |
| F9 | Enhanced 3D on / off |
| Alt+Enter or F11 | Full screen on / off |

The mouse works in the menus. Xbox-type (XInput) controllers work with analog
steering. The window's system menu (the icon in the title bar) also has
"CRT scanlines" and "About". The game stands still while its window is not the
active one. `README.txt` in the ZIP has the full list.

## PlayStation 3

1. Install the PKG (Package Manager, Install Package Files).
2. Copy `NFS_WIN.EXE`, `FRONTEND`, `GAMEDATA` and `SIMDATA` of your game copy
   to `/dev_hdd0/game/NFSSE0001/USRDIR/GAME/`.
3. Start "The Need for Speed: Special Edition" from the XMB.

D-pad or left stick steer, R2 accelerates, L2 brakes, Cross selects, Circle
goes back, Start pauses. R3 held for half a second switches Enhanced 3D.
`README-PS3.txt` has the full list.

## Enhanced 3D

In a race, Enhanced 3D draws the 3D scene at the window's or the display's
resolution instead of 640x480, with extra pictures between the game's own 33
per second. The cockpit, the HUD and the mirror stay the original artwork. The
game itself is the same in both modes, and you can switch at any moment.

## Not in this version

- Network, modem and serial play.
- Languages other than English.
- Joysticks and wheels other than XInput controllers; force feedback.
- The distance at which the track and its scenery appear is the original
  game's; a longer one is planned for v1.1.

## Checks

- During development the translated code was compared with a reference run of
  the original program call by call: 21,150 drawn frames and 42,525 simulation
  steps of racing gave identical results.
- PS3, on a real console on 2026-11-22: unattended 8-lap races in Enhanced 3D
  held 33.4 simulation steps per second with 42 to 60 pictures per second and
  no late audio block.
- Windows, on one PC (Windows 11, NVIDIA graphics): a scripted 8-lap race in
  Enhanced 3D held 60 pictures per second; window functions, both ways of
  leaving the game and the first-start folder dialog were checked by script.
  Controllers, other graphics hardware and other display scalings were not
  tried.

## The earlier releases

The compatibility patch kit for the original program (v0.2.2 and earlier)
stays available under its own release tags and is not changed by v1.0.

The Need for Speed is a trademark of Electronic Arts. This is an independent
fan project, not affiliated with or endorsed by Electronic Arts.
