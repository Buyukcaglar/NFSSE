"""Append native icon resources without relocating existing game sections."""
import hashlib
import struct

import pefile


def embed_application_icon(executable, icon):
    pe = pefile.PE(data=bytes(executable))
    resource = pe.OPTIONAL_HEADER.DATA_DIRECTORY[2]
    if resource.VirtualAddress or resource.Size:
        raise ValueError("Executable already has resources; preserve them explicitly.")
    reserved, kind, count = struct.unpack_from("<HHH", icon)
    if reserved != 0 or kind != 1 or not count or len(icon) < 6 + count * 16:
        raise ValueError("Invalid ICO directory")

    images = {}
    group = bytearray(struct.pack("<HHH", 0, 1, count))
    for index in range(count):
        width, height, colors, unused, planes, bits, size, offset = struct.unpack_from(
            "<BBBBHHII", icon, 6 + index * 16)
        if offset < 6 + count * 16 or not size or offset + size > len(icon):
            raise ValueError("Invalid ICO image bounds")
        image = icon[offset:offset + size]
        # The media ICO leaves these directory fields zero. Its DIB header
        # supplies the actual planes/bit depth; keep the image bytes unchanged.
        if (not planes or not bits) and len(image) >= 16 and struct.unpack_from("<I", image)[0] >= 40:
            dib_planes, dib_bits = struct.unpack_from("<HH", image, 12)
            planes = planes or dib_planes
            bits = bits or dib_bits
        identity = index + 1
        images[identity] = {0: image}
        group.extend(struct.pack("<BBBBHHIH", width, height, colors, unused,
                                 planes, bits, size, identity))

    align = lambda value, boundary: (value + boundary - 1) & ~(boundary - 1)
    rva = align(pe.OPTIONAL_HEADER.SizeOfImage, pe.OPTIONAL_HEADER.SectionAlignment)
    raw_offset = align(len(executable), pe.OPTIONAL_HEADER.FileAlignment)
    tree = bytearray()
    payloads = []

    def reserve(size):
        offset = align(len(tree), 4)
        tree.extend(b"\0" * (offset + size - len(tree)))
        return offset

    def directory(entries):
        offset = reserve(16 + len(entries) * 8)
        struct.pack_into("<IIHHHH", tree, offset, 0, 0, 0, 0, 0, len(entries))
        for index, (identity, value) in enumerate(sorted(entries.items())):
            if isinstance(value, dict):
                target = directory(value) | 0x80000000
            else:
                target = reserve(16)
                payloads.append((target, value))
            struct.pack_into("<II", tree, offset + 16 + index * 8, identity, target)
        return offset

    assert directory({3: images, 14: {1: {0: bytes(group)}}}) == 0
    for entry, payload in payloads:
        offset = reserve(len(payload))
        tree[offset:offset + len(payload)] = payload
        struct.pack_into("<IIII", tree, entry, rva + offset, len(payload), 0, 0)

    data = bytearray(executable)
    header = pe.sections[0].get_file_offset() + pe.FILE_HEADER.NumberOfSections * 40
    if header + 40 > pe.OPTIONAL_HEADER.SizeOfHeaders or any(data[header:header + 40]):
        raise ValueError("No unused section-header space")
    raw_size = align(len(tree), pe.OPTIONAL_HEADER.FileAlignment)
    data.extend(b"\0" * (raw_offset - len(data)))
    data.extend(tree + b"\0" * (raw_size - len(tree)))
    struct.pack_into("<8sIIIIIIHHI", data, header, b".rsrc\0\0\0", len(tree), rva,
                     raw_size, raw_offset, 0, 0, 0, 0, 0x40000040)
    struct.pack_into("<H", data, pe.FILE_HEADER.get_field_absolute_offset("NumberOfSections"),
                     pe.FILE_HEADER.NumberOfSections + 1)
    for field, value in (
        ("SizeOfImage", align(rva + len(tree), pe.OPTIONAL_HEADER.SectionAlignment)),
        ("SizeOfInitializedData", pe.OPTIONAL_HEADER.SizeOfInitializedData + raw_size),
        ("CheckSum", 0),
    ):
        struct.pack_into("<I", data, pe.OPTIONAL_HEADER.get_field_absolute_offset(field), value)
    struct.pack_into("<II", data, resource.get_file_offset(), rva, len(tree))
    return data, {
        "source": "NFSICONN.ICO",
        "source_sha256": hashlib.sha256(icon).hexdigest(),
        "image_count": count,
        "group_id": 1,
        "resource_section_rva": hex(rva),
        "resource_section_raw_offset": hex(raw_offset),
        "resource_bytes": len(tree),
        "image_payloads_unchanged": True,
    }
