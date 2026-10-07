# Portable player persistence

The v0.2.2 update saves the confirmed player name immediately and saves
the current settings/records block on normal process exit, including the game's
Quit option and Alt+F4. These checkpoints keep the original game's data format.

Storage stays inside the game folder:

| Relative file/folder | Purpose |
| --- | --- |
| `GAMEDATA/CONFIG/CONFIG.DAT` | Last confirmed name, settings, records and the other fields in the original 24,402-byte configuration |
| `GAMEDATA/SAVEGAME/*.SAV` | Explicitly saved tournament state, using the original Save/Load controls and 1,462-byte format |
| `GAMEDATA/REPLAY/` | Original replay storage |

The helper derives the root from the running game executable on each launch.
There is no registry, AppData, Documents or fixed installation path for player
storage. Moving the complete writable game folder carries this data with it.
Tournament Save/Load behavior remains the game's own; this patch does not add
automatic resumption of an unsaved race or tournament.

Keep `CONFIG.DAT`: deleting it discards the stored name, settings and records.
If intentionally resetting these, close the game and retain a backup such as
`CONFIG.DAT.bak`. Tournament `.SAV` files are separate. Back up the complete
`GAMEDATA` folder to preserve both kinds of data.

The original configuration writer is called after selected game/menu transitions,
but name confirmation itself does not call it. The patch replaces its three
caller checkpoints, adds a checkpoint after successful name entry, and intercepts
both game `ExitProcess` imports after the original configuration loader has run.
Cancelled name entry and exits before configuration initialization do not save.

Each checkpoint writes a complete temporary file beside CONFIG.DAT, flushes it,
closes it and replaces the previous file. A failed write/replacement leaves the
previous configuration intact and reports the failure. It never truncates the
last saved configuration before the new copy is complete.

The original save-space routine copies disk geometry/free-cluster counts into
16-bit fields and compares a signed 32-bit multiplication. An ample modern disk
can therefore appear full. All six callers now use a 64-bit free-space query for
the game folder, retaining the requested-size check and failure behavior.

## Verification

`tests/PlayerPersistenceTests.cpp` maps only the hash-verified original engine
in a test process. It invokes the original configuration and tournament file
serializers/loaders with real files in a separate, disposable game folder.
Allocation, formatting and lock support are supplied by the harness; the game
entry point, renderer, audio, name dialog and simulation are never started.

The checks establish byte identity for the full configuration and tournament
state, restoration in a new process after the intercepted exit import, immediate
confirmed-name saving, cancelled-name/readiness guards, preserved data after a
failed replacement, rejection of unexpected hook instructions, and relocation
with a different launch directory. A simulated 256 MB free disk reproduces the
original truncation failure; the new check passes threshold and multi-terabyte
cases. Synthetic tournament data proves serialization and restoration, not
race-completion or championship semantics.

Media-independent checks also run in CI. The existing input, window/renderer
policy, configuration migration and language-selection checks remain in place.
Fresh/repeated installation checks verify save/settings preservation and all
three language inventories. On 2026-10-07 the user stated, "Ok user play checks
passed", accepting the persistence play checks. Their earlier report identifies
the game's own Quit/Exit option as their exit method. See
[user acceptance](../research/validation/player-persistence-user-acceptance.json).
The individual race modes and championship stages were not specified, so this
does not establish exhaustive championship, other-host or multiplayer coverage.

Developer commands from the repository root:

```cmd
tools\test-player-persistence.cmd --storage "%CD%\build\player-storage-check"
tools\test-player-persistence.cmd "%CD%\install\NFS_WIN.EXE" "%CD%\install\GAMEDATA\CONFIG\CONFIG.DAT" "%CD%\build\player-native-check"
build\PlayerPersistenceTests.exe "%CD%\install\NFS_WIN.EXE" "%CD%\install\GAMEDATA\CONFIG\CONFIG.DAT" "%CD%\build\player-native-check relocated" --exit
build\PlayerPersistenceTests.exe "%CD%\install\NFS_WIN.EXE" "%CD%\install\GAMEDATA\CONFIG\CONFIG.DAT" "%CD%\build\player-native-check relocated" --restore
```

Use new output directories for the first two commands. Test names and state
exist only in those directories; the player's actual files are not test inputs.
