# Contributing

Open an issue with a concrete problem, reproduction steps and evidence before expanding the patch scope. Include the release, Windows version, source-executable hash, display setup and relevant runtime log. Review logs for personal paths. Do not upload original executables, media assets, icon files, full process dumps or private captures.

Build with the x86 compiler as described in [Building](docs/BUILDING.md). Keep byte checks, source hashes and fail-closed behavior when touching build-specific offsets. A new media edition needs independent analysis rather than reusing offsets blindly. The bundled renderer is also build-specific.

Preserve original art, codecs, game logic, I-Force behavior and user data. Base any fidelity claim on the original material and measured evidence. Keep compile/static checks, runtime tests and visual/hardware acceptance distinct in a contribution's validation notes. Describe which behavior changed and what remains untested.

Use a separate installation folder for development and retain the original media. Keep changes to patch sources and distributable documentation; generated game files and captures are ignored. Update the recipe, documentation and relevant evidence together. Low-priority I-Force work is deferred until its scope and test hardware are agreed.
