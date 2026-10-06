// Source-bounded resource transforms used by the optional Windows installer.
// No artwork generation, palette conversion, resampling or audio transcoding.
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

public static class NfsLanguageResources {
    static void Need(bool condition, string message) {
        if (!condition) throw new InvalidOperationException(message);
    }
    static uint U32(byte[] b, int p) { Need(p >= 0 && p + 4 <= b.Length, "Truncated resource field"); return BitConverter.ToUInt32(b, p); }
    static void Put(byte[] b, int p, uint n) { Array.Copy(BitConverter.GetBytes(n), 0, b, p, 4); }
    public static byte[] Decode(byte[] input) {
        if (input.Length >= 4 && Encoding.ASCII.GetString(input, 0, 4) == "SHPI") return input;
        Need(input.Length >= 6 && input[0] == 0x10 && input[1] == 0xfb, "Unsupported resource compression");
        int expected = (input[2] << 16) | (input[3] << 8) | input[4];
        Need(expected >= 16 && expected < 0x1000000, "Invalid RefPack output size");
        List<byte> output = new List<byte>(expected + 3); int position = 5;
        while (true) {
            Need(position < input.Length, "Missing RefPack stop code");
            int command = input[position++];
            int args = command < 0x80 ? 1 : command < 0xc0 ? 2 : command < 0xe0 ? 3 : 0;
            Need(position + args <= input.Length, "Truncated RefPack command");
            int a = args > 0 ? input[position] : 0, b = args > 1 ? input[position + 1] : 0, c = args > 2 ? input[position + 2] : 0;
            position += args; int literals, distance = 0, length = 0;
            if (command < 0x80) { literals = command & 3; distance = ((command & 0x60) << 3) + a + 1; length = ((command >> 2) & 7) + 3; }
            else if (command < 0xc0) { literals = a >> 6; distance = ((a & 0x3f) << 8) + b + 1; length = (command & 0x3f) + 4; }
            else if (command < 0xe0) { literals = command & 3; distance = ((command & 0x10) << 12) + (a << 8) + b + 1; length = ((command & 0x0c) << 6) + c + 5; }
            else if (command < 0xfc) literals = ((command & 0x1f) << 2) + 4;
            else literals = command & 3;
            Need(position + literals <= input.Length, "Truncated RefPack literals");
            Need(output.Count + literals + length <= expected + 3, "RefPack output exceeds declared size");
            for (int i = 0; i < literals; i++) output.Add(input[position++]);
            if (distance > 0) {
                Need(distance <= output.Count, "RefPack reference precedes output");
                for (int i = 0; i < length; i++) output.Add(output[output.Count - distance]);
            }
            if (command >= 0xfc) break;
        }
        Need(position == input.Length && output.Count >= expected, "RefPack size mismatch or trailing data");
        for (int i = expected; i < output.Count; i++) Need(output[i] == 0, "Nonzero RefPack padding");
        return output.Take(expected).ToArray();
    }
    public static byte[] Encode(byte[] raw) {
        Need(raw.Length >= 16 && raw.Length < 0x1000000 && Encoding.ASCII.GetString(raw, 0, 4) == "SHPI", "Expected bounded SHPI data");
        List<byte> output = new List<byte>(); output.AddRange(new byte[] {0x10, 0xfb, (byte)(raw.Length >> 16), (byte)(raw.Length >> 8), (byte)raw.Length});
        // The original loader stages the file in decoded_size + 1024 bytes,
        // then decodes from the buffer's end. Literal-only encoding overflows
        // this workspace for large screens despite a correct round trip.
        Dictionary<int, int> recent = new Dictionary<int, int>();
        int position = 0, literalStart = 0, written = 0, peak = 0;
        while (position + 3 <= raw.Length) {
            int tag = Key(raw, position), previous, distance = 0, length = 0;
            if (recent.TryGetValue(tag, out previous)) distance = position - previous;
            if (distance > 0 && distance <= 131072) {
                int limit = Math.Min(1028, raw.Length - position);
                while (length < limit && raw[previous + length] == raw[position + length]) length++;
            }
            bool usable = length >= 5 || length >= 4 && distance <= 16384 || length >= 3 && distance <= 1024;
            if (!usable) { recent[tag] = position++; continue; }
            Literals(raw, output, position, ref literalStart, ref written, ref peak);
            int tail = position - literalStart, offset = distance - 1;
            if (length <= 10 && distance <= 1024) {
                output.Add((byte)((offset >> 8) << 5 | (length - 3) << 2 | tail));
                output.Add((byte)offset);
            } else if (length <= 67 && distance <= 16384) {
                output.Add((byte)(0x80 | length - 4));
                output.Add((byte)(tail << 6 | offset >> 8)); output.Add((byte)offset);
            } else {
                int count = length - 5;
                output.Add((byte)(0xc0 | (offset >> 16) << 4 | (count >> 8) << 2 | tail));
                output.Add((byte)(offset >> 8)); output.Add((byte)offset); output.Add((byte)count);
            }
            for (int i = literalStart; i < position; i++) output.Add(raw[i]);
            written += tail + length; peak = Math.Max(peak, written - output.Count);
            int end = position + length;
            while (position < end) {
                if (position + 3 <= raw.Length) recent[Key(raw, position)] = position;
                position++;
            }
            literalStart = position;
        }
        Literals(raw, output, raw.Length, ref literalStart, ref written, ref peak);
        output.Add((byte)(0xfc + raw.Length - literalStart));
        for (int i = literalStart; i < raw.Length; i++) output.Add(raw[i]);
        Need(output.Count + peak <= raw.Length + 1024, "RefPack exceeds legacy in-place workspace");
        return output.ToArray();
    }
    static int Key(byte[] raw, int position) {
        return raw[position] << 16 | raw[position + 1] << 8 | raw[position + 2];
    }
    static void Literals(byte[] raw, List<byte> output, int end, ref int start, ref int written, ref int peak) {
        while (end - start >= 4) {
            int size = Math.Min(112, ((end - start) / 4) * 4);
            output.Add((byte)(0xe0 + size / 4 - 1));
            for (int i = 0; i < size; i++) output.Add(raw[start++]);
            written += size; peak = Math.Max(peak, written - output.Count);
        }
    }
    public sealed class Archive {
        public readonly List<string> Order = new List<string>();
        public readonly Dictionary<string, byte[]> Blobs = new Dictionary<string, byte[]>();
        public readonly byte[] Kind;
        static readonly Encoding Tags = Encoding.GetEncoding(28591);
        public Archive(byte[] input) {
            byte[] raw = Decode(input);
            Need(raw.Length >= 16 && Encoding.ASCII.GetString(raw, 0, 4) == "SHPI", "Missing SHPI header");
            uint size = U32(raw, 4), count = U32(raw, 8);
            Need(size == raw.Length && count > 0 && count <= 4096 && 16 + count * 8 <= size, "Invalid SHPI size or directory");
            Kind = raw.Skip(12).Take(4).ToArray();
            List<int> offsets = new List<int>();
            Dictionary<string, int> locations = new Dictionary<string, int>();
            for (int i = 0; i < count; i++) {
                string name = Tags.GetString(raw, 16 + i * 8, 4); uint offset = U32(raw, 20 + i * 8);
                Need(!locations.ContainsKey(name) && offset >= 16 + count * 8 && offset <= size - 4, "Invalid SHPI name or offset");
                locations.Add(name, (int)offset); Order.Add(name); offsets.Add((int)offset);
            }
            offsets = offsets.Distinct().OrderBy(n => n).ToList();
            foreach (string name in Order) {
                int start = locations[name], index = offsets.IndexOf(start);
                int end = index + 1 < offsets.Count ? offsets[index + 1] : raw.Length;
                byte[] blob = raw.Skip(start).Take(end - start).ToArray();
                if (blob[0] == 0x7b) {
                    Need(blob.Length >= 16, "Truncated indexed image header");
                    long pixels = (long)BitConverter.ToUInt16(blob, 4) * BitConverter.ToUInt16(blob, 6);
                    Need(pixels <= blob.Length - 16, "Truncated indexed image pixels");
                }
                Blobs.Add(name, blob);
            }
        }
        public byte[] Pack(IEnumerable<string> names, IDictionary<string, byte[]> blobs) {
            List<string> order = names.ToList();
            Need(order.Count > 0 && order.Distinct().Count() == order.Count && order.All(s => s.Length == 4), "Invalid SHPI output directory");
            int offset = 16 + order.Count * 8;
            foreach (string name in order) { Need(blobs.ContainsKey(name), "Missing output entry"); offset = checked(offset + blobs[name].Length); }
            byte[] result = new byte[offset]; Encoding.ASCII.GetBytes("SHPI").CopyTo(result, 0);
            Put(result, 4, (uint)result.Length); Put(result, 8, (uint)order.Count); Kind.CopyTo(result, 12);
            offset = 16 + order.Count * 8;
            for (int i = 0; i < order.Count; i++) {
                string name = order[i]; Tags.GetBytes(name).CopyTo(result, 16 + i * 8); Put(result, 20 + i * 8, (uint)offset);
                blobs[name].CopyTo(result, offset); offset += blobs[name].Length;
            }
            new Archive(result); return result;
        }
    }
    public static byte[] Graphics(byte[] japanese, byte[] english, byte[] target) {
        Archive jp = new Archive(japanese), en = new Archive(english), context = new Archive(target);
        Need(jp.Blobs["!pal"].SequenceEqual(en.Blobs["!pal"]), "Graphics palettes differ");
        string[] missing = {"atld", "atll", "atmd", "atml"};
        Need(new HashSet<string>(en.Order.Except(jp.Order)).SetEquals(missing) && !jp.Order.Except(en.Order).Any(), "Unexpected Japanese graphics entries");
        Need(new HashSet<string>(context.Order).SetEquals(en.Order), "Unexpected graphics context entries");
        HashSet<string> restored = new HashSet<string>(missing.Concat(new[] {"320d", "320l", "320m"}));
        Dictionary<string, byte[]> blobs = new Dictionary<string, byte[]>();
        foreach (string name in en.Order) blobs.Add(name, restored.Contains(name) ? en.Blobs[name] : jp.Blobs[name]);
        return jp.Pack(context.Order, blobs);
    }
    public static byte[] Hud(byte[] japanese, byte[] english) {
        Archive jp = new Archive(japanese), en = new Archive(english);
        Need(!en.Order.Except(jp.Order).Any(), "Japanese HUD lacks required entries");
        return jp.Pack(en.Order, jp.Blobs);
    }
}
