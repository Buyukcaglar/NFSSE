# Backlog

## IFORCE-001 — Modern USB I-Force support

**Priority:** low. **Status:** deferred; no implementation in v0.1.0.

Tracked in [GitHub issue #1](https://github.com/Buyukcaglar/NFSSE/issues/1).

Preserve the game's original I-Force call path and `IFORCE.DLL` while investigating how original force-feedback effects could reach compatible modern USB devices. The user requested USB devices if possible and then explicitly deferred implementation.

Before work starts, identify an actual device/model and its Windows driver/API, map the original DLL's calls and effect behavior, and determine whether an adapter can preserve those semantics. Validation requires real hardware and comparison against original effect behavior. Merely detecting a USB controller is insufficient evidence of force-feedback support.

The current release copies the original DLL unchanged. It does not claim that USB force feedback works.

## Validation follow-ups

- Finish exit and Alt+Enter checks without desktop mode changes.
- Exercise a complete race and save/reload with the public installer output.
- Expand host/display coverage and assess multiplayer separately.

Higher internal rendering resolution is outside the accepted original-image scaling objective. New media builds need their own source hashes and verified patch recipe.
