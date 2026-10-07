// Execute only the verified engine's file serializers/loaders in isolation.
// No game entry point, window, renderer, audio, simulation or UI is started.
#define _CRT_SECURE_NO_WARNINGS
#include "../src/NFSPortable.cpp"
#include <wincrypt.h>
#include <cstdlib>
#include <string>
#include <vector>
#include <fstream>
#include <stdexcept>

static void need(bool value, const char* message) {
    if (!value) throw std::runtime_error(message);
}
static std::vector<BYTE> readBytes(const std::wstring& path) {
    std::ifstream file(path, std::ios::binary);
    need(bool(file), "Missing test file");
    return std::vector<BYTE>(std::istreambuf_iterator<char>(file), {});
}
static void writeBytes(const std::wstring& path, const std::vector<BYTE>& bytes) {
    std::ofstream file(path, std::ios::binary);
    file.write(reinterpret_cast<const char*>(bytes.data()), bytes.size());
    need(bool(file), "Could not write test fixture");
}
static unsigned warnings, nativeErrors;
static DWORD allocationSize;
static BYTE* reservedEngine;
static ULONGLONG fakeFreeBytes;
static BOOL fakeQueryResult = TRUE;
static int WINAPI fakeWarning(HWND, LPCWSTR, LPCWSTR, UINT) { ++warnings; return IDOK; }
static BOOL WINAPI fakeFreeSpace(LPCWSTR root, PULARGE_INTEGER available,
    PULARGE_INTEGER, PULARGE_INTEGER) {
    need(wcscmp(root, gameRoot) == 0, "Save-space check used a different folder");
    available->QuadPart = fakeFreeBytes;
    if (!fakeQueryResult) SetLastError(ERROR_ACCESS_DENIED);
    return fakeQueryResult;
}
static BOOL WINAPI truncatedDisk(LPCSTR, LPDWORD sectors, LPDWORD bytes,
    LPDWORD freeClusters, LPDWORD totalClusters) {
    *sectors = 8; *bytes = 512; *freeClusters = 0x10000; *totalClusters = 0x20000;
    return TRUE; // 256 MB available; native WORD truncation reports zero.
}
static void __cdecl noLock(void*) {}
static void* __cdecl allocate(const char*, DWORD size, int) {
    allocationSize = size;
    return std::calloc(1, size);
}
static DWORD __cdecl allocatedSize(void*) { return allocationSize; }
static void __cdecl release(void* memory) { std::free(memory); }
static void __declspec(naked) nativeError() {
    __asm {
        inc dword ptr [nativeErrors]
        ret
    }
}
static void __declspec(naked) nativeCwd() {
    __asm {
        pushad
        push eax
        push edx
        call GetCurrentDirectoryA
        popad
        ret
    }
}
static int fakeNameResult = 1;
static void __declspec(naked) fakeName() {
    __asm {
        mov eax, dword ptr [fakeNameResult]
        ret
    }
}
static void patchFunction(DWORD rva, void* function) {
    gameBase[rva] = 0xe9;
    *reinterpret_cast<DWORD*>(gameBase + rva + 1) =
        reinterpret_cast<DWORD>(function) - reinterpret_cast<DWORD>(gameBase + rva + 5);
}
static BYTE* mapEngine(const std::vector<BYTE>& media) {
    need(media.size() == 1069056, "Unsupported media size");
    HCRYPTPROV provider = 0; HCRYPTHASH hash = 0;
    need(CryptAcquireContextW(&provider, nullptr, nullptr, PROV_RSA_AES, CRYPT_VERIFYCONTEXT) != FALSE,
        "Hash provider failed");
    need(CryptCreateHash(provider, CALG_SHA_256, 0, 0, &hash) != FALSE, "Hash creation failed");
    need(CryptHashData(hash, media.data(), DWORD(media.size()), 0) != FALSE, "Hash failed");
    BYTE digest[32]; DWORD size = sizeof(digest);
    need(CryptGetHashParam(hash, HP_HASHVAL, digest, &size, 0) != FALSE, "Hash read failed");
    CryptDestroyHash(hash); CryptReleaseContext(provider, 0);
    char text[65];
    for (unsigned i = 0; i < 32; ++i) sprintf_s(text + i * 2, 3, "%02x", digest[i]);
    need(strcmp(text, "ac72e59587b66f9a3bb2bdb83fa40b8eaac2d68a5ae47a041b026922f8d2594b") == 0,
        "Unsupported engine hash");
    auto dos = reinterpret_cast<const IMAGE_DOS_HEADER*>(media.data());
    auto pe = reinterpret_cast<const IMAGE_NT_HEADERS32*>(media.data() + dos->e_lfanew);
    need(pe->OptionalHeader.ImageBase == 0x400000 && pe->OptionalHeader.SizeOfImage <= 0x141000,
        "Unexpected engine mapping size");
    BYTE* mapped = static_cast<BYTE*>(VirtualAlloc(reservedEngine,
        pe->OptionalHeader.SizeOfImage, MEM_COMMIT, PAGE_EXECUTE_READWRITE));
    need(mapped != nullptr, "Test mapping unavailable");
    memcpy(mapped, media.data(), pe->OptionalHeader.SizeOfHeaders);
    auto sections = IMAGE_FIRST_SECTION(pe);
    for (unsigned i = 0; i < pe->FileHeader.NumberOfSections; ++i) {
        if (sections[i].PointerToRawData)
            memcpy(mapped + sections[i].VirtualAddress, media.data() + sections[i].PointerToRawData,
                sections[i].SizeOfRawData);
    }
    const DWORD delta = reinterpret_cast<DWORD>(mapped) - pe->OptionalHeader.ImageBase;
    if (delta) {
        const auto directory = pe->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_BASERELOC];
        need(directory.VirtualAddress && directory.Size, "Engine has no relocation table");
        DWORD offset = directory.VirtualAddress;
        const DWORD end = offset + directory.Size;
        while (offset < end) {
            auto block = reinterpret_cast<IMAGE_BASE_RELOCATION*>(mapped + offset);
            need(block->SizeOfBlock >= sizeof(*block) && offset + block->SizeOfBlock <= end,
                "Invalid relocation block");
            auto entries = reinterpret_cast<const WORD*>(block + 1);
            for (DWORD i = 0; i < (block->SizeOfBlock - sizeof(*block)) / sizeof(WORD); ++i) {
                const unsigned type = entries[i] >> 12;
                if (type == IMAGE_REL_BASED_ABSOLUTE) continue;
                need(type == IMAGE_REL_BASED_HIGHLOW, "Unsupported relocation type");
                const DWORD target = block->VirtualAddress + (entries[i] & 0xfff);
                need(target + sizeof(DWORD) <= pe->OptionalHeader.SizeOfImage, "Relocation outside image");
                *reinterpret_cast<DWORD*>(mapped + target) += delta;
            }
            offset += block->SizeOfBlock;
        }
    }
    auto imports = reinterpret_cast<IMAGE_IMPORT_DESCRIPTOR*>(mapped +
        pe->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress);
    for (; imports->Name; ++imports) {
        const char* name = reinterpret_cast<const char*>(mapped + imports->Name);
        if (_stricmp(name, "kernel32.dll") != 0) continue;
        auto symbols = reinterpret_cast<IMAGE_THUNK_DATA32*>(mapped + imports->OriginalFirstThunk);
        auto slots = reinterpret_cast<IMAGE_THUNK_DATA32*>(mapped + imports->FirstThunk);
        for (; symbols->u1.AddressOfData; ++symbols, ++slots) {
            need(!IMAGE_SNAP_BY_ORDINAL32(symbols->u1.Ordinal), "Unexpected ordinal");
            auto symbol = reinterpret_cast<IMAGE_IMPORT_BY_NAME*>(mapped + symbols->u1.AddressOfData);
            auto address = GetProcAddress(GetModuleHandleW(L"kernel32.dll"), symbol->Name);
            need(address != nullptr, "Missing kernel import");
            slots->u1.Function = reinterpret_cast<DWORD>(address);
        }
    }
    return mapped;
}
static DWORD callRegister(DWORD rva, void* argument) {
    void* function = gameBase + rva;
    DWORD result;
    __asm {
        pushad
        mov eax, argument
        call dword ptr [function]
        mov result, eax
        popad
    }
    return result;
}
static DWORD callNativeSpace(DWORD bytes) { return callRegister(0x6733c, reinterpret_cast<void*>(bytes)); }
static void resetNativeFiles() {
    static DWORD handles[64 * 4];
    memset(handles, 0xff, sizeof(handles));
    *reinterpret_cast<DWORD*>(gameBase + 0xc785c) = reinterpret_cast<DWORD>(handles);
    *reinterpret_cast<DWORD*>(gameBase + 0xc7858) = 64;
}
static void bindRoot(const std::wstring& root) {
    wcscpy_s(gameRoot, root.c_str());
    need(SetCurrentDirectoryW(root.c_str()) != FALSE, "Test cwd failed");
}
static void storageChecks(const std::wstring& root) {
    need(CreateDirectoryW(root.c_str(), nullptr) != FALSE, "Use a fresh storage-test folder");
    need(CreateDirectoryW((root + L"\\GAMEDATA").c_str(), nullptr) != FALSE, "Fixture mkdir failed");
    need(CreateDirectoryW((root + L"\\GAMEDATA\\CONFIG").c_str(), nullptr) != FALSE, "Fixture mkdir failed");
    gameBase = static_cast<BYTE*>(VirtualAlloc(nullptr, 0x130000, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE));
    need(gameBase != nullptr, "Fixture allocation failed");
    wcscpy_s(gameRoot, root.c_str());
    showPlayerSaveWarning = fakeWarning;
    std::vector<BYTE> expected(playerConfigSize);
    for (size_t i = 0; i < expected.size(); ++i) expected[i] = BYTE(i * 29 + 7);
    memcpy(expected.data(), "PORTABLE", 9);
    memcpy(gameBase + 0x124df0, expected.data(), expected.size());
    auto path = root + L"\\GAMEDATA\\CONFIG\\CONFIG.DAT";
    playerConfigReady = 0;
    need(persistPlayerConfig() && GetFileAttributesW(path.c_str()) == INVALID_FILE_ATTRIBUTES,
        "Uninitialized configuration was saved");
    playerConfigReady = 1;
    originalEnterPlayerName = reinterpret_cast<void*>(&fakeName);
    fakeNameResult = 0; enterPlayerName();
    need(GetFileAttributesW(path.c_str()) == INVALID_FILE_ATTRIBUTES, "Cancelled name was saved");
    fakeNameResult = 1; enterPlayerName();
    need(readBytes(path) == expected, "Confirmed name/full configuration was not saved");
    HANDLE locked = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL, nullptr);
    need(locked != INVALID_HANDLE_VALUE, "Saved file lock failed");
    gameBase[0x124df0 + 0x2200] ^= 0xff;
    need(!persistPlayerConfig() && readBytes(path) == expected && warnings == 1,
        "Failed update did not retain/report the previous data");
    need(!persistPlayerConfig() && warnings == 1, "Save warning repeated");
    CloseHandle(locked);
    gameBase[0x124df0 + 0x2200] ^= 0xff;
    need(persistPlayerConfig(), "Save did not recover after the file was unlocked");
    queryPlayerFreeSpace = fakeFreeSpace;
    for (ULONGLONG bytes : {0ull, 24401ull, 24402ull, 24403ull, 0x100000000ull, 0x10000000000ull}) {
        fakeFreeBytes = bytes;
        need(checkPlayerFreeSpace(playerConfigSize) == int(bytes >= playerConfigSize),
            "Save-space boundary failed");
    }
    fakeQueryResult = FALSE;
    need(checkPlayerFreeSpace(playerConfigSize) == 0, "Failed save-space query was accepted");
    std::wstring relocated = root + L" relocated";
    need(MoveFileExW(root.c_str(), relocated.c_str(), 0) != FALSE, "Storage relocation failed");
    wcscpy_s(gameRoot, relocated.c_str());
    need(persistPlayerConfig() && readBytes(relocated + L"\\GAMEDATA\\CONFIG\\CONFIG.DAT") == expected,
        "Relocated storage used the old folder or launch cwd");
    std::puts("Media-independent persistence checks passed: name checkpoint/cancel, full data, readiness, failure preservation, recovery, 64-bit space and relocation");
}
int wmain(int argc, wchar_t** argv) {
    try {
        if (argc == 3 && wcscmp(argv[1], L"--storage") == 0) {
            storageChecks(argv[2]); return 0;
        }
        need(argc >= 4, "Usage: PlayerPersistenceTests media-exe media-config fresh-output [--exit|--restore]");
        // Reserve before file/vector allocations. If a Windows startup heap
        // occupies the preferred base, apply the engine's own PE relocations.
        reservedEngine = static_cast<BYTE*>(VirtualAlloc(reinterpret_cast<void*>(0x400000),
            0x141000, MEM_RESERVE, PAGE_NOACCESS));
        if (!reservedEngine) reservedEngine = static_cast<BYTE*>(VirtualAlloc(nullptr,
            0x141000, MEM_RESERVE, PAGE_NOACCESS));
        need(reservedEngine != nullptr, "Test reservation unavailable");
        const auto media = readBytes(argv[1]);
        auto config = readBytes(argv[2]);
        need(config.size() == playerConfigSize, "Unsupported configuration layout");
        gameBase = mapEngine(media);
        showPlayerSaveWarning = fakeWarning;
        patchFunction(0x73d43, reinterpret_cast<void*>(&sprintf));
        patchFunction(0x74c8c, reinterpret_cast<void*>(&allocate));
        patchFunction(0x75260, reinterpret_cast<void*>(&release));
        patchFunction(0x7596c, reinterpret_cast<void*>(&allocatedSize));
        patchFunction(0x76c78, reinterpret_cast<void*>(&noLock));
        patchFunction(0x76cfc, reinterpret_cast<void*>(&noLock));
        patchFunction(0x960cf, reinterpret_cast<void*>(&nativeCwd));
        patchFunction(0x8f9ec, reinterpret_cast<void*>(&nativeError));
        patchFunction(0x8fa14, reinterpret_cast<void*>(&nativeError));
        patchFunction(0x77a40, reinterpret_cast<void*>(&nativeError));
        resetNativeFiles();
        // The harness output must be a new or explicitly retained test folder.
        std::wstring root = argv[3];
        need(root.size() > 3 && root[1] == L':', "Use an absolute test folder");
        if (argc == 4) need(CreateDirectoryW(root.c_str(), nullptr) != FALSE, "Test folder already exists");
        else need(GetFileAttributesW(root.c_str()) != INVALID_FILE_ATTRIBUTES, "Missing exit test folder");
        CreateDirectoryW((root + L"\\GAMEDATA").c_str(), nullptr);
        CreateDirectoryW((root + L"\\GAMEDATA\\CONFIG").c_str(), nullptr);
        CreateDirectoryW((root + L"\\GAMEDATA\\SAVEGAME").c_str(), nullptr);
        bindRoot(root);
        strcpy_s(reinterpret_cast<char*>(gameBase + 0x124198), 80, "gamedata/config/");
        std::wstring configPath = root + L"\\GAMEDATA\\CONFIG\\CONFIG.DAT";
        if (argc > 4 && wcscmp(argv[4], L"--restore") == 0) {
            config = readBytes(configPath);
            need(config.size() == playerConfigSize && memcmp(config.data(), "EXITTEST", 9) == 0,
                "Exit did not save the player name");
            need(configurePlayerPersistence(gameBase), "Restore-process hooks failed");
            memset(gameBase + 0x124df0, 0, playerConfigSize); loadPlayerConfig();
            need(memcmp(gameBase + 0x124df0, config.data(), config.size()) == 0,
                "New process did not restore the complete exit checkpoint");
            const auto progress = readBytes(root + L"\\GAMEDATA\\SAVEGAME\\PORTABLE.SAV");
            char savePath[] = "gamedata/savegame/PORTABLE.SAV";
            callRegister(0x2a484, savePath);
            need(progress.size() == 0x5b6 && memcmp(gameBase + 0x12ad44, progress.data(), progress.size()) == 0,
                "New process did not restore tournament progress");
            std::puts("Passed: separate-process exit/restart restores name, entire CONFIG.DAT and tournament progress");
            return 0;
        }
        memcpy(gameBase + 0x124df0, config.data(), config.size());
        memcpy(gameBase + 0x124df0, "PERSIST", 8);
        // Seed independent settings/records/progress bytes, retaining valid control fields.
        gameBase[0x124df0 + 0x2200] = 0x73;
        config.assign(gameBase + 0x124df0, gameBase + 0x124df0 + playerConfigSize);
        writeBytes(configPath, config);

        // Reproduce the original disk-space truncation with an ample test disk.
        *reinterpret_cast<void**>(gameBase + 0x131534) = reinterpret_cast<void*>(&truncatedDisk);
        need(callNativeSpace(playerConfigSize) == 0, "Legacy free-space failure did not reproduce");
        std::puts("Reproduced: original save-space check rejects 256 MB free after WORD truncation");
        auto codeBefore = std::vector<BYTE>(gameBase, gameBase + 0x141000);
        gameBase[0x37cf4] = 0x90;
        need(!configurePlayerPersistence(gameBase), "Unexpected persistence code accepted");
        need(memcmp(gameBase + 0x373e7, codeBefore.data() + 0x373e7, 5) == 0,
            "Partial hook installation on rejection");
        gameBase[0x37cf4] = codeBefore[0x37cf4];
        need(configurePlayerPersistence(gameBase), "Persistence hooks failed");
        queryPlayerFreeSpace = fakeFreeSpace;
        for (ULONGLONG freeBytes : {0ull, 24401ull, 24402ull, 24403ull, 0x100000000ull, 0x10000000000ull}) {
            fakeFreeBytes = freeBytes;
            need(checkPlayerFreeSpace(playerConfigSize) == int(freeBytes >= playerConfigSize),
                "64-bit free-space boundary failed");
        }
        fakeQueryResult = FALSE;
        need(checkPlayerFreeSpace(playerConfigSize) == 0, "Failed space query allowed saving");
        fakeQueryResult = TRUE; fakeFreeBytes = 0x10000000000ull;
        // The actual game saver still serializes byte-for-byte to the same portable file.
        callRegister(0x2a504, nullptr);
        need(nativeErrors == 0 && readBytes(configPath) == config, "Native configuration serialization failed");
        memset(gameBase + 0x124df0, 0, playerConfigSize);
        loadPlayerConfig();
        need(playerConfigReady == 1 && memcmp(gameBase + 0x124df0, config.data(), config.size()) == 0,
            "Original loader did not restore the full name/settings/records block");
        originalEnterPlayerName = reinterpret_cast<void*>(&fakeName);
        if (argc > 4) {
            memcpy(gameBase + 0x124df0, "EXITTEST", 9);
            reinterpret_cast<decltype(&ExitProcess)>(*reinterpret_cast<void**>(gameBase + 0x131514))(0);
            need(false, "Exit hook returned");
        }
        playerConfigReady = 0;
        memcpy(gameBase + 0x124df0, "UNREADY", 8);
        need(persistPlayerConfig() && readBytes(configPath) == config, "Uninitialized config overwrote a save");
        playerConfigReady = 1;
        memcpy(gameBase + 0x124df0, "NAMEONLY", 9);
        fakeNameResult = 0; enterPlayerName();
        need(readBytes(configPath) == config, "Cancelled name dialog saved");
        fakeNameResult = 1; enterPlayerName();
        config.assign(gameBase + 0x124df0, gameBase + 0x124df0 + playerConfigSize);
        need(readBytes(configPath) == config, "Accepted name was not checkpointed immediately");
        memset(gameBase + 0x124df0, 0, playerConfigSize); loadPlayerConfig();
        need(memcmp(gameBase + 0x124df0, config.data(), config.size()) == 0,
            "Name checkpoint failed native reload");
        std::puts("Passed: native CONFIG.DAT byte identity; full block restore; accepted/cancelled name; readiness guard");
        // Test the original .SAV serializer and loader, with the production
        // free-space bridge installed, using a patterned tournament-state block.
        std::vector<BYTE> progress(0x5b6);
        for (size_t i = 0; i < progress.size(); ++i) progress[i] = BYTE(i * 17 + 11);
        memcpy(gameBase + 0x12ad44, progress.data(), progress.size());
        char savePath[] = "gamedata/savegame/PORTABLE.SAV";
        need(callRegister(0x2a580, savePath) == 1, "Original tournament save failed");
        need(readBytes(root + L"\\GAMEDATA\\SAVEGAME\\PORTABLE.SAV") == progress,
            "Tournament save bytes changed");
        memset(gameBase + 0x12ad44, 0, progress.size());
        callRegister(0x2a484, savePath);
        need(memcmp(gameBase + 0x12ad44, progress.data(), progress.size()) == 0,
            "Tournament state failed native restore");
        std::puts("Passed: original .SAV writer/loader restore all 1,462 tournament-state bytes");
        // Failure must keep the last good file and clean up its temporary write.
        HANDLE locked = CreateFileW(configPath.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
            OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
        need(locked != INVALID_HANDLE_VALUE, "Could not lock saved config");
        memcpy(gameBase + 0x124df0, "FAILSAVE", 9);
        need(!persistPlayerConfig() && warnings == 1, "Save failure was not reported");
        need(readBytes(configPath) == config, "Failed checkpoint damaged the old configuration");
        need(!persistPlayerConfig() && warnings == 1, "Repeated failure warning was not bounded");
        CloseHandle(locked);
        memcpy(gameBase + 0x124df0, config.data(), config.size());
        std::wstring temporary = configPath + L".portable-" + std::to_wstring(GetCurrentProcessId()) + L".tmp";
        need(GetFileAttributesW(temporary.c_str()) == INVALID_FILE_ATTRIBUTES, "Failed write left a temporary file");
        std::puts("Passed: failed replacement preserves old configuration and reports the failure once");
        // Move the test installation and deliberately start from an unrelated cwd.
        need(SetCurrentDirectoryW(L"C:\\") != FALSE, "Could not leave test directory");
        std::wstring relocated = root + L" relocated";
        need(MoveFileExW(root.c_str(), relocated.c_str(), 0) != FALSE, "Relocation failed");
        wcscpy_s(gameRoot, relocated.c_str());
        need(persistPlayerConfig(), "Relocated checkpoint failed from unrelated cwd");
        bindRoot(relocated);
        memset(gameBase + 0x124df0, 0, playerConfigSize); loadPlayerConfig();
        need(memcmp(gameBase + 0x124df0, config.data(), config.size()) == 0, "Relocated name/config failed restore");
        memset(gameBase + 0x12ad44, 0, progress.size()); callRegister(0x2a484, savePath);
        need(memcmp(gameBase + 0x12ad44, progress.data(), progress.size()) == 0, "Relocated progress failed restore");
        std::puts("Passed: relocated name/settings/records and tournament progress; no fixed storage path");
        std::printf("RESULT: all persistence checks passed; warnings=%u; native errors=%u\n", warnings, nativeErrors);
        return 0;
    } catch (const std::exception& error) {
        std::fprintf(stderr, "%s\n", error.what()); return 1;
    }
}
