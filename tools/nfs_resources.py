"""Bounded SHPI/RefPack helpers for source-derived NFS SE prototype resources.

Only the 0x10FB RefPack variant is decoded. Other EA compressors are left intact.
No pixels are synthesized or resampled; archive edits reuse original entry blobs.
"""
import struct


def decode_qfs(data):
    if data[:4] == b"SHPI":
        return data
    if len(data) < 6 or data[:2] != b"\x10\xfb":
        raise ValueError("Expected SHPI or 0x10FB RefPack")
    expected = int.from_bytes(data[2:5], "big")
    if not 16 <= expected < 0x1000000:
        raise ValueError("Invalid RefPack output size")
    output = bytearray()
    pos = 5
    while True:
        if pos >= len(data):
            raise ValueError("Missing RefPack stop code")
        command = data[pos]
        pos += 1
        count = 1 if command < 0x80 else 2 if command < 0xc0 else 3 if command < 0xe0 else 0
        if pos + count > len(data):
            raise ValueError("Truncated RefPack command")
        args = data[pos:pos + count]
        pos += count
        distance = length = 0
        if command < 0x80:
            literals = command & 3
            distance = ((command & 0x60) << 3) + args[0] + 1
            length = ((command >> 2) & 7) + 3
        elif command < 0xc0:
            literals = args[0] >> 6
            distance = ((args[0] & 0x3f) << 8) + args[1] + 1
            length = (command & 0x3f) + 4
        elif command < 0xe0:
            literals = command & 3
            distance = ((command & 0x10) << 12) + (args[0] << 8) + args[1] + 1
            length = ((command & 0x0c) << 6) + args[2] + 5
        elif command < 0xfc:
            literals = ((command & 0x1f) << 2) + 4
        else:
            literals = command & 3
        if pos + literals > len(data):
            raise ValueError("Truncated RefPack literals")
        output.extend(data[pos:pos + literals])
        pos += literals
        if distance:
            if distance > len(output):
                raise ValueError("RefPack reference precedes output")
            if distance >= length:
                start = len(output) - distance
                output.extend(output[start:start + length])
            else:
                pattern = output[-distance:]
                output.extend((pattern * ((length + distance - 1) // distance))[:length])
        if len(output) > expected + 3:
            raise ValueError("RefPack output exceeds declared size")
        if command >= 0xfc:
            break
    # This media's STANDTRK includes two zero bytes in its final literal run.
    if len(output) < expected or any(output[expected:]):
        raise ValueError("RefPack output size mismatch")
    if pos != len(data):
        raise ValueError("Trailing compressed data")
    return bytes(output[:expected])


def encode_qfs(data):
    """Encode RefPack within the game's 1024-byte in-place workspace.

    The loader copies the compressed file into decoded_size + 1024 bytes,
    then moves it to the buffer's end before decoding. Literal-only encoding
    can overflow that allocation even though it round trips correctly.
    """
    if data[:4] != b"SHPI" or not 16 <= len(data) < 0x1000000:
        raise ValueError("Expected bounded SHPI data")
    encoded = bytearray(b"\x10\xfb" + len(data).to_bytes(3, "big"))
    recent = {}
    pos = literal_start = written = peak = 0

    def literals(end):
        nonlocal literal_start, written, peak
        while end - literal_start >= 4:
            size = min(112, ((end - literal_start) // 4) * 4)
            encoded.append(0xe0 + size // 4 - 1)
            encoded.extend(data[literal_start:literal_start + size])
            literal_start += size
            written += size
            peak = max(peak, written - len(encoded))

    def key(index):
        return (data[index] << 16) | (data[index + 1] << 8) | data[index + 2]

    while pos + 3 <= len(data):
        tag = key(pos)
        previous = recent.get(tag)
        distance = pos - previous if previous is not None else 0
        length = 0
        if 0 < distance <= 131072:
            limit = min(1028, len(data) - pos)
            while length < limit and data[previous + length] == data[pos + length]:
                length += 1
        usable = (length >= 5 or length >= 4 and distance <= 16384
                  or length >= 3 and distance <= 1024)
        if not usable:
            recent[tag] = pos
            pos += 1
            continue
        literals(pos)
        tail = pos - literal_start
        offset = distance - 1
        if length <= 10 and distance <= 1024:
            encoded.extend(((offset >> 8) << 5 | (length - 3) << 2 | tail, offset & 255))
        elif length <= 67 and distance <= 16384:
            encoded.extend((0x80 | length - 4, tail << 6 | offset >> 8, offset & 255))
        else:
            count = length - 5
            encoded.extend((0xc0 | (offset >> 16) << 4 | (count >> 8) << 2 | tail,
                            (offset >> 8) & 255, offset & 255, count & 255))
        encoded.extend(data[literal_start:pos])
        written += tail + length
        peak = max(peak, written - len(encoded))
        end = pos + length
        while pos < end:
            if pos + 3 <= len(data):
                recent[key(pos)] = pos
            pos += 1
        literal_start = pos
    literals(len(data))
    encoded.append(0xfc + len(data) - literal_start)
    encoded.extend(data[literal_start:])
    # Check both the initial copy and every decoding boundary. A compact file
    # can still overwrite unread input if its final literal runs expand too far.
    if len(encoded) + peak > len(data) + 1024:
        raise ValueError("RefPack exceeds legacy in-place workspace")
    return bytes(encoded)


class Archive:
    def __init__(self, data):
        data = decode_qfs(data)
        if len(data) < 16 or data[:4] != b"SHPI":
            raise ValueError("Missing SHPI header")
        size, count = struct.unpack_from("<II", data, 4)
        if size != len(data) or not 0 < count <= 4096 or 16 + count * 8 > size:
            raise ValueError("Invalid SHPI size/directory")
        rows = [struct.unpack_from("<4sI", data, 16 + n * 8) for n in range(count)]
        names = [name for name, _ in rows]
        offsets = sorted({offset for _, offset in rows})
        if len(set(names)) != count or offsets[0] < 16 + count * 8 or offsets[-1] + 4 > size:
            raise ValueError("Invalid SHPI names/offsets")
        ends = dict(zip(offsets, offsets[1:] + [size]))
        self.kind = data[12:16]
        self.order = names
        self.blobs = {name: data[offset:ends[offset]] for name, offset in rows}
        for blob in self.blobs.values():
            if blob[0] == 0x7b:
                if len(blob) < 16:
                    raise ValueError("Truncated indexed image header")
                width, height = struct.unpack_from("<HH", blob, 4)
                if width * height > len(blob) - 16:
                    raise ValueError("Truncated indexed image pixels")

    def pack(self, order=None, blobs=None):
        order = self.order if order is None else order
        blobs = self.blobs if blobs is None else blobs
        if not order or len(set(order)) != len(order) or any(len(name) != 4 for name in order):
            raise ValueError("Invalid SHPI output directory")
        offset = 16 + 8 * len(order)
        directory = bytearray()
        payload = bytearray()
        for name in order:
            directory.extend(struct.pack("<4sI", name, offset))
            payload.extend(blobs[name])
            offset += len(blobs[name])
        result = b"SHPI" + struct.pack("<II", offset, len(order)) + self.kind + directory + payload
        Archive(result)
        return result


GRAPHICS_ENGLISH_ENTRIES = (b"atld", b"atll", b"atmd", b"atml", b"320d", b"320l", b"320m")


def compatible_graphics(japanese, english):
    """Use original OPTION graphics with a byte-identical shared palette.

    English supplies its four auto-detail entries and the truthful 320x200
    labels. Every other entry blob comes unchanged from Japanese OPTION.
    """
    if japanese.blobs[b"!pal"] != english.blobs[b"!pal"]:
        raise ValueError("Graphics palettes differ; pixel index copying would change colors")
    if set(english.order) - set(japanese.order) != set(GRAPHICS_ENGLISH_ENTRIES[:4]):
        raise ValueError("Unexpected missing Japanese graphics entries")
    if set(japanese.order) - set(english.order):
        raise ValueError("Unexpected extra Japanese graphics entries")
    blobs = {name: (english.blobs[name] if name in GRAPHICS_ENGLISH_ENTRIES else japanese.blobs[name])
             for name in english.order}
    raw = japanese.pack(english.order, blobs)
    return raw


def compatible_hud(japanese, english):
    """Retain original Japanese blobs in the English engine's directory order.

    The extra low-resolution Japanese entries are omitted; no font/image pixels
    or placement metadata are changed. Existing English tag names all survive.
    """
    if set(english.order) - set(japanese.order):
        raise ValueError("Japanese HUD lacks English engine entries")
    return japanese.pack(english.order, japanese.blobs)
