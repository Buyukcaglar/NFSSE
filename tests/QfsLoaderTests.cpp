// Exercise only the supported media's self-contained RefPack decoder, with
// the original loader's allocation and staging layout. Never start the game.
#include <windows.h>
#include <wincrypt.h>
#include <algorithm>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <stdexcept>
#include <string>
#include <vector>

static void need(bool value, const char* message) {
    if (!value) throw std::runtime_error(message);
}
static std::vector<BYTE> read(const char* path) {
    std::ifstream stream(path, std::ios::binary);
    need(bool(stream), "Missing test input");
    return std::vector<BYTE>(std::istreambuf_iterator<char>(stream), {});
}
static void verifyMedia(const std::vector<BYTE>& media) {
    need(media.size() == 1069056, "Unsupported media executable size");
    HCRYPTPROV provider = 0; HCRYPTHASH hash = 0;
    need(CryptAcquireContext(&provider, nullptr, nullptr, PROV_RSA_AES, CRYPT_VERIFYCONTEXT) != 0,
         "Could not create hash provider");
    need(CryptCreateHash(provider, CALG_SHA_256, 0, 0, &hash) != 0, "Could not create hash");
    need(CryptHashData(hash, media.data(), DWORD(media.size()), 0) != 0, "Could not hash media");
    BYTE result[32]; DWORD size = sizeof(result);
    need(CryptGetHashParam(hash, HP_HASHVAL, result, &size, 0) != 0, "Could not read hash");
    CryptDestroyHash(hash); CryptReleaseContext(provider, 0);
    char text[65];
    for (unsigned i = 0; i < 32; ++i) sprintf_s(text + i * 2, 3, "%02x", result[i]);
    need(std::string(text) == "ac72e59587b66f9a3bb2bdb83fa40b8eaac2d68a5ae47a041b026922f8d2594b",
         "Unsupported media executable hash");
}
int main(int argc, char** argv) {
    try {
        need(sizeof(void*) == 4, "Build this check for x86");
        need(argc >= 4 && argc % 2 == 0, "Usage: QfsLoaderTests media-exe qfs fsh [qfs fsh ...]");
        auto media = read(argv[1]); verifyMedia(media);
        auto dos = reinterpret_cast<const IMAGE_DOS_HEADER*>(media.data());
        auto pe = reinterpret_cast<const IMAGE_NT_HEADERS*>(media.data() + dos->e_lfanew);
        auto section = IMAGE_FIRST_SECTION(pe);
        const DWORD rva = 0xa823c, length = 0x170;
        DWORD offset = 0;
        for (unsigned i = 0; i < pe->FileHeader.NumberOfSections; ++i) {
            if (rva >= section[i].VirtualAddress && rva + length <= section[i].VirtualAddress + section[i].SizeOfRawData)
                offset = section[i].PointerToRawData + rva - section[i].VirtualAddress;
        }
        need(offset != 0 && offset + length <= media.size(), "Decoder is not file backed");
        // This checked function has only local relative branches, no imports,
        // calls or absolute addresses. Copy no other game code into execution.
        void* code = VirtualAlloc(nullptr, length, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
        need(code != nullptr, "Could not allocate decoder");
        memcpy(code, media.data() + offset, length);
        DWORD oldProtection = 0;
        need(VirtualProtect(code, length, PAGE_EXECUTE_READ, &oldProtection) != 0, "Could not protect decoder");
        FlushInstructionCache(GetCurrentProcess(), code, length);
        auto decode = reinterpret_cast<int (__cdecl *)(const BYTE*, BYTE*, int)>(code);
        for (int i = 2; i < argc; i += 2) {
            auto packed = read(argv[i]), raw = read(argv[i + 1]);
            need(packed.size() >= 6 && packed[0] == 0x10 && packed[1] == 0xfb, "Unsupported QFS header");
            size_t expected = (size_t(packed[2]) << 16) | (size_t(packed[3]) << 8) | packed[4];
            need(expected == raw.size(), "Declared size differs from reference");
            size_t capacity = expected + 1024;
            need(packed.size() <= capacity, "Compressed file exceeds original loader allocation");
            std::vector<BYTE> buffer(capacity + 128, 0xa5);
            BYTE* destination = buffer.data() + 64;
            memcpy(destination, packed.data(), packed.size());
            BYTE* source = destination + capacity - packed.size();
            memmove(source, destination, packed.size());
            need(decode(source, destination, 1) == int(expected), "Decoder returned wrong length");
            need(memcmp(destination, raw.data(), expected) == 0, "Original decoder changed resource bytes");
            need(std::all_of(buffer.begin(), buffer.begin() + 64, [](BYTE b) { return b == 0xa5; }) &&
                 std::all_of(buffer.end() - 64, buffer.end(), [](BYTE b) { return b == 0xa5; }), "Workspace sentinel changed");
            printf("Original decoder passed: %s (%zu -> %zu bytes); workspace sentinels intact\n", argv[i], packed.size(), expected);
        }
        VirtualFree(code, 0, MEM_RELEASE);
        return 0;
    } catch (const std::exception& error) {
        fprintf(stderr, "%s\n", error.what()); return 1;
    }
}
