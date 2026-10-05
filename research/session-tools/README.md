# Historical builder

`build_portable.py` preserves the session's original bootstrap assembly generation and local-folder construction. Its personal temporary Python-library path has been removed. It expects the old session layout (`install/`, `analysis/nfs_win/`, `portable/`) and an already-built runtime helper; it is an archive of the investigation, not the public installer entry point.

Use the root installer and `tools/package-release.ps1` for current installation and packaging. The public recipe contains the same bootstrap bytes and expected final executable hash. The active PowerShell installer adds destination/integrity checks and save/configuration preservation around that patch.
