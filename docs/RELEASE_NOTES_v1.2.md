# NFSSE v1.2 — Force feedback and rumble, and the PlayStation Vita version

v1.2 updates the **native ports** of The Need for Speed: Special Edition: the
game's own code, translated by static recompilation into a 64-bit Windows
program, a macOS application, a PlayStation 3 program and a PlayStation Vita
program (earlier releases: [v1.1](RELEASE_NOTES_v1.1.md),
[v1.0](RELEASE_NOTES_v1.0.md)).

**The downloads contain no game data. You need your own copy of the game**
(the CD, or a full copy of it): `NFS_WIN.EXE` (1,069,056 bytes, SHA-256
`ac72e59587b66f9a3bb2bdb83fa40b8eaac2d68a5ae47a041b026922f8d2594b`) with the
`FRONTEND`, `GAMEDATA` and `SIMDATA` folders. The English files are used.

**Files on this release:** Windows and PS Vita. The PlayStation 3 file follows
once it has been tried on a console, and the macOS file follows from the Mac.
Until then the PS3 and macOS files of
[v1.1](https://github.com/Buyukcaglar/NFSSE/releases/tag/v1.1) stay available.

## New in v1.2

- **Force feedback and rumble.** The game was made for Immersion's I-Force
  force feedback joystick (1996). Its effects now reach today's devices: the
  weight of the steering in bends (the tyres' grip), jolts in collisions, at
  walls and on landing, and the shaking of rough surfaces and of a tumbling
  car.
  - Windows: wheels and force feedback joysticks (DirectInput; they also work
    as inputs now, with analog steering and pedals), and Xbox / XInput
    controllers as rumble. "Force feedback and rumble" in the window's system
    menu switches them off and on; `USER\nfsse.ini` has `ff_strength`,
    `ff_tyre_forces` and `ff_invert` (for a device that pushes the wrong way).
  - PlayStation 3 (with its file): the DUALSHOCK 3's motors.
  - PlayStation TV: a DUALSHOCK 3 or 4 vibrates (the PS Vita itself has no
    motors).
- **PlayStation Vita version** (added to v1.1 on 2026-11-25, now part of the
  release). A native program for PS Vita and PlayStation TV systems that run
  homebrew (HENkaku / Ensō, installed with VitaShell), title ID NFSSE0001. The
  picture uses the Vita's whole screen resolution, 960x544. Enhanced 3D draws
  the race's 3D scene at that resolution with extra pictures between the
  game's own; the widescreen race fills the screen. The player's name is typed
  with the system's keyboard. Game files go to `ux0:data/NFSSE/GAME`.

## Downloads

| File | For |
| --- | --- |
| `NFSSE-v1.2-Windows-x64.zip` | Windows 10 or 11, 64-bit, Direct3D 11 |
| `NFSSE-v1.2-PSVita-nodata.vpk` | PS Vita or PlayStation TV that runs homebrew |
| `README-PSVita.txt` | Install steps and buttons for the PS Vita |
| `SHA256SUMS.txt` | Checksums of the files above |

Windows: extract the ZIP over the earlier version's folder (the `USER`
folder with settings and best times stays) and start `NFSSE.exe`. PS Vita:
install the VPK with VitaShell, also over v1.1 (`ux0:data/NFSSE` with the
game files, settings and best times stays). `README.txt` in the ZIP and
`README-PSVita.txt` have the full key and button lists.

## Checks

- The translated code was compared with a reference run of the original
  program call by call (start-up demo race and a scripted race): identical.
  The force effects change nothing in the game itself.
- Windows: in a race the game's effects reach the program as expected
  (strength 22-80 % jolts on bumps and car hits, rough-surface shaking at
  12 Hz, tyre forces every step, with the sign that pulls the steering back
  to the centre).
- PS Vita, in the Vita3K emulator: the start with the game files in the
  package and on the memory card, the message when they are missing, the demo
  race, and scripted races in Original and in Enhanced 3D with widescreen.

**Not tried yet:** force feedback and rumble with a real wheel, joystick or
controller (none was at hand), and the PS Vita version on a real Vita or
PlayStation TV (its speed there is not known yet). Reports are welcome in the
[issues](https://github.com/Buyukcaglar/NFSSE/issues/new/choose).

## Not in this version

- Network, modem and serial play.
- Languages other than English.
- PS Vita: the touch screens; analog accelerator and brake.
