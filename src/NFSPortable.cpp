#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <cstdio>
#include <cstdarg>
#include <algorithm>

static HANDLE logFile = INVALID_HANDLE_VALUE;
static decltype(&GlobalMemoryStatus) realMemoryStatus;
static decltype(&CreateWindowExA) realCreateWindow;
static decltype(&RegisterClassA) realRegisterClass;
static WNDPROC gameWindowProc;
static volatile LONG memoryLogCount;
static BYTE* gameBase;
static HANDLE windowReady;
static CRITICAL_SECTION* presentationLock;
static wchar_t gameRoot[32768];
static decltype(&LoadLibraryA) realDplayLoadLibrary;
static decltype(&CreateFileA) realCreateFile;
static decltype(&ReadFile) realReadFile;
static void logMessage(const char* format, ...);

static bool verifyGraphicsSetting(BYTE* graphics, DWORD keyRva, const char* key,
    DWORD loadRva, DWORD readRva, DWORD storeRva, DWORD settingRva) {
    // Verify the key, its cfg_get_int/bool call, and the relocated store into
    // g_config before using a private setting in the pinned renderer build.
    return strcmp(reinterpret_cast<const char*>(graphics + keyRva), key) == 0 &&
        graphics[loadRva] == 0xb9 &&
        *reinterpret_cast<DWORD*>(graphics + loadRva + 1) == reinterpret_cast<DWORD>(graphics + keyRva) &&
        graphics[loadRva + 5] == 0xe8 &&
        *reinterpret_cast<LONG*>(graphics + loadRva + 6) == static_cast<LONG>(readRva - loadRva - 10) &&
        graphics[storeRva] == 0xa3 &&
        *reinterpret_cast<DWORD*>(graphics + storeRva + 1) == reinterpret_cast<DWORD>(graphics + settingRva);
}

static bool configureWindowPresentation(BYTE* graphics, DWORD desktopHeight) {
    auto dos = reinterpret_cast<IMAGE_DOS_HEADER*>(graphics);
    auto nt = reinterpret_cast<IMAGE_NT_HEADERS32*>(graphics + dos->e_lfanew);
    if (dos->e_magic != IMAGE_DOS_SIGNATURE || nt->Signature != IMAGE_NT_SIGNATURE ||
        nt->FileHeader.Machine != IMAGE_FILE_MACHINE_I386 ||
        nt->FileHeader.TimeDateStamp != 0x676faadf || nt->OptionalHeader.SizeOfImage != 0x6c000 ||
        !verifyGraphicsSetting(graphics, 0x48250, "width", 0x1e0b7, 0x1ef70, 0x1e0c3, 0x58b88) ||
        !verifyGraphicsSetting(graphics, 0x48258, "height", 0x1e0c8, 0x1ef70, 0x1e0d4, 0x58b8c) ||
        !verifyGraphicsSetting(graphics, 0x48318, "border", 0x1e295, 0x1eea0, 0x1e2a4, 0x596fc) ||
        !verifyGraphicsSetting(graphics, 0x48330, "resizable", 0x1e2bd, 0x1eea0, 0x1e2cc, 0x59704)) {
        logMessage("Unexpected cnc-ddraw window configuration layout\r\n");
        return false;
    }
    // cnc-ddraw reads ddraw.ini in DllMain, before our bootstrap. Apply the
    // launch policy to its already-loaded settings before any game window or
    // rendering thread starts; the on-disk configuration stays untouched.
    *reinterpret_cast<BOOL*>(graphics + 0x596fc) = TRUE;
    if (desktopHeight > 960) {
        *reinterpret_cast<LONG*>(graphics + 0x58b88) = 1280;
        *reinterpret_cast<LONG*>(graphics + 0x58b8c) = 960;
        *reinterpret_cast<BOOL*>(graphics + 0x59704) = FALSE;
    }
    logMessage("Window presentation: desktop height=%lu; client=%ldx%ld; border=true; resizable=%ld\r\n",
        desktopHeight, *reinterpret_cast<LONG*>(graphics + 0x58b88),
        *reinterpret_cast<LONG*>(graphics + 0x58b8c), *reinterpret_cast<BOOL*>(graphics + 0x59704));
    return true;
}

static void releaseGameKeys(HWND window) {
    // The original WM_KEYUP handler clears one entry in its 128-scan-code
    // table. Release through that handler instead of editing game memory.
    // A key released outside the window never reaches that handler normally.
    for (UINT scan = 1; scan < 128; ++scan) {
        const WPARAM key = MapVirtualKeyA(scan, MAPVK_VSC_TO_VK);
        const LPARAM flags = static_cast<LPARAM>(0xc0000001u | (scan << 16));
        CallWindowProcA(gameWindowProc, window, WM_KEYUP, key, flags);
    }
    // Clear this window thread's stale pressed state too. Otherwise Enter can
    // remain a system key and cnc-ddraw consumes it as Alt+Enter. Retain the
    // toggle bits for Caps Lock / Num Lock / Scroll Lock; no global input is sent.
    BYTE keys[256];
    if (GetKeyboardState(keys)) {
        for (BYTE& key : keys) key &= 1;
        SetKeyboardState(keys);
    }
    logMessage("Released stale keyboard state on focus transition\r\n");
}

static LRESULT CALLBACK portableWindowProc(HWND window, UINT message,
    WPARAM key, LPARAM flags) {
    if (message == WM_KILLFOCUS || message == WM_SETFOCUS) releaseGameKeys(window);
    if (message == WM_SYSKEYDOWN && key == VK_F4 && (flags & (1u << 29))) {
        // The original consumes system-key messages before DefWindowProc can
        // turn Alt+F4 into SC_CLOSE. Match cnc-ddraw's immediate close behavior.
        logMessage("Alt+F4: closing game\r\n");
        ExitProcess(0);
    }
    return CallWindowProcA(gameWindowProc, window, message, key, flags);
}

static ATOM WINAPI portableRegisterClass(const WNDCLASSA* description) {
    if (!description || reinterpret_cast<ULONG_PTR>(description->lpszClassName) <= 0xffff ||
        strcmp(description->lpszClassName, "EACLibWindow") != 0) {
        return realRegisterClass(description);
    }
    // This class is the supported game's message dispatcher. cnc-ddraw later
    // wraps it, keeping its scaling, mouse handling and Alt+Enter hook intact.
    if (description->lpfnWndProc != reinterpret_cast<WNDPROC>(gameBase + 0x9bb7c)) {
        logMessage("Unexpected EACLibWindow message dispatcher\r\n");
        SetLastError(ERROR_INVALID_DATA);
        return 0;
    }
    WNDCLASSA portable = *description;
    gameWindowProc = description->lpfnWndProc;
    portable.lpfnWndProc = portableWindowProc;
    return realRegisterClass(&portable);
}

static HANDLE WINAPI portableCreateFile(LPCSTR name, DWORD access, DWORD share,
    LPSECURITY_ATTRIBUTES security, DWORD disposition, DWORD flags, HANDLE templateFile) {
    if (name && disposition == OPEN_EXISTING && (flags & FILE_FLAG_NO_BUFFERING) &&
        strncmp(name, "\\\\.\\", 4) != 0) {
        flags &= ~FILE_FLAG_NO_BUFFERING;
        logMessage("Buffered legacy file stream: %s\r\n", name);
    }
    return realCreateFile(name, access, share, security, disposition, flags, templateFile);
}

static BOOL WINAPI portableReadFile(HANDLE file, LPVOID buffer, DWORD count,
    LPDWORD read, LPOVERLAPPED overlapped) {
    BOOL result = realReadFile(file, buffer, count, read, overlapped);
    const DWORD error = GetLastError();
    if (!result && error != ERROR_IO_PENDING) logMessage("ReadFile failed: handle=%p count=%lu error=%lu\r\n", file, count, error);
    SetLastError(error);
    return result;
}

static void logMessage(const char* format, ...) {
    if (logFile == INVALID_HANDLE_VALUE) return;
    char text[1024];
    va_list args;
    va_start(args, format);
    int length = _vsnprintf_s(text, sizeof(text), _TRUNCATE, format, args);
    va_end(args);
    if (length < 0) length = static_cast<int>(strlen(text));
    DWORD written;
    WriteFile(logFile, text, static_cast<DWORD>(length), &written, nullptr);
    FlushFileBuffers(logFile);
}

static void WINAPI portableMemoryStatus(LPMEMORYSTATUS status) {
    realMemoryStatus(status);
    const MEMORYSTATUS before = *status;
    // The game's signed 32-bit comparisons cannot handle contemporary RAM totals.
    status->dwTotalPhys = std::min<SIZE_T>(status->dwTotalPhys, 512u * 1024 * 1024);
    status->dwAvailPhys = std::min<SIZE_T>(status->dwAvailPhys, 256u * 1024 * 1024);
    status->dwTotalPageFile = std::min<SIZE_T>(status->dwTotalPageFile, 0x7fffffffu);
    status->dwAvailPageFile = std::min<SIZE_T>(status->dwAvailPageFile, 0x7fffffffu);
    status->dwTotalVirtual = std::min<SIZE_T>(status->dwTotalVirtual, 0x7fffffffu);
    status->dwAvailVirtual = std::min<SIZE_T>(status->dwAvailVirtual, 0x7fffffffu);
    if (InterlockedIncrement(&memoryLogCount) <= 3) {
        logMessage("GlobalMemoryStatus phys=%lu/%lu -> %lu/%lu, virtual=%lu/%lu\r\n",
            static_cast<DWORD>(before.dwAvailPhys), static_cast<DWORD>(before.dwTotalPhys),
            static_cast<DWORD>(status->dwAvailPhys), static_cast<DWORD>(status->dwTotalPhys),
            static_cast<DWORD>(status->dwAvailVirtual), static_cast<DWORD>(status->dwTotalVirtual));
    }
}

static HWND WINAPI portableCreateWindow(DWORD exStyle, LPCSTR className, LPCSTR title,
    DWORD style, int x, int y, int width, int height, HWND parent, HMENU menu,
    HINSTANCE instance, LPVOID parameter) {
    const bool gameWindow = reinterpret_cast<ULONG_PTR>(className) > 0xffff &&
        strcmp(className, "EACLibWindow") == 0;
    const int requestedWidth = width, requestedHeight = height;
    if (gameWindow && (width <= 0 || width > 4096 || height <= 0 || height > 4096)) {
        width = 640;
        height = 480;
        x = y = 0;
    }
    HWND window = realCreateWindow(exStyle, className, title, style, x, y, width, height,
        parent, menu, instance, parameter);
    if (gameWindow) {
        logMessage("CreateWindow requested=%dx%d used=%dx%d hwnd=%p error=%lu\r\n",
            requestedWidth, requestedHeight, width, height, window, GetLastError());
    }
    return window;
}

static bool replaceImport(BYTE* base, DWORD rva, void* replacement, void** original) {
    auto slot = reinterpret_cast<void**>(base + rva);
    DWORD protection;
    if (!VirtualProtect(slot, sizeof(*slot), PAGE_READWRITE, &protection)) return false;
    *original = *slot;
    *slot = replacement;
    DWORD ignored;
    VirtualProtect(slot, sizeof(*slot), protection, &ignored);
    return true;
}

static HMODULE WINAPI loadDplayProvider(LPCSTR filename) {
    if (!filename) return realDplayLoadLibrary(filename);
    const char* name = strrchr(filename, '\\');
    name = name ? name + 1 : filename;
    const bool bundled = _stricmp(name, "dpwsock.dll") == 0 ||
        _stricmp(name, "dpserial.dll") == 0 || _stricmp(name, "dpwsockx.dll") == 0 ||
        _stricmp(name, "dpmodemx.dll") == 0;
    if (bundled) {
        wchar_t path[32768];
        wchar_t wideName[64];
        if (MultiByteToWideChar(CP_ACP, 0, name, -1, wideName, ARRAYSIZE(wideName)) &&
            swprintf_s(path, L"%s\\%s", gameRoot, wideName) >= 0) {
            HMODULE module = LoadLibraryW(path);
            logMessage("DirectPlay local provider %s: module=%p error=%lu\r\n", name, module, module ? 0 : GetLastError());
            return module;
        }
    }
    return realDplayLoadLibrary(filename);
}

static bool replaceDword(BYTE* base, DWORD rva, DWORD expected, DWORD replacement) {
    auto value = reinterpret_cast<DWORD*>(base + rva);
    if (*value != expected) {
        logMessage("Unexpected scratch reference at RVA %08lX: %08lX\r\n", rva, *value);
        return false;
    }
    DWORD protection;
    if (!VirtualProtect(value, sizeof(*value), PAGE_EXECUTE_READWRITE, &protection)) return false;
    *value = replacement;
    DWORD ignored;
    VirtualProtect(value, sizeof(*value), protection, &ignored);
    FlushInstructionCache(GetCurrentProcess(), value, sizeof(*value));
    return true;
}

static DWORD __cdecl startWindowThread(void* function, DWORD a, DWORD b, DWORD c, DWORD* threadId) {
    ResetEvent(windowReady);
    auto original = reinterpret_cast<DWORD (__cdecl*)(void*, DWORD, DWORD, DWORD, DWORD*)>(gameBase + 0x76820);
    return original(function, a, b, c, threadId);
}

static int __cdecl finishWindowInitialization() {
    auto original = reinterpret_cast<int (__cdecl*)()>(gameBase + 0x774b0);
    const int result = original();
    logMessage("Window graphics initialization completed: result=%d, thread=%lu\r\n", result, GetCurrentThreadId());
    SetEvent(windowReady);
    return result;
}

static DWORD __cdecl waitWindowInitialization(DWORD) {
    // The original waits two 1ms sleeps, then publishes an HWND before the
    // worker has initialized graphics. Later mode changes can free its object.
    const DWORD result = WaitForSingleObject(windowReady, 30000);
    logMessage("Main thread waited for graphics initialization: result=%lu\r\n", result);
    return result;
}

static bool replaceCall(BYTE* base, DWORD rva, DWORD originalTarget, void* replacement) {
    if (base[rva] != 0xe8 || *reinterpret_cast<LONG*>(base + rva + 1) !=
        static_cast<LONG>(originalTarget - rva - 5)) return false;
    return replaceDword(base, rva + 1, originalTarget - rva - 5,
        reinterpret_cast<DWORD>(replacement) - reinterpret_cast<DWORD>(base + rva + 5));
}

static bool replaceIndirectCall(BYTE* base, DWORD rva, DWORD slotRva, void* replacement) {
    BYTE* code = base + rva;
    if (code[0] != 0xff || code[1] != 0x15 ||
        *reinterpret_cast<DWORD*>(code + 2) != reinterpret_cast<DWORD>(base + slotRva)) return false;
    DWORD protection;
    if (!VirtualProtect(code, 6, PAGE_EXECUTE_READWRITE, &protection)) return false;
    code[0] = 0xe8;
    *reinterpret_cast<DWORD*>(code + 1) = reinterpret_cast<DWORD>(replacement) - reinterpret_cast<DWORD>(code + 5);
    code[5] = 0x90;
    DWORD ignored;
    VirtualProtect(code, 6, protection, &ignored);
    FlushInstructionCache(GetCurrentProcess(), code, 6);
    return true;
}

static void __cdecl beginVideoPaletteUpdate() {
    EnterCriticalSection(presentationLock);
}

static void __cdecl endVideoPaletteUpdate() {
    LeaveCriticalSection(presentationLock);
}

static LONG CALLBACK logException(EXCEPTION_POINTERS* exception) {
    const DWORD code = exception->ExceptionRecord->ExceptionCode;
    if (code == EXCEPTION_ACCESS_VIOLATION || code == EXCEPTION_ILLEGAL_INSTRUCTION ||
        code == EXCEPTION_PRIV_INSTRUCTION ||
        code == EXCEPTION_INT_DIVIDE_BY_ZERO) {
        logMessage("Exception %08lX at %p; EIP=%08lX ESP=%08lX EAX=%08lX EBX=%08lX ECX=%08lX EDX=%08lX\r\n",
            code, exception->ExceptionRecord->ExceptionAddress, exception->ContextRecord->Eip,
            exception->ContextRecord->Esp, exception->ContextRecord->Eax, exception->ContextRecord->Ebx,
            exception->ContextRecord->Ecx, exception->ContextRecord->Edx);
    }
    return EXCEPTION_CONTINUE_SEARCH;
}

extern "C" __declspec(dllexport) BOOL WINAPI Initialize() {
    BYTE* base = reinterpret_cast<BYTE*>(GetModuleHandleW(nullptr));
    auto dos = reinterpret_cast<IMAGE_DOS_HEADER*>(base);
    auto nt = reinterpret_cast<IMAGE_NT_HEADERS32*>(base + dos->e_lfanew);
    // Fail closed on another executable; these import RVAs are build-specific.
    if (dos->e_magic != IMAGE_DOS_SIGNATURE || nt->Signature != IMAGE_NT_SIGNATURE ||
        nt->FileHeader.TimeDateStamp != 0x31c4f35c || nt->FileHeader.Machine != IMAGE_FILE_MACHINE_I386) {
        return FALSE;
    }
    wchar_t root[32768];
    DWORD length = GetModuleFileNameW(nullptr, root, ARRAYSIZE(root));
    if (!length || length >= ARRAYSIZE(root)) return FALSE;
    wchar_t* separator = wcsrchr(root, L'\\');
    if (!separator) return FALSE;
    *separator = L'\0';
    if (!SetCurrentDirectoryW(root)) return FALSE;
    wcscpy_s(gameRoot, root);

    logFile = CreateFileW(L"portable-runtime.log", GENERIC_WRITE, FILE_SHARE_READ,
        nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    logMessage("NFSPortable 5; image=%p; executable-relative working directory established\r\n", base);
    gameBase = base;
    windowReady = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    if (!windowReady) return FALSE;

    // Relocate only verified legacy VGA/debug pointers. Fixed-point physics
    // constants with similar values must retain their original values.
    void* scratch = VirtualAlloc(nullptr, 0x10000, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
    if (!scratch) {
        logMessage("Scratch allocation failed, error=%lu\r\n", GetLastError());
        return FALSE;
    }
    const DWORD scratchAddress = reinterpret_cast<DWORD>(scratch);
    if (!replaceDword(base, 0x494ff + 2, 0xb0000, scratchAddress) ||
        !replaceDword(base, 0x4cf8e + 1, 0xb0000, scratchAddress) ||
        !replaceDword(base, 0x4cfc0 + 1, 0xb00a0, scratchAddress + 0xa0) ||
        !replaceDword(base, 0x8a4b3 + 1, 0xb0000, scratchAddress) ||
        !replaceDword(base, 0xc7884, 0xb0000, scratchAddress)) return FALSE;
    logMessage("Legacy scratch references relocated to %p\r\n", scratch);
    // Keep the game's window dimensions coherent with the bounded CreateWindow.
    if (!replaceDword(base, 0x7787c + 1, 10000, 480) ||
        !replaceDword(base, 0x77881 + 1, 10000, 640)) return FALSE;
    // Standalone DOS-era interrupt helpers are invalid in a Windows process.
    // Preserve each RET and remove only the verified CLI/STI instructions.
    if (!replaceDword(base, 0x8ed2a, 0xc3fbc3fa, 0xc390c390)) return FALSE;
    if (!replaceImport(base, 0x13135c, reinterpret_cast<void*>(&portableMemoryStatus),
        reinterpret_cast<void**>(&realMemoryStatus))) return FALSE;
    if (!replaceImport(base, 0x1311a0, reinterpret_cast<void*>(&portableCreateWindow),
        reinterpret_cast<void**>(&realCreateWindow))) return FALSE;
    if (!replaceImport(base, 0x1311e0, reinterpret_cast<void*>(&portableRegisterClass),
        reinterpret_cast<void**>(&realRegisterClass))) return FALSE;
    logMessage("Focus recovery and Alt+F4 window hook installed\r\n");
    for (DWORD slot : {0x1312e8u, 0x131504u}) {
        if (!replaceImport(base, slot, reinterpret_cast<void*>(&portableCreateFile),
            reinterpret_cast<void**>(&realCreateFile))) return FALSE;
    }
    for (DWORD slot : {0x13136cu, 0x131574u}) {
        if (!replaceImport(base, slot, reinterpret_cast<void*>(&portableReadFile),
            reinterpret_cast<void**>(&realReadFile))) return FALSE;
    }
    BYTE* dplay = reinterpret_cast<BYTE*>(GetModuleHandleW(L"DPLAY.dll"));
    if (!dplay) return FALSE;
    auto dplayDos = reinterpret_cast<IMAGE_DOS_HEADER*>(dplay);
    auto dplayNt = reinterpret_cast<IMAGE_NT_HEADERS32*>(dplay + dplayDos->e_lfanew);
    if (dplayDos->e_magic != IMAGE_DOS_SIGNATURE || dplayNt->Signature != IMAGE_NT_SIGNATURE ||
        dplayNt->FileHeader.TimeDateStamp != 0x31a17ff9 || dplayNt->FileHeader.Machine != IMAGE_FILE_MACHINE_I386) return FALSE;
    realDplayLoadLibrary = *reinterpret_cast<decltype(realDplayLoadLibrary)*>(dplay + 0xb0d4);
    // A graphics wrapper may rebind imported LoadLibraryA slots. Redirect the
    // verified provider-loading call itself so local provider paths stay intact.
    if (!replaceIndirectCall(dplay, 0x11e9, 0xb0d4, reinterpret_cast<void*>(&loadDplayProvider))) return FALSE;
    BYTE* graphics = reinterpret_cast<BYTE*>(GetModuleHandleW(L"ddraw.dll"));
    if (!graphics) return FALSE;
    auto graphicsDos = reinterpret_cast<IMAGE_DOS_HEADER*>(graphics);
    auto graphicsNt = reinterpret_cast<IMAGE_NT_HEADERS32*>(graphics + graphicsDos->e_lfanew);
    // This synchronization point belongs to the bundled cnc-ddraw 7.1.0.0.
    // Verify its build and the InitializeCriticalSection argument before using it.
    if (graphicsNt->FileHeader.TimeDateStamp != 0x676faadf ||
        graphicsNt->OptionalHeader.SizeOfImage != 0x6c000 || graphics[0x6949] != 0x68 ||
        *reinterpret_cast<DWORD*>(graphics + 0x694a) != reinterpret_cast<DWORD>(graphics + 0x5f190)) return FALSE;
    // The ANSI display query and GetSystemMetrics can be hooked by cnc-ddraw
    // to report the game mode. Its hook list leaves the Unicode query intact.
    DEVMODEW desktop = {};
    desktop.dmSize = sizeof(desktop);
    if (!EnumDisplaySettingsW(nullptr, ENUM_CURRENT_SETTINGS, &desktop) || !desktop.dmPelsHeight) {
        logMessage("Could not read the current desktop resolution: error=%lu\r\n", GetLastError());
        return FALSE;
    }
    if (!configureWindowPresentation(graphics, desktop.dmPelsHeight)) return FALSE;
    presentationLock = reinterpret_cast<CRITICAL_SECTION*>(graphics + 0x5f190);
    if (!replaceCall(base, 0x42473, 0x8ed2a, reinterpret_cast<void*>(&beginVideoPaletteUpdate)) ||
        !replaceCall(base, 0x424a1, 0x8ed2c, reinterpret_cast<void*>(&endVideoPaletteUpdate))) return FALSE;
    logMessage("Video frame and palette presentation synchronization installed\r\n");
    AddVectoredExceptionHandler(0, logException);
    if (!replaceCall(base, 0x9c19a, 0x76820, reinterpret_cast<void*>(&startWindowThread)) ||
        !replaceCall(base, 0x9bde0, 0x774b0, reinterpret_cast<void*>(&finishWindowInitialization)) ||
        !replaceCall(base, 0x9c1f7, 0x76914, reinterpret_cast<void*>(&waitWindowInitialization))) return FALSE;
    logMessage("Window initialization synchronization installed\r\n");
    logMessage("Memory-status and initial-window compatibility hooks installed\r\n");
    return TRUE;
}

BOOL WINAPI DllMain(HINSTANCE, DWORD reason, LPVOID) {
    if (reason == DLL_PROCESS_DETACH && logFile != INVALID_HANDLE_VALUE) CloseHandle(logFile);
    return TRUE;
}
