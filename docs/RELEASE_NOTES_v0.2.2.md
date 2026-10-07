# NFSSE v0.2.2 — Portable player persistence

The Windows game could forget a confirmed player name because name entry did
not immediately save the configuration. Its old disk-space check also truncated
modern disk values and could incorrectly block saving despite ample free space.

v0.2.2 saves confirmed names immediately, checkpoints settings and records on
normal exit, and uses a 64-bit free-space check for the game folder. Complete
flushed configuration writes preserve the previous file if replacement fails,
and a save failure is reported to the player.

| Location relative to the game folder | Data |
| --- | --- |
| `GAMEDATA/CONFIG/CONFIG.DAT` | Last confirmed name, settings, records and original configuration fields |
| `GAMEDATA/SAVEGAME/*.SAV` | Tournament progress saved/restored with the game's Save/Load controls |
| `GAMEDATA/REPLAY/` | Replays |

Keep `CONFIG.DAT`; deleting it discards the data it contains. Back up `GAMEDATA`.
Move the complete writable installation to carry player data with it. All game
paths remain relative to the executable's folder. Unsaved races/tournaments are
not automatically resumed.

Download and extract `NFSSE-v0.2.2-patch-kit.zip`, then run `Install-NFSSE.cmd`
with your supported original media. Use a new, empty destination for fresh
installation. To update an existing v0.2.1 kit installation, close the game,
back up player data, and select the same destination. Saves, settings and
language selection are preserved; replaced managed files and the previous
helper/configuration are backed up inside `.patch-backups`.

The exact tested helper is included. Optional English/German/Japanese selection,
the Japanese Graphics fix, original game engine, artwork, renderer, title and
icon are retained. The kit includes no original game executable, media, artwork,
audio or icon; these come from your own media. Players need no Python, Visual
Studio or administrator rights.

The user confirmed the persistence play checks passed on 2026-10-07. Automated
checks independently cover complete configuration/tournament byte restoration,
exit/restart, failed-save preservation, relocation, 64-bit disk space, standard
installation and all optional languages. Those isolated checks do not start the
game; exhaustive championship, multiplayer and other-host coverage remain open.

See the [user guide](https://github.com/Buyukcaglar/NFSSE/blob/main/docs/USER_GUIDE.md),
[player persistence](https://github.com/Buyukcaglar/NFSSE/blob/main/docs/PLAYER_PERSISTENCE.md)
and [validation record](https://github.com/Buyukcaglar/NFSSE/blob/main/docs/VALIDATION.md).
