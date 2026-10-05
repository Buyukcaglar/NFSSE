"""Build a separate local-assets NFS SE Windows copy from the exact media hash."""
import hashlib
import json
from pathlib import Path
import shutil
import stat
import struct
import sys

# Install pefile in your Python environment; original temporary tool path omitted.
import pefile
from icon_resources import embed_application_icon

root = Path(__file__).resolve().parents[3]
media = root / "install"
out = root / "portable"
source = (media / "NFS_WIN.EXE").read_bytes()
expected = "ac72e59587b66f9a3bb2bdb83fa40b8eaac2d68a5ae47a041b026922f8d2594b"
assert hashlib.sha256(source).hexdigest() == expected
out.mkdir(exist_ok=True)
for folder in ("FRONTEND", "GAMEDATA", "SIMDATA"):
    # Merge missing media files only; preserve generated paths and later saves.
    for asset in (media / folder).rglob("*"):
        destination = out / asset.relative_to(media)
        if asset.is_dir():
            destination.mkdir(parents=True, exist_ok=True)
        elif not destination.exists():
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(asset, destination)
            if folder == "GAMEDATA":
                destination.chmod(destination.stat().st_mode | stat.S_IWRITE)
for filename in ("IFORCE.DLL", "NFSICONN.ICO"):
    destination = out / filename
    if not destination.exists():
        shutil.copy2(media / filename, destination)
shutil.copy2(media / "REDIST/DIRECTX/DPLAY.DLL", out / "DPLAY.dll")
for filename in ("DPWSOCK.DLL", "DPSERIAL.DLL"):
    shutil.copy2(media / "REDIST/DIRECTX" / filename, out / filename)
for filename in ("DPWSOCKX.DLL", "DPMODEMX.DLL", "DPLAYX.DLL"):
    shutil.copy2(media / "DIRECTX3/DIRECTX" / filename, out / filename)

data = bytearray(source)
patches = []
def patch(offset, before, after, purpose):
    assert data[offset:offset+len(before)] == before, (hex(offset), data[offset:offset+len(before)].hex())
    assert len(before) == len(after)
    data[offset:offset+len(after)] = after
    patches.append({"file_offset": hex(offset), "original": before.hex(" "), "patched": after.hex(" "), "purpose": purpose})

# Skip physical-CD identity checks, while keeping local asset opening and errors.
patch(0x29825, bytes.fromhex("66 83 3d 1e b3 52 00 00"), bytes.fromhex("e9 4c 00 00 00 90 90 90"),
      "Jump from loaded path table to completion; remove CD drive-type/access gates.")
# Skip the entire writeability probe; changing only the filename would still write.
patch(0x3f68c, bytes.fromhex("66 83 3d cc 5c 4c 00 00"), bytes.fromhex("e9 b8 00 00 00 90 90 90"),
      "Bypass By_R&T creation and car-field sabotage; continue at original post-check code.")

pe = pefile.PE(data=source)
align = lambda n, a: (n + a - 1) & ~(a - 1)
raw_offset = align(len(data), pe.OPTIONAL_HEADER.FileAlignment)
rva = align(pe.OPTIONAL_HEADER.SizeOfImage, pe.OPTIONAL_HEADER.SectionAlignment)
entry = bytearray(b"\x9c\x60")  # pushfd; pushad
entry += b"\xe8\0\0\0\0\x5b"  # position-independent image base in EBX
entry += b"\x81\xeb" + struct.pack("<I", rva + 7)
fixups = []
def lea_string(label):
    entry.extend(b"\x8d\x83")
    fixups.append((len(entry), label))
    entry.extend(b"\0" * 4)
def call_iat(import_rva):
    entry.extend(b"\xff\x93" + struct.pack("<I", import_rva))
def jz_failure():
    entry.extend(b"\x0f\x84")
    fixups.append((len(entry), "rel_fail"))
    entry.extend(b"\0" * 4)

lea_string("dll"); entry += b"\x50"; call_iat(0x131564)
entry += b"\x85\xc0"; jz_failure()
entry += b"\x89\xc6"
lea_string("initialize"); entry += b"\x50\x56"; call_iat(0x131554)
entry += b"\x85\xc0"; jz_failure()
entry += b"\xff\xd0\x85\xc0"; jz_failure()
entry += b"\x61\x9d\xe9"
entry += struct.pack("<i", pe.OPTIONAL_HEADER.AddressOfEntryPoint - (rva + len(entry) + 4))
labels = {"rel_fail": len(entry)}
entry += b"\x6a\x10"
lea_string("title"); entry += b"\x50"
lea_string("error"); entry += b"\x50\x6a\0"; call_iat(0x1311d8)
entry += b"\x6a\x01"; call_iat(0x131514)
for name, text in (("dll", "NFSPortable.dll"), ("initialize", "Initialize"),
                   ("title", "NFS SE Portable"), ("error", "Portable compatibility initialization failed. Keep NFSPortable.dll beside NFSSE.exe and check portable-runtime.log.")):
    labels[name] = len(entry)
    entry += text.encode("ascii") + b"\0"
for offset, label in fixups:
    if label == "rel_fail":
        struct.pack_into("<i", entry, offset, labels[label]-(offset+4))
    else:
        struct.pack_into("<I", entry, offset, rva+labels[label])
raw_size = align(len(entry), pe.OPTIONAL_HEADER.FileAlignment)
data.extend(b"\0" * (raw_offset-len(data)))
data.extend(entry + b"\0" * (raw_size-len(entry)))
section_header = pe.sections[0].get_file_offset() + 40*pe.FILE_HEADER.NumberOfSections
assert not any(source[section_header:section_header+40])
struct.pack_into("<8sIIIIIIHHI", data, section_header, b".nfspat\0", len(entry), rva,
                 raw_size, raw_offset, 0, 0, 0, 0, 0x60000020)
struct.pack_into("<H", data, pe.FILE_HEADER.get_field_absolute_offset("NumberOfSections"), pe.FILE_HEADER.NumberOfSections+1)
for field, value in (("AddressOfEntryPoint", rva), ("SizeOfImage", align(rva+len(entry), pe.OPTIONAL_HEADER.SectionAlignment)),
                     ("SizeOfCode", pe.OPTIONAL_HEADER.SizeOfCode+raw_size), ("CheckSum", 0)):
    struct.pack_into("<I", data, pe.OPTIONAL_HEADER.get_field_absolute_offset(field), value)

data, embedded_icon = embed_application_icon(data, (media / "NFSICONN.ICO").read_bytes())
(out / "NFSSE.exe").write_bytes(data)
paths_map = json.loads((root / "analysis/nfs_win/portable_paths_map.json").read_text())
paths = bytearray(1520)
for row in paths_map:
    value = row["path"].encode("ascii") + b"\0"
    assert len(value) <= 80
    paths[row["index"]*80:row["index"]*80+len(value)] = value
    (out / row["path"]).mkdir(parents=True, exist_ok=True)
(out / "GAMEDATA/CONFIG/PATHS.DAT").write_bytes(paths)
if not (out / "nfs.cfg").exists():
    # Space-terminated tokens match the original fixed-line parser.
    (out / "nfs.cfg").write_bytes(b"YESSOUND HIGHVIDEO ENGLISH NOREMOTE \r\n")
shutil.copy2(root / "analysis/nfs_win/third_party/cnc-ddraw-v7.1.0.0/ddraw.dll", out / "ddraw.dll")
shutil.copy2(Path(__file__).with_name("ddraw.ini"), out / "ddraw.ini")
(out / "Run-NFS.cmd").write_text("@echo off\nsetlocal\npushd \"%~dp0\"\nstart \"\" /wait \"NFSSE.exe\"\npopd\nendlocal\n", encoding="ascii")
license_path = root / "analysis/nfs_win/third_party/cnc-ddraw-LICENSE.txt"
if license_path.exists(): shutil.copy2(license_path, out / "cnc-ddraw-LICENSE.txt")
manifest = {"source_executable": str((media / "NFS_WIN.EXE").resolve()), "source_sha256": expected,
    "portable_executable": str((out / "NFSSE.exe").resolve()), "patched_sha256": hashlib.sha256(data).hexdigest(),
    "patches": patches, "application_icon": embedded_icon, "new_section": {"rva": hex(rva), "raw_offset": hex(raw_offset), "size": len(entry),
    "purpose": "Load NFSPortable.dll before original runtime entry; position-independent trampoline."},
    "relative_paths": paths_map, "graphics_wrapper": {"name": "cnc-ddraw", "version": "7.1.0.0", "renderer": "GDI", "surface_locking": True, "minimum_redraw_fps": 5, "single_cpu": True, "borderless": True,
    "source": "https://github.com/FunkyFr3sh/cnc-ddraw/releases/tag/v7.1.0.0",
    "dll_sha256": hashlib.sha256((out / "ddraw.dll").read_bytes()).hexdigest()},
    "runtime_helper": {"name": "NFSPortable.dll", "sha256": hashlib.sha256((out / "NFSPortable.dll").read_bytes()).hexdigest(),
        "source": "analysis/nfs_win/portable/NFSPortable.cpp",
        "patches": ["Executable-relative working directory for all 19 relative PATHS.DAT entries",
            "Relocate five verified legacy VGA scratch references to allocated RAM",
            "Remove two privileged CLI/STI instructions from standalone interrupt helpers",
            "Bound RAM reporting for signed 32-bit game comparisons",
            "Keep initial logical window dimensions at 640x480",
            "Synchronize graphics initialization before proceeding on the main thread",
            "Use buffered file access for legacy streams while preserving overlapped flags",
            "Load bundled DirectPlay providers by absolute paths under the executable folder",
            "Make movie keyframe flips and palette changes atomic with the verified bundled renderer"]},
    "retained_iforce_sha256": hashlib.sha256((out / "IFORCE.DLL").read_bytes()).hexdigest(),
    "runtime_verification": "See VALIDATION.txt beside the executable for bounded live test results."}
for filename in ("README.txt", "VALIDATION.txt"):
    source_document = Path(__file__).with_name(filename)
    if source_document.exists(): shutil.copy2(source_document, out / filename)
(out / "patch-manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
print(json.dumps({"folder": str(out), "patched_sha256": manifest["patched_sha256"], "patches": patches, "startup_rva": hex(rva)}, indent=2))
