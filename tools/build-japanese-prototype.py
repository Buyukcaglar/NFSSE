"""Build an isolated selectable Japanese resource prototype from user media.

Uses Python's standard library only. Never launches the game or patches its
executable/helper. Original installation and both media folders are read-only.
"""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import uuid

from nfs_resources import Archive, compatible_graphics, compatible_hud, encode_qfs, decode_qfs

ROOT = Path(__file__).resolve().parent.parent


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def checked_file(root, relative):
    path = (root / relative).resolve()
    if not path.is_relative_to(root) or not path.is_file():
        raise ValueError(f"Missing or escaping input file: {relative}")
    return path


def verify(root, relative, expected):
    path = checked_file(root, relative)
    if digest(path) != expected:
        raise ValueError(f"Unsupported/modified input: {relative}")
    return path


def path_table(recipe, profile, japanese):
    values = {row["index"]: row["path"] for row in recipe["paths"]}
    if sorted(values) != list(range(19)):
        raise ValueError("Expected nineteen path records")
    if japanese:
        for tree in profile["trees"]:
            for index in tree["path_records"]:
                values[index] = tree["target"].lower() + "/"
    result = bytearray(1520)
    for index, value in values.items():
        if ".." in value or value.startswith(("/", "\\")) or ":" in value:
            raise ValueError("Unsafe resource path")
        data = value.encode("ascii")
        if len(data) >= 80:
            raise ValueError("Resource path exceeds legacy record")
        result[index * 80:index * 80 + len(data)] = data
    return bytes(result)


def copy_file(source, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)
    target.chmod(target.stat().st_mode | stat.S_IWRITE)


def write_launcher(stage, filename, arguments):
    text = ('@echo off\r\n' +
            '"%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" '
            '-NoProfile -ExecutionPolicy Bypass -File "%~dp0Select-Language.ps1" ' + arguments + '\r\n' +
            'if errorlevel 1 pause\r\n')
    (stage / filename).write_bytes(text.encode("ascii"))


def build(args):
    base = args.base_game.resolve()
    english = args.english_media.resolve()
    japanese = args.japanese_media.resolve()
    destination = args.destination.resolve()
    profile = json.loads((ROOT / "config/japanese-resource-profile.json").read_text())
    recipe = json.loads((ROOT / "config/patch-recipe.json").read_text())
    if destination.exists():
        raise ValueError("Destination already exists; choose a fresh prototype folder")
    for source in (base, english, japanese):
        if destination.is_relative_to(source) or source.is_relative_to(destination):
            raise ValueError("Prototype destination overlaps an input folder")
    for name, expected in profile["runtime_sha256"].items():
        verify(base, name, expected)
    verify(english, recipe["source_executable"], recipe["source_sha256"])
    verify(japanese, "NFS.EXE", profile["japanese_executable_sha256"])
    for relative, expected in profile["english_resource_sha256"].items():
        verify(english, relative, expected)
    for item in profile["files"]:
        verify(japanese, item["path"], item["sha256"])
    for number in range(1, 4):
        if digest(japanese / f"FRONTEND/MOVIE/GCOP{number}.TGV") != digest(japanese / f"FRONTEND/MOVIE/COP{number}.TGV"):
            raise ValueError("Police movie identity changed; reassess language routing")
    en_paths = path_table(recipe, profile, False)
    ja_paths = path_table(recipe, profile, True)
    if checked_file(base, "GAMEDATA/CONFIG/PATHS.DAT").read_bytes() != en_paths:
        raise ValueError("Base game uses custom resource paths; choose the verified English installation")
    tokens = checked_file(base, "nfs.cfg").read_bytes().decode("ascii").split()
    if len(tokens) != 4 or tokens[2] != "ENGLISH":
        raise ValueError("Base nfs.cfg must use the English engine branch")
    snapshot = {}
    for path in base.rglob("*"):
        if path.is_symlink():
            raise ValueError("Base game contains a link; use a self-contained installation")
        if path.is_file():
            snapshot[path.relative_to(base).as_posix()] = digest(path)
    for name in recipe["race_speech_files"]:
        verify(base, name, digest(english / "FRONTEND/SPEECH" / name))

    stage = destination.with_name(destination.name + ".staging-" + uuid.uuid4().hex)
    destination.parent.mkdir(parents=True, exist_ok=True)
    try:
        shutil.copytree(base, stage, copy_function=shutil.copy2)
        for path in stage.rglob("*"):
            if path.is_file():
                path.chmod(path.stat().st_mode | stat.S_IWRITE)
        for item in profile["files"]:
            copy_file(japanese / item["path"], stage / item["target"])

        # Use the original Japanese OPTION screen for both menu contexts. Its
        # palette exactly matches English OPTION, allowing unchanged entry blobs
        # to coexist. The Japanese CHECK palette differs and is never remapped.
        jp_graphics = Archive((japanese / "FRONTEND/ART/OPTION/GRAPHICS.QFS").read_bytes())
        en_graphics = Archive((english / "FRONTEND/ART/OPTION/GRAPHICS.QFS").read_bytes())
        graphics = Archive(compatible_graphics(jp_graphics, en_graphics))
        edits = []
        for folder in ("OPTION", "CHECK"):
            order = Archive((english / f"FRONTEND/ART/{folder}/GRAPHICS.QFS").read_bytes()).order
            raw = graphics.pack(order)
            encoded = encode_qfs(raw)
            if decode_qfs(encoded) != raw:
                raise ValueError("Graphics RefPack round trip failed")
            for suffix, data in ((".FSH", raw), (".QFS", encoded)):
                (stage / f"LANG/JA/ART/{folder}/GRAPHICS{suffix}").write_bytes(data)
            edits.append({"target": f"LANG/JA/ART/{folder}/GRAPHICS",
                          "japanese_source": "FRONTEND/ART/OPTION/GRAPHICS.QFS",
                          "english_source": "FRONTEND/ART/OPTION/GRAPHICS.QFS",
                          "restored_entries": ["atld", "atll", "atmd", "atml"],
                          "resolution_entries": ["320d", "320l", "320m"],
                          "pixel_or_palette_conversion": False,
                          "entries": len(order)})
        for name in ("MASKHI.FSH", "MASKLO.FSH"):
            source = Archive((japanese / "SIMDATA/MISC" / name).read_bytes())
            original = Archive((english / "SIMDATA/MISC" / name).read_bytes())
            raw = compatible_hud(source, original)
            (stage / "LANG/JA/MISC" / name).write_bytes(raw)
            edits.append({"target": f"LANG/JA/MISC/{name}", "entries": len(original.order),
                          "omitted_japanese_extra_entries": len(set(source.order) - set(original.order)),
                          "pixel_or_placement_changes": False,
                          "directory_order": "English engine"})

        (stage / "LANG").mkdir(exist_ok=True)
        (stage / "LANG/English.paths").write_bytes(en_paths)
        (stage / "LANG/Japanese.paths").write_bytes(ja_paths)
        resource_files = [{"path": path.relative_to(stage).as_posix(), "sha256": digest(path)}
                          for path in sorted((stage / "LANG/JA").rglob("*")) if path.is_file()]
        runtime = [{"path": name, "sha256": value} for name, value in profile["runtime_sha256"].items()]
        manifest = {"schema": 1, "profile": profile["id"], "experimental": True,
                    "created_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
                    "runtime_files": runtime, "resource_files": resource_files,
                    "languages": [
                        {"name": "English", "path_table": "LANG/English.paths", "sha256": hashlib.sha256(en_paths).hexdigest()},
                        {"name": "Japanese", "path_table": "LANG/Japanese.paths", "sha256": hashlib.sha256(ja_paths).hexdigest()}],
                    "resource_edits": edits, "police_movie_remapping": "unnecessary: COP and GCOP originals are identical",
                    "source_input_files": len(profile["files"]), "game_launched": False}
        (stage / "japanese-prototype.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        (stage / "base-game-snapshot.json").write_text(json.dumps(snapshot, indent=2) + "\n", encoding="utf-8")
        copy_file(ROOT / "tools/Select-PrototypeLanguage.ps1", stage / "Select-Language.ps1")
        copy_file(ROOT / "docs/JAPANESE_PROTOTYPE.md", stage / "JAPANESE_PROTOTYPE.md")
        write_launcher(stage, "Play-Japanese.cmd", "-Language Japanese -Launch")
        write_launcher(stage, "Play-English.cmd", "-Language English -Launch")
        write_launcher(stage, "Select-Language.cmd", "")
        # Fail without exposing a half-completed prototype if selector validation
        # or source-preservation checks fail. The staging folder remains recoverable.
        powershell = Path(os.environ["SystemRoot"]) / "System32/WindowsPowerShell/v1.0/powershell.exe"
        subprocess.run([str(powershell), "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
                        str(stage / "Select-Language.ps1"), "-Language", "Japanese"], check=True)
        for relative, expected in snapshot.items():
            verify(base, relative, expected)
        stage.rename(destination)
    except Exception:
        print(f"Incomplete build retained for diagnosis: {stage}")
        raise
    print(f"Created Japanese prototype: {destination}")
    print("Use Play-Japanese.cmd or Play-English.cmd. No game was launched.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-game", type=Path, default=ROOT / "NFSSE")
    parser.add_argument("--english-media", type=Path, default=ROOT / "install")
    parser.add_argument("--japanese-media", type=Path, default=ROOT / "japanese")
    parser.add_argument("--destination", type=Path, default=ROOT / "build/japanese-prototype")
    try:
        build(parser.parse_args())
    except (ValueError, OSError, subprocess.CalledProcessError) as exc:
        parser.exit(1, f"Prototype build failed: {exc}\n")


if __name__ == "__main__":
    main()
