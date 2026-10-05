// MIT licensed patch tooling. Icon pixels are supplied by the user's media.
using System;
using System.Collections.Generic;
using System.IO;

public static class NfsseIconResources
{
    private sealed class Payload { public int Entry; public byte[] Bytes; }
    private static uint U32(byte[] b, int p) { return BitConverter.ToUInt32(b, p); }
    private static ushort U16(byte[] b, int p) { return BitConverter.ToUInt16(b, p); }
    private static void Put(byte[] b, int p, uint v) { Array.Copy(BitConverter.GetBytes(v), 0, b, p, 4); }
    private static uint Align(uint v, uint a) { return (v + a - 1) & ~(a - 1); }
    private static int Reserve(MemoryStream stream, int size)
    {
        int offset = (int)Align((uint)stream.Length, 4);
        stream.SetLength(offset + size);
        return offset;
    }
    private static int Directory(MemoryStream stream, BinaryWriter writer,
                                 Dictionary<int, object> entries, List<Payload> payloads)
    {
        int offset = Reserve(stream, 16 + entries.Count * 8);
        stream.Position = offset;
        writer.Write((uint)0); writer.Write((uint)0);
        writer.Write((ushort)0); writer.Write((ushort)0);
        writer.Write((ushort)0); writer.Write((ushort)entries.Count);
        List<int> ids = new List<int>(entries.Keys); ids.Sort();
        for (int i = 0; i < ids.Count; ++i)
        {
            object value = entries[ids[i]];
            Dictionary<int, object> child = value as Dictionary<int, object>;
            uint target;
            if (child != null) target = (uint)Directory(stream, writer, child, payloads) | 0x80000000;
            else
            {
                target = (uint)Reserve(stream, 16);
                payloads.Add(new Payload { Entry = (int)target, Bytes = (byte[])value });
            }
            stream.Position = offset + 16 + i * 8;
            writer.Write((uint)ids[i]); writer.Write(target);
        }
        return offset;
    }

    public static byte[] Embed(byte[] executable, byte[] icon)
    {
        if (executable.Length < 256 || U16(executable, 0) != 0x5A4D)
            throw new InvalidDataException("Invalid executable header.");
        int nt = (int)U32(executable, 0x3C), file = nt + 4, optional = nt + 24;
        if (U32(executable, nt) != 0x4550 || U16(executable, optional) != 0x10B)
            throw new InvalidDataException("Only the supported PE32 build can be patched.");
        int resource = optional + 96 + 2 * 8;
        if (U32(executable, resource) != 0 || U32(executable, resource + 4) != 0)
            throw new InvalidDataException("Existing resources must be preserved explicitly.");
        if (icon.Length < 6 || U16(icon, 0) != 0 || U16(icon, 2) != 1)
            throw new InvalidDataException("Invalid ICO header.");
        int count = U16(icon, 4);
        if (count == 0 || icon.Length < 6 + count * 16)
            throw new InvalidDataException("Invalid ICO directory.");
        Dictionary<int, object> images = new Dictionary<int, object>();
        MemoryStream groupStream = new MemoryStream(); BinaryWriter group = new BinaryWriter(groupStream);
        group.Write((ushort)0); group.Write((ushort)1); group.Write((ushort)count);
        for (int i = 0; i < count; ++i)
        {
            int entry = 6 + i * 16;
            uint size = U32(icon, entry + 8), offset = U32(icon, entry + 12);
            if (offset < 6 + count * 16 || size == 0 || (ulong)offset + size > (ulong)icon.Length)
                throw new InvalidDataException("Invalid ICO image bounds.");
            byte[] image = new byte[size]; Array.Copy(icon, (int)offset, image, 0, (int)size);
            ushort planes = U16(icon, entry + 4), bits = U16(icon, entry + 6);
            if ((planes == 0 || bits == 0) && image.Length >= 16 && U32(image, 0) >= 40)
            {
                if (planes == 0) planes = U16(image, 12);
                if (bits == 0) bits = U16(image, 14);
            }
            for (int k = 0; k < 4; ++k) group.Write(icon[entry + k]);
            group.Write(planes); group.Write(bits); group.Write(size); group.Write((ushort)(i + 1));
            images.Add(i + 1, new Dictionary<int, object> { { 0, image } });
        }
        uint sectionAlign = U32(executable, optional + 32), fileAlign = U32(executable, optional + 36);
        uint rva = Align(U32(executable, optional + 56), sectionAlign);
        uint rawOffset = Align((uint)executable.Length, fileAlign);
        MemoryStream tree = new MemoryStream(); BinaryWriter writer = new BinaryWriter(tree);
        List<Payload> payloads = new List<Payload>();
        Dictionary<int, object> root = new Dictionary<int, object> {
            { 3, images }, { 14, new Dictionary<int, object> {
                { 1, new Dictionary<int, object> { { 0, groupStream.ToArray() } } } } }
        };
        if (Directory(tree, writer, root, payloads) != 0) throw new InvalidDataException("Resource root offset.");
        foreach (Payload payload in payloads)
        {
            int offset = Reserve(tree, payload.Bytes.Length);
            tree.Position = offset; writer.Write(payload.Bytes);
            tree.Position = payload.Entry;
            writer.Write(rva + (uint)offset); writer.Write((uint)payload.Bytes.Length);
            writer.Write((uint)0); writer.Write((uint)0);
        }
        byte[] resources = tree.ToArray(); uint rawSize = Align((uint)resources.Length, fileAlign);
        int sections = U16(executable, file + 2);
        int header = optional + U16(executable, file + 16) + sections * 40;
        if (header + 40 > U32(executable, optional + 60))
            throw new InvalidDataException("No section-header space.");
        for (int i = header; i < header + 40; ++i)
            if (executable[i] != 0) throw new InvalidDataException("Section-header padding is in use.");
        byte[] result = new byte[rawOffset + rawSize];
        Array.Copy(executable, result, executable.Length); Array.Copy(resources, 0, result, rawOffset, resources.Length);
        Array.Copy(System.Text.Encoding.ASCII.GetBytes(".rsrc"), 0, result, header, 5);
        Put(result, header + 8, (uint)resources.Length); Put(result, header + 12, rva);
        Put(result, header + 16, rawSize); Put(result, header + 20, rawOffset);
        Put(result, header + 36, 0x40000040);
        Array.Copy(BitConverter.GetBytes((ushort)(sections + 1)), 0, result, file + 2, 2);
        Put(result, optional + 56, Align(rva + (uint)resources.Length, sectionAlign));
        Put(result, optional + 8, U32(executable, optional + 8) + rawSize);
        Put(result, optional + 64, 0);
        Put(result, resource, rva); Put(result, resource + 4, (uint)resources.Length);
        return result;
    }
}
