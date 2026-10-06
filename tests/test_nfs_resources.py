import struct
import random
import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from nfs_resources import Archive, GRAPHICS_ENGLISH_ENTRIES, compatible_graphics, compatible_hud, decode_qfs, encode_qfs


def image(color, anchor=0):
    return struct.pack("<I6H", 0x7b, 4, 1, anchor, 0, 0, 0) + bytes([color]) * 4


def archive(blobs):
    offset = 16 + len(blobs) * 8
    directory = bytearray()
    payload = bytearray()
    for name, blob in blobs.items():
        directory.extend(struct.pack("<4sI", name, offset))
        payload.extend(blob)
        offset += len(blob)
    return Archive(b"SHPI" + struct.pack("<II", offset, len(blobs)) + b"LN32" + directory + payload)


class ResourcesTests(unittest.TestCase):
    def test_literal_encoding_handles_every_tail_length(self):
        for size in (16, 17, 18, 19, 111, 112, 113, 114, 115, 1027):
            raw = b"SHPI" + bytes((n % 256 for n in range(size - 4)))
            self.assertEqual(decode_qfs(encode_qfs(raw)), raw)

    def test_each_reference_command_and_overlapping_copy(self):
        initial = b"SHPI" + b"a" * 12
        for command, count in ((b"\x00\x00", 3), (b"\x80\x00\x00", 4), (b"\xc0\x00\x00\x00", 5)):
            expected = initial + b"a" * count
            stream = b"\x10\xfb" + len(expected).to_bytes(3, "big") + b"\xe3" + initial + command + b"\xfc"
            self.assertEqual(decode_qfs(stream), expected)

    def test_large_screen_encoding_fits_the_legacy_loader(self):
        raw = b"SHPI" + bytes(n % 256 for n in range(502848))
        # The old literal-only file exceeds decoded_size + 1024, matching
        # the user's 503876-byte corrupted graphics block.
        old_size = 5 + len(raw) + (len(raw) // 112) + 1
        self.assertGreater(old_size, len(raw) + 1024)
        encoded = encode_qfs(raw)
        self.assertLess(len(encoded), len(raw))
        capacity = len(raw) + 1024
        buffer = bytearray(capacity)
        buffer[capacity - len(encoded):] = encoded
        # Decode directly from the same staging buffer the game uses. Check
        # unread input after each byte rather than using a separate decoder.
        source, target = capacity - len(encoded) + 5, 0
        while True:
            command = buffer[source]; source += 1
            count = 1 if command < 0x80 else 2 if command < 0xc0 else 3 if command < 0xe0 else 0
            args = buffer[source:source + count]; source += count
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
            else:
                literals = ((command & 0x1f) << 2) + 4 if command < 0xfc else command & 3
            for _ in range(literals):
                value = buffer[source]; source += 1
                self.assertLess(target, source)
                buffer[target] = value; target += 1
            for _ in range(length):
                self.assertLess(target, source)
                buffer[target] = buffer[target - distance]; target += 1
            if command >= 0xfc:
                break
        self.assertEqual(target, len(raw))
        self.assertEqual(source, capacity)
        self.assertEqual(buffer[:target], raw)

    def test_incompressible_tail_cannot_overwrite_unread_input(self):
        rng = random.Random(1234)
        tail = rng.randbytes(200000)
        # Initial compressible pixels make the total file small, but a large
        # incompressible suffix still needs more than the loader's workspace.
        for raw in (b"SHPI" + tail, b"SHPI" + bytes(200000) + tail):
            with self.assertRaisesRegex(ValueError, 'in-place workspace'):
                encode_qfs(raw)

    def test_malformed_compression_is_rejected(self):
        for stream in (b"\x10\xfb\x00\x00\x10\x00\x00\xfc",
                       b"\x10\xfb\x00\x00\x10\xe3short",
                       b"\x10\xfb\x00\x00\x10\xc0"):
            with self.assertRaises(ValueError):
                decode_qfs(stream)
        raw = b"SHPI" + b"x" * 12
        with self.assertRaises(ValueError):
            decode_qfs(encode_qfs(raw) + b"junk")

    def test_directory_offsets_and_image_extents_are_bounded(self):
        original = archive({b"bgnd": image(1)})
        raw = bytearray(original.pack())
        struct.pack_into("<I", raw, 20, 0)
        with self.assertRaises(ValueError):
            Archive(raw)
        with self.assertRaises(ValueError):
            archive({b"bgnd": image(1)[:-1]})

    def test_graphics_restores_controls_without_changing_other_blobs(self):
        palette = struct.pack("<I6H", 0x22, 256, 3, 256, 0, 0, 0) + bytes(768)
        english = archive({b"!pal": palette, b"bgnd": image(1),
                           **{tag: image(n + 2) for n, tag in enumerate(GRAPHICS_ENGLISH_ENTRIES)}})
        japanese = archive({b"bgnd": image(12), b"!pal": palette,
                            **{tag: image(13) for tag in GRAPHICS_ENGLISH_ENTRIES[4:]}})
        result = Archive(compatible_graphics(japanese, english))
        self.assertEqual(result.order, english.order)
        self.assertEqual(result.blobs[b"bgnd"], japanese.blobs[b"bgnd"])
        self.assertEqual(result.blobs[b"!pal"], palette)
        for tag in GRAPHICS_ENGLISH_ENTRIES:
            self.assertEqual(result.blobs[tag], english.blobs[tag])
        japanese.blobs[b"!pal"] = palette[:-1] + b"\x01"
        with self.assertRaises(ValueError):
            compatible_graphics(japanese, english)

    def test_hud_keeps_requested_pixels_and_placement_in_original_order(self):
        english = archive({b"one ": image(1), b"two ": image(2)})
        japanese = archive({b"two ": image(5, 22), b"more": image(9), b"one ": image(4, 12)})
        result = Archive(compatible_hud(japanese, english))
        self.assertEqual(result.order, english.order)
        self.assertEqual(result.blobs[b"one "], japanese.blobs[b"one "])
        self.assertEqual(result.blobs[b"two "], japanese.blobs[b"two "])
        self.assertNotIn(b"more", result.blobs)


if __name__ == "__main__":
    unittest.main()
