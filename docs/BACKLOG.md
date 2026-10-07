# Backlog

## IFORCE-001 — Modern USB I-Force support

**Status:** closed; reported working, no further work planned.

Closed in [GitHub issue #1](https://github.com/Buyukcaglar/NFSSE/issues/1).

On 2026-10-06 the user reported that I-Force was working and explicitly requested no further work on it. The original call path and `IFORCE.DLL` remain intact; no new adapter or wrapper integration was implemented for this closure.

The [working report](../research/validation/iforce-user-report.json) records the user's statement without inferring a specific controller, wrapper configuration or independent hardware test.

## Validation follow-ups

- Complete the separate in-game focus-recovery and Alt+F4 checks without desktop mode changes. The window-presentation visual task is already accepted.
- Expand smaller-desktop and broader host/transition coverage. The user accepted the window-presentation task and the full window title/original-icon visual task.
- Expand race/championship coverage beyond the persistence play checks accepted on 2026-10-07; see [user acceptance](../research/validation/player-persistence-user-acceptance.json).
- Expand host/display coverage and assess multiplayer separately.

Higher internal rendering resolution is outside the accepted original-image scaling objective. New media builds need their own source hashes and verified patch recipe.
