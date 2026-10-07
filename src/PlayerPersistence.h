// The verified game serializes this entire block verbatim to CONFIG.DAT.
// Keep its name, settings, records and unlock/tournament fields together.
static constexpr DWORD playerConfigSize = 0x5f52;
static volatile LONG playerConfigReady;
static volatile LONG playerSaveWarning;
static SRWLOCK playerSaveLock = SRWLOCK_INIT;
static void* originalLoadPlayerConfig;
static void* originalEnterPlayerName;
static decltype(&ExitProcess) realExitProcess = ExitProcess;
static decltype(&GetDiskFreeSpaceExW) queryPlayerFreeSpace = GetDiskFreeSpaceExW;
static decltype(&MessageBoxW) showPlayerSaveWarning = MessageBoxW;

static bool writePlayerConfig(const wchar_t* path, const BYTE* bytes) {
    wchar_t temporary[32768];
    if (swprintf_s(temporary, L"%s.portable-%lu.tmp", path, GetCurrentProcessId()) < 0) {
        SetLastError(ERROR_FILENAME_EXCED_RANGE);
        return false;
    }
    HANDLE file = CreateFileW(temporary, GENERIC_WRITE, 0, nullptr, CREATE_NEW,
        FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file == INVALID_HANDLE_VALUE) return false;
    DWORD written = 0;
    bool result = WriteFile(file, bytes, playerConfigSize, &written, nullptr) != FALSE;
    DWORD error = result ? ERROR_WRITE_FAULT : GetLastError();
    result = result && written == playerConfigSize;
    if (result && !FlushFileBuffers(file)) { result = false; error = GetLastError(); }
    if (!CloseHandle(file) && result) { result = false; error = GetLastError(); }
    // Never truncate the previous configuration before a complete new copy
    // exists. Both files live in the same game-relative directory/volume.
    if (result && !MoveFileExW(temporary, path, MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) {
        result = false;
        error = GetLastError();
    }
    if (!result) { DeleteFileW(temporary); SetLastError(error); }
    return result;
}

static bool persistPlayerConfig() {
    if (!InterlockedCompareExchange(&playerConfigReady, 0, 0)) return true;
    AcquireSRWLockExclusive(&playerSaveLock);
    BYTE snapshot[playerConfigSize];
    memcpy(snapshot, gameBase + 0x124df0, sizeof(snapshot));
    wchar_t path[32768];
    bool result = swprintf_s(path, L"%s\\GAMEDATA\\CONFIG\\CONFIG.DAT", gameRoot) >= 0;
    if (result) result = writePlayerConfig(path, snapshot);
    else SetLastError(ERROR_FILENAME_EXCED_RANGE);
    const DWORD error = result ? ERROR_SUCCESS : GetLastError();
    ReleaseSRWLockExclusive(&playerSaveLock);
    logMessage("Player configuration checkpoint: %s; bytes=%lu; error=%lu\r\n",
        result ? "saved" : "FAILED", playerConfigSize, error);
    if (!result && InterlockedCompareExchange(&playerSaveWarning, 1, 0) == 0) {
        showPlayerSaveWarning(nullptr,
            L"Your player name, settings or records could not be saved. "
            L"Make sure the game folder is writable. Existing saved data was kept.",
            L"The Need for Speed: Special Edition", MB_OK | MB_ICONWARNING);
    }
    SetLastError(error);
    return result;
}

static void WINAPI portableExitProcess(UINT code) {
    persistPlayerConfig();
    realExitProcess(code);
}

static int __cdecl checkPlayerFreeSpace(DWORD requested) {
    ULARGE_INTEGER available = {};
    if (!queryPlayerFreeSpace(gameRoot, &available, nullptr, nullptr)) {
        logMessage("Save-space query failed: error=%lu\r\n", GetLastError());
        return 0;
    }
    return available.QuadPart >= requested ? 1 : 0;
}

// Watcom's register convention is different from MSVC's. These bridges keep
// every original register and flag, including the loader/name return in EAX.
static void __declspec(naked) loadPlayerConfig() {
    __asm {
        call dword ptr [originalLoadPlayerConfig]
        pushfd
        pushad
        mov eax, 1
        xchg eax, dword ptr [playerConfigReady]
        popad
        popfd
        ret
    }
}
static void __declspec(naked) savePlayerConfig() {
    __asm {
        pushfd
        pushad
        call persistPlayerConfig
        popad
        popfd
        ret
    }
}
static void __declspec(naked) enterPlayerName() {
    __asm {
        call dword ptr [originalEnterPlayerName]
        pushfd
        pushad
        test ax, ax
        jz cancelled
        call persistPlayerConfig
    cancelled:
        popad
        popfd
        ret
    }
}
static void __declspec(naked) playerFreeSpace() {
    __asm {
        pushfd
        pushad
        push eax
        call checkPlayerFreeSpace
        add esp, 4
        mov dword ptr [esp + 28], eax
        popad
        popfd
        ret
    }
}

static bool configurePlayerPersistence(BYTE* base) {
    const struct { DWORD rva, target; void* replacement; } calls[] = {
        {0x373e7, 0x2a010, &loadPlayerConfig}, {0x374d4, 0x2a010, &loadPlayerConfig},
        {0x432b, 0x2a504, &savePlayerConfig}, {0x37499, 0x2a504, &savePlayerConfig},
        {0x37520, 0x2a504, &savePlayerConfig},
        {0x37431, 0x667fc, &enterPlayerName}, {0x37bd3, 0x667fc, &enterPlayerName},
        {0x37c0b, 0x667fc, &enterPlayerName}, {0x37cf4, 0x667fc, &enterPlayerName},
        {0x2a511, 0x6733c, &playerFreeSpace}, {0x2a58d, 0x6733c, &playerFreeSpace},
        {0x2a64b, 0x6733c, &playerFreeSpace}, {0x3cad9, 0x6733c, &playerFreeSpace},
        {0x3d22a, 0x6733c, &playerFreeSpace}, {0x51aef, 0x6733c, &playerFreeSpace}
    };
    // Validate the complete set before changing any call site.
    for (const auto& call : calls) {
        if (base[call.rva] != 0xe8 || *reinterpret_cast<LONG*>(base + call.rva + 1) !=
            static_cast<LONG>(call.target - call.rva - 5)) {
            logMessage("Unexpected player persistence call at RVA %08lX\r\n", call.rva);
            return false;
        }
    }
    originalLoadPlayerConfig = base + 0x2a010;
    originalEnterPlayerName = base + 0x667fc;
    for (const auto& call : calls) {
        if (!replaceCall(base, call.rva, call.target, call.replacement)) return false;
    }
    for (DWORD slot : {0x131300u, 0x131514u}) {
        if (!replaceImport(base, slot, reinterpret_cast<void*>(&portableExitProcess),
            reinterpret_cast<void**>(&realExitProcess))) return false;
    }
    logMessage("Player name, configuration checkpoints and 64-bit save-space checks installed\r\n");
    return true;
}
