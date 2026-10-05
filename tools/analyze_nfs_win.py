"""Read-only static PE inventory and selected xrefs for the supplied NFS_WIN.EXE.

Requires pefile and capstone. No code from the examined executable is executed.
Addresses in outputs are preferred-image VAs; file offsets are separate fields.
Linear disassembly and xrefs are leads, not a recovered function/control-flow map.
"""
import argparse
import collections
import datetime
import hashlib
import importlib.metadata
import json
import math
from pathlib import Path
import re
import struct
import sys


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("exe", type=Path)
    ap.add_argument("output", type=Path)
    ap.add_argument("--tool-path", type=Path)
    args = ap.parse_args()
    if args.tool_path:
        sys.path.insert(0, str(args.tool_path))
    import capstone
    import pefile

    data = args.exe.read_bytes()
    pe = pefile.PE(data=data)
    base = pe.OPTIONAL_HEADER.ImageBase
    args.output.mkdir(parents=True, exist_ok=True)

    def location(offset):
        section = next((s.Name.rstrip(b"\0").decode("ascii") for s in pe.sections
                        if s.PointerToRawData != 0 and
                        s.PointerToRawData <= offset < s.PointerToRawData + s.SizeOfRawData), "headers")
        return {"offset": offset, "offset_hex": hex(offset),
                "va": base + pe.get_rva_from_offset(offset), "section": section}

    sections = []
    for s in pe.sections:
        raw = data[s.PointerToRawData:s.PointerToRawData + s.SizeOfRawData] if s.PointerToRawData else b""
        counts = collections.Counter(raw)
        entropy = -sum((n / len(raw)) * math.log2(n / len(raw)) for n in counts.values()) if raw else None
        sections.append({"name": s.Name.rstrip(b"\0").decode("ascii"), "rva": s.VirtualAddress,
                         "virtual_size_field": s.Misc_VirtualSize, "raw_offset": s.PointerToRawData,
                         "raw_size_field": s.SizeOfRawData, "file_backed": bool(s.PointerToRawData),
                         "entropy_file_bytes": entropy, "characteristics": hex(s.Characteristics)})

    imports = []
    iat = {}
    for desc in getattr(pe, "DIRECTORY_ENTRY_IMPORT", []):
        dll = desc.dll.decode("ascii")
        symbols = []
        for imp in desc.imports:
            name = imp.name.decode("ascii") if imp.name else f"ordinal_{imp.ordinal}"
            symbols.append({"name": name, "ordinal": imp.ordinal, "iat_va": imp.address})
            iat[imp.address] = f"{dll}!{name}"
        imports.append({"dll": dll, "symbols": symbols})

    strings = []
    for match in re.finditer(rb"[\x20-\x7e]{4,}", data):
        strings.append({**location(match.start()), "encoding": "ascii", "text": match.group().decode("ascii")})
    for match in re.finditer(rb"(?:[\x20-\x7e]\x00){4,}", data):
        strings.append({**location(match.start()), "encoding": "utf-16le", "text": match.group().decode("utf-16le")})
    strings.sort(key=lambda s: (s["offset"], s["encoding"]))
    selected_rx = re.compile(r"CD not present|By_R&T|paths\.dat|config\.dat|nfs\.cfg|NOVIDEO|LOWVIDEO|YESSOUND|"
                             r"DirectDrawCreate|256 color|DOS IPX compatible|WINIPX|DSOUND|DPLAY|iforce|"
                             r"IPX Connection|EACLibWindow|%sea\.tgv|%sattract%d\.tgv|%stitle\.tgv|"
                             r"DirectX FAILED|WATCOM|GetProcAddress|GetDriveType|WSAStartup|Version|WIN95", re.I)
    selected = [s for s in strings if selected_rx.search(s["text"])]
    targets = {s["va"] for s in selected}
    targets.update(iat)

    md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_32)
    md.skipdata = True
    xrefs = collections.defaultdict(list)
    edges = collections.defaultdict(list)
    thunks = {}
    instruction_count = 0
    for s in pe.sections:
        if not (s.Characteristics & 0x20000000) or not s.PointerToRawData:
            continue
        raw = data[s.PointerToRawData:s.PointerToRawData+s.SizeOfRawData]
        for va, size, mnemonic, ops in md.disasm_lite(raw, base+s.VirtualAddress):
            instruction_count += 1
            nums = set(int(x, 16) for x in re.findall(r"0x([0-9a-f]+)", ops))
            offset = va-base-s.VirtualAddress+s.PointerToRawData
            row = {"va": va, "offset": offset, "bytes": data[offset:offset+size].hex(" "),
                   "mnemonic": mnemonic, "operands": ops}
            for value in nums & targets:
                xrefs[value].append(row)
            if (mnemonic == "call" or mnemonic.startswith("j")) and re.fullmatch(r"0x[0-9a-f]+", ops):
                edges[int(ops, 16)].append(row)
            if mnemonic == "jmp" and ops.startswith("dword ptr [0x"):
                value = next(iter(nums), None)
                if value in iat:
                    thunks[va] = iat[value]

    selected_rows = [{**s, "code_xrefs": xrefs[s["va"]]} for s in selected]
    callsites = []
    for address, name in sorted(iat.items()):
        row = {"symbol": name, "iat_va": address, "direct_iat_xrefs": xrefs[address], "thunks": []}
        for thunk, symbol in thunks.items():
            if symbol == name:
                row["thunks"].append({"va": thunk, "callers": edges[thunk]})
        callsites.append(row)

    overlay = pe.get_overlay_data_start_offset()
    summary = {
        "input": str(args.exe.resolve()), "analysis_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "size_bytes": len(data), "sha256": hashlib.sha256(data).hexdigest(),
        "coff_timestamp_raw": pe.FILE_HEADER.TimeDateStamp,
        "coff_timestamp_utc": datetime.datetime.fromtimestamp(pe.FILE_HEADER.TimeDateStamp, datetime.timezone.utc).isoformat(),
        "machine": hex(pe.FILE_HEADER.Machine), "optional_magic": hex(pe.OPTIONAL_HEADER.Magic),
        "subsystem": pe.OPTIONAL_HEADER.Subsystem, "image_base": base,
        "entrypoint_rva": pe.OPTIONAL_HEADER.AddressOfEntryPoint,
        "entrypoint_va": base+pe.OPTIONAL_HEADER.AddressOfEntryPoint,
        "entrypoint_offset": pe.get_offset_from_rva(pe.OPTIONAL_HEADER.AddressOfEntryPoint),
        "size_of_image": pe.OPTIONAL_HEADER.SizeOfImage,
        "linker_version": [pe.OPTIONAL_HEADER.MajorLinkerVersion, pe.OPTIONAL_HEADER.MinorLinkerVersion],
        "subsystem_version": [pe.OPTIONAL_HEADER.MajorSubsystemVersion, pe.OPTIONAL_HEADER.MinorSubsystemVersion],
        "os_version_field": [pe.OPTIONAL_HEADER.MajorOperatingSystemVersion, pe.OPTIONAL_HEADER.MinorOperatingSystemVersion],
        "stack_reserve": pe.OPTIONAL_HEADER.SizeOfStackReserve, "stack_commit": pe.OPTIONAL_HEADER.SizeOfStackCommit,
        "heap_reserve": pe.OPTIONAL_HEADER.SizeOfHeapReserve, "heap_commit": pe.OPTIONAL_HEADER.SizeOfHeapCommit,
        "coff_characteristics": hex(pe.FILE_HEADER.Characteristics), "dll_characteristics": hex(pe.OPTIONAL_HEADER.DllCharacteristics),
        "coff_symbol_count": pe.FILE_HEADER.NumberOfSymbols,
        "directories": [{"name": d.name, "rva": d.VirtualAddress, "size": d.Size} for d in pe.OPTIONAL_HEADER.DATA_DIRECTORY],
        "sections": sections, "overlay_offset": overlay, "overlay_size": len(data)-overlay if overlay else 0,
        "imports": imports, "import_descriptor_count": len(imports),
        "distinct_import_dlls": sorted({d["dll"].lower() for d in imports}), "import_slot_count": len(iat),
        "base_relocation_blocks": len(getattr(pe, "DIRECTORY_ENTRY_BASERELOC", [])),
        "base_relocation_entries": dict(collections.Counter(e.type for block in getattr(pe, "DIRECTORY_ENTRY_BASERELOC", []) for e in block.entries)),
        "parser_warnings": pe.get_warnings(), "strings_count": len(strings),
        "linear_disassembly_instruction_count": instruction_count,
        "tools": {"python": sys.version, "pefile": importlib.metadata.version("pefile"), "capstone": capstone.__version__},
        "limits": ["Static examination only; target executable was not run.",
                   "Linear xrefs may include embedded code data or missed instruction boundaries; validate local disassembly.",
                   "PE header timestamp and flags do not establish provenance or authenticity.",
                   "No reference clean executable or signature-based malware scan was supplied."]}
    for filename, obj in (("pe_inventory.json", summary), ("selected_strings_xrefs.json", selected_rows), ("import_callsites.json", callsites)):
        (args.output / filename).write_text(json.dumps(obj, indent=2), encoding="utf-8")
    (args.output / "strings.txt").write_text("\n".join(f"FILE {s['offset']:08x}  VA {s['va']:08x}  {s['section']:8}  {s['encoding']:8}  {s['text']}" for s in strings)+"\n", encoding="utf-8")
    (args.output / "imports.txt").write_text("\n".join(f"{d['dll']} ({len(d['symbols'])} slots)\n"+"\n".join(f"  {s['iat_va']:08x} {s['name']}" for s in d["symbols"]) for d in imports)+"\n", encoding="utf-8")
    # These ranges were locally checked at instruction boundaries for this hash.
    # They are intentionally hash-specific; do not reuse them for another build.
    if summary["sha256"] == "ac72e59587b66f9a3bb2bdb83fa40b8eaac2d68a5ae47a041b026922f8d2594b":
        ranges = [
            ("Entry jump", 0x48c802, 0x48c807),
            ("Watcom startup", 0x4a2282, 0x4a22c8),
            ("nfs.cfg parser", 0x432144, 0x4322f8),
            ("paths.dat loader and CD gates", 0x42a188, 0x42a483),
            ("title.tgv presence gate and CD errors", 0x43264f, 0x4326d2),
            ("By_R&T writeability check", 0x44028c, 0x440349),
            ("fopen-style runtime helper", 0x482195, 0x4821d8),
            ("mode parser", 0x482000, 0x4820d1),
            ("fwrite-style runtime helper", 0x48d5b2, 0x48d794),
            ("CD drive-letter wrapper", 0x4673ac, 0x4673cd),
            ("GetDriveTypeA wrapper", 0x471f20, 0x471f38),
            ("DirectDraw hardware then emulation attempts", 0x47ca75, 0x47cb41),
            ("IPX datagram socket arguments", 0x481698, 0x4816a6),
            ("Additional IPX socket helper", 0x49e390, 0x49e450),
            ("Runtime dynamic USER32 lookup", 0x4a6d32, 0x4a6d5c),
            ("Byte-writing software graphics routine", 0x48c89a, 0x48c908),
            ("File-presence helper", 0x4886e0, 0x488723),
            ("Generic file-open wrapper", 0x488428, 0x48844b),
            ("Termination callback", 0x487b70, 0x487b77),
            ("Runtime exit cleanup", 0x49b39f, 0x49b3dc),
            ("Runtime ExitProcess path", 0x49ef35, 0x49ef54),
        ]
        excerpt_lines = ["Static x86 excerpts; VA uses image base 0x00400000.",
                         "FILE offsets refer to the original executable.",
                         "Labels are analyst descriptions, not recovered symbols.", ""]
        for label, start, end in ranges:
            excerpt_lines.append(f"; {label}: VA 0x{start:08X} to 0x{end:08X} (end exclusive)")
            for va, size, mnemonic, ops in md.disasm_lite(pe.get_data(start-base, end-start), start):
                off = pe.get_offset_from_rva(va-base)
                excerpt_lines.append(f"FILE {off:08X}  VA {va:08X}  {data[off:off+size].hex(' '):28} {mnemonic:8} {ops}")
            excerpt_lines.append("")
        (args.output / "verified_excerpts.asm").write_text("\n".join(excerpt_lines), encoding="utf-8")

        support = {"iforce_imported_exports_all_present": None, "directplay_ordinal_resolution": [],
                   "related_files": [], "asset_folders": [], "configuration_files": {},
                   "copy_check_marker": {}}
        sibling = args.exe.parent
        for filename in ("IFORCE.DLL", "NFS_DOS.EXE", "INSTALLW.EXE", "INFSW.EXE", "README.TXT", "GATEWAY/Gateway.cfg"):
            path = sibling / filename
            if path.is_file():
                contents = path.read_bytes()
                support["related_files"].append({"path": str(path.resolve()), "size": len(contents),
                                                 "sha256": hashlib.sha256(contents).hexdigest()})
        if (sibling / "IFORCE.DLL").is_file():
            force = pefile.PE(str(sibling / "IFORCE.DLL"))
            exports = {x.name.decode("ascii") for x in force.DIRECTORY_ENTRY_EXPORT.symbols if x.name}
            requested = {s["name"] for d in imports if d["dll"].lower() == "iforce.dll" for s in d["symbols"]}
            support["iforce_imported_exports_all_present"] = requested <= exports
            support["iforce_dependencies"] = [d.dll.decode("ascii") for d in force.DIRECTORY_ENTRY_IMPORT]
        for relative in ("REDIST/DIRECTX/DPLAY.DLL", "DIRECTX3/DIRECTX/DPLAY.DLL"):
            path = sibling / relative
            if path.is_file():
                dp = pefile.PE(str(path))
                support["directplay_ordinal_resolution"].append({"path": str(path.resolve()),
                    "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                    "exports": [{"ordinal": s.ordinal, "name": s.name.decode("ascii") if s.name else None}
                                for s in dp.DIRECTORY_ENTRY_EXPORT.symbols if s.ordinal in (1, 2)]})
        for folder in ("FRONTEND", "GAMEDATA", "SIMDATA"):
            files = [path for path in (sibling / folder).rglob("*") if path.is_file()]
            support["asset_folders"].append({"folder": folder, "files": len(files),
                "bytes": sum(path.stat().st_size for path in files),
                "extensions": dict(collections.Counter(path.suffix.upper() for path in files))})
        for relative in ("gamedata/config/paths.dat", "nfs.cfg", "gamedata/config/config.dat"):
            path = sibling / relative
            support["configuration_files"][relative] = {"exists": path.is_file(), "path": str(path.resolve())}
        marker = sibling / "SIMDATA/CARSPECS/BY_R&T"
        if marker.is_file():
            contents = marker.read_bytes()
            support["copy_check_marker"] = {"path": str(marker.resolve()), "size": len(contents),
                "sha256": hashlib.sha256(contents).hexdigest(), "bytes_hex": contents.hex(" ")}
        (args.output / "supporting_files.json").write_text(json.dumps(support, indent=2), encoding="utf-8")
    print(json.dumps({k:summary[k] for k in ("sha256", "size_bytes", "coff_timestamp_utc", "entrypoint_va", "entrypoint_offset", "distinct_import_dlls", "import_slot_count", "overlay_size", "parser_warnings", "linear_disassembly_instruction_count")}, indent=2))
    for s in selected_rows:
        if s["section"] in ("DGROUP", "BEGTEXT"):
            print(f"{s['offset']:08x} VA {s['va']:08x} {s['text'][:150]}")
            for x in s["code_xrefs"]:
                print(f"  FILE {x['offset']:08x} VA {x['va']:08x} {x['mnemonic']} {x['operands']}")


if __name__ == "__main__":
    main()
