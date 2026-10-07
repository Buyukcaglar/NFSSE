// Native language selection; the accepted game engine and helper stay intact.
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <wincrypt.h>
#include <algorithm>
#include <cstdio>
#include <string>
#include <vector>
#include <stdexcept>

using Bytes = std::vector<BYTE>;
enum class Language { English, German, Japanese };
static const char* voiceNames[] = {"FINALLAP.EAS", "BESTTIME.EAS", "FIRST.EAS",
    "SECOND.EAS", "THIRD.EAS", "FOURTH.EAS", "FIFTH.EAS", "SIXTH.EAS",
    "SEVENTH.EAS", "EIGHTH.EAS", "BESTLAST.EAS"};
static const char* basePaths[] = {"gamedata/config/", "gamedata/savegame/",
    "frontend/speech/", "simdata/soundbnk/", "frontend/music/", "frontend/art/",
    "gamedata/modem/", "frontend/movie/", "gamedata/replay/", "simdata/misc/",
    "simdata/etrackfm/", "simdata/ntrackfm/", "simdata/slides/", "simdata/carfams/",
    "simdata/soundbnk/", "simdata/carspecs/", "simdata/dash/", "simdata/misc/",
    "frontend/show/"};

struct Handle {
    HANDLE value;
    explicit Handle(HANDLE v = INVALID_HANDLE_VALUE) : value(v) {}
    ~Handle() { if (value != INVALID_HANDLE_VALUE && value) CloseHandle(value); }
    Handle(const Handle&) = delete;
    Handle& operator=(const Handle&) = delete;
};
static void require(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}
static std::wstring wide(const std::string& s) { return std::wstring(s.begin(), s.end()); }
static bool safeRelative(const std::string& path) {
    if (path.empty() || path.front() == '/' || path.back() == '/') return false;
    for (unsigned char c : path) if (c < 32 || c > 126 || c == ':' || c == '\\') return false;
    size_t start = 0;
    do {
        size_t end = path.find('/', start);
        std::string part = path.substr(start, end - start);
        if (part.empty() || part == "." || part == ".." || part.back() == '.' || part.back() == ' ') return false;
        if (end == std::string::npos) break;
        start = end + 1;
    } while (true);
    return true;
}
static std::wstring localPath(const std::wstring& root, const std::string& relative) {
    require(safeRelative(relative), "The language inventory contains an invalid path.");
    std::wstring path = root;
    DWORD attributes = GetFileAttributesW(path.c_str());
    require(attributes != INVALID_FILE_ATTRIBUTES && !(attributes & FILE_ATTRIBUTE_REPARSE_POINT),
        "The game folder must be an ordinary local folder.");
    size_t start = 0;
    while (true) {
        size_t end = relative.find('/', start);
        path += L"\\" + wide(relative.substr(start, end - start));
        attributes = GetFileAttributesW(path.c_str());
        require(attributes != INVALID_FILE_ATTRIBUTES && !(attributes & FILE_ATTRIBUTE_REPARSE_POINT),
            "A required game file is missing or linked. Restore the complete installation.");
        if (end == std::string::npos) break;
        require((attributes & FILE_ATTRIBUTE_DIRECTORY) != 0, "A game directory is invalid.");
        start = end + 1;
    }
    return path;
}
static Bytes readBytes(const std::wstring& path, DWORD limit = 1024 * 1024) {
    Handle file(CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
        OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr));
    require(file.value != INVALID_HANDLE_VALUE, "A game file cannot be read. Close the game and try again.");
    LARGE_INTEGER size;
    require(GetFileSizeEx(file.value, &size) && size.QuadPart >= 0 && size.QuadPart <= limit,
        "A game configuration file has an unexpected size.");
    Bytes bytes(static_cast<size_t>(size.QuadPart));
    DWORD count = 0;
    require(ReadFile(file.value, bytes.data(), static_cast<DWORD>(bytes.size()), &count, nullptr)
        && count == bytes.size(), "A game file could not be read completely.");
    return bytes;
}
static std::string hashFile(const std::wstring& path) {
    Handle file(CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
        OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, nullptr));
    require(file.value != INVALID_HANDLE_VALUE, "A language resource cannot be read.");
    HCRYPTPROV provider = 0; HCRYPTHASH hash = 0;
    require(CryptAcquireContextW(&provider, nullptr, nullptr, PROV_RSA_AES, CRYPT_VERIFYCONTEXT) != FALSE,
        "Windows could not verify the game files.");
    try {
        require(CryptCreateHash(provider, CALG_SHA_256, 0, 0, &hash) != FALSE, "Windows hash creation failed.");
        BYTE buffer[65536]; DWORD count;
        do {
            require(ReadFile(file.value, buffer, sizeof(buffer), &count, nullptr) != FALSE, "Resource reading failed.");
            require(CryptHashData(hash, buffer, count, 0) != FALSE, "Resource verification failed.");
        } while (count);
        BYTE digest[32]; DWORD size = sizeof(digest);
        require(CryptGetHashParam(hash, HP_HASHVAL, digest, &size, 0) != FALSE, "Resource hash failed.");
        std::string result;
        for (BYTE b : digest) { result += "0123456789abcdef"[b >> 4]; result += "0123456789abcdef"[b & 15]; }
        CryptDestroyHash(hash); CryptReleaseContext(provider, 0);
        return result;
    } catch (...) { if (hash) CryptDestroyHash(hash); CryptReleaseContext(provider, 0); throw; }
}
static char languageCode(Language language) {
    return language == Language::German ? 'D' : language == Language::Japanese ? 'J' : 'E';
}
static Bytes pathTable(Language language) {
    const char* paths[19]; std::copy(std::begin(basePaths), std::end(basePaths), paths);
    if (language == Language::German) {
        paths[2] = "frontend/gspeech/"; paths[5] = "frontend/gart/";
        paths[10] = "simdata/gtrackfm/"; paths[12] = "simdata/gslides/";
        paths[16] = "simdata/gdash/"; paths[18] = "frontend/gshow/";
    } else if (language == Language::Japanese) {
        paths[2] = "lang/ja/speech/"; paths[5] = "lang/ja/art/";
        paths[9] = paths[17] = "lang/ja/misc/"; paths[18] = "lang/ja/show/";
    }
    Bytes bytes(1520, 0);
    for (size_t i = 0; i < 19; ++i) std::copy(paths[i], paths[i] + strlen(paths[i]), bytes.begin() + i * 80);
    return bytes;
}
static bool knownPaths(Bytes bytes) {
    // Existing v0.1.5 tables retain mixed case in three original directory names.
    for (BYTE& b : bytes) if (b >= 'A' && b <= 'Z') b += 'a' - 'A';
    return bytes == pathTable(Language::English) || bytes == pathTable(Language::German)
        || bytes == pathTable(Language::Japanese);
}
static Bytes languageConfig(const Bytes& bytes, Language language) {
    require(!bytes.empty() && bytes.size() <= 80, "nfs.cfg must contain the four original game settings.");
    std::string text(bytes.begin(), bytes.end());
    std::vector<std::pair<size_t, size_t>> tokens;
    size_t position = 0;
    while (position < text.size()) {
        if (text[position] == ' ' || text[position] == '\r' || text[position] == '\n') { ++position; continue; }
        size_t start = position;
        while (position < text.size() && text[position] != ' ' && text[position] != '\r' && text[position] != '\n') {
            require(text[position] >= 33 && text[position] <= 126, "nfs.cfg contains unsupported characters."); ++position;
        }
        require(position < text.size() && text[position] == ' ', "Each nfs.cfg option must end with a space.");
        tokens.emplace_back(start, position - start);
    }
    require(tokens.size() == 4, "nfs.cfg must contain the four original game settings.");
    auto token = [&](size_t i) { return text.substr(tokens[i].first, tokens[i].second); };
    require(token(0) == "YESSOUND" || token(0) == "NOSOUND", "The nfs.cfg sound option is unrecognized.");
    require(token(1) == "HIGHVIDEO" || token(1) == "LOWVIDEO" || token(1) == "NOVIDEO", "The nfs.cfg video option is unrecognized.");
    require(token(2) == "ENGLISH" || token(2) == "GERMAN", "The nfs.cfg language option is unrecognized.");
    text.replace(tokens[2].first, tokens[2].second, language == Language::German ? "GERMAN" : "ENGLISH");
    require(text.size() <= 80, "The resulting nfs.cfg is too long for the original parser.");
    return Bytes(text.begin(), text.end());
}
struct InventoryRecord { char group; std::string hash, path; };
static std::vector<InventoryRecord> readInventory(const std::wstring& root) {
    Bytes bytes = readBytes(localPath(root, "LANG/language-edition.index"));
    std::string text(bytes.begin(), bytes.end());
    require(text.substr(0, 18) == "NFSSE-LANGUAGES-1\n", "The language installation inventory is invalid.");
    size_t start = 18; std::vector<InventoryRecord> records;
    while (start < text.size()) {
        size_t end = text.find('\n', start);
        require(end != std::string::npos, "The language inventory is truncated.");
        std::string line = text.substr(start, end - start); start = end + 1;
        require(line.size() > 67 && line[1] == '\t' && line[66] == '\t'
            && std::string("CEDJ").find(line[0]) != std::string::npos, "The language inventory record is invalid.");
        InventoryRecord r{line[0], line.substr(2, 64), line.substr(67)};
        require(r.hash.find_first_not_of("0123456789abcdef") == std::string::npos && safeRelative(r.path),
            "The language inventory record is unsafe.");
        for (const auto& other : records) require(other.path != r.path || other.group != r.group,
            "The language inventory contains duplicate records.");
        records.push_back(r);
    }
    require(!records.empty(), "The language inventory is empty.");
    return records;
}
static void verifyInventory(const std::wstring& root, Language language) {
    const auto records = readInventory(root); size_t common = 0, selected = 0;
    for (const auto& record : records) {
        if (record.group != 'C' && record.group != languageCode(language)) continue;
        std::string actual = hashFile(localPath(root, record.path));
        if (actual != record.hash) throw std::runtime_error("A game resource has changed: " + record.path);
        if (record.group == 'C') ++common; else ++selected;
    }
    require(common >= 3 && selected >= 11, "This language installation is incomplete.");
}
static bool languageAvailable(const std::wstring& root, Language language) {
    size_t count = 0;
    for (const auto& record : readInventory(root)) if (record.group == languageCode(language)) ++count;
    return count >= 11;
}
static void verifyRuntime(const std::wstring& root) {
    const struct { const char* path; const char* hash; } runtime[] = {
        {"NFSSE-Game.exe", "a962a27077a31748f860160dc84699cc46fe03b2c3d04287d07a0c88479c9ddd"},
        {"NFSPortable.dll", "4e970616fb5100f03c7bb2543dec6a0a28bcd1ad8227a455f7e840bc1b6662e4"},
        {"ddraw.dll", "85e0f7d530dfda134793a57cb3e76b0287dcc96892ee57162dd68f47283b03a9"}};
    for (const auto& file : runtime) require(hashFile(localPath(root, file.path)) == file.hash,
        "The supported game engine, compatibility helper or renderer has changed.");
}
static std::string voiceSource(Language language, const char* name) {
    return std::string(language == Language::German ? "FRONTEND/GSPEECH/" : "FRONTEND/SPEECH/") + name;
}
static void atomicWrite(const std::wstring& path, const Bytes& bytes) {
    wchar_t suffix[80]; swprintf_s(suffix, L".language-%lu-%llu.tmp", GetCurrentProcessId(), GetTickCount64());
    std::wstring temporary = path + suffix;
    {
        Handle file(CreateFileW(temporary.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, nullptr));
        require(file.value != INVALID_HANDLE_VALUE, "The game folder cannot be updated. Keep it writable.");
        DWORD count = 0;
        if (!WriteFile(file.value, bytes.data(), static_cast<DWORD>(bytes.size()), &count, nullptr)
            || count != bytes.size() || !FlushFileBuffers(file.value)) {
            CloseHandle(file.value); file.value = INVALID_HANDLE_VALUE; DeleteFileW(temporary.c_str());
            throw std::runtime_error("A language selection file could not be saved.");
        }
    }
    DWORD error = 0;
    for (int attempt = 0; attempt < 21; ++attempt) {
        if (ReplaceFileW(path.c_str(), temporary.c_str(), nullptr, 0, nullptr, nullptr)) return;
        error = GetLastError();
        if (error != ERROR_SHARING_VIOLATION && error != ERROR_LOCK_VIOLATION && error != ERROR_ACCESS_DENIED) break;
        // Windows scanning can briefly hold a freshly written voice/config
        // file. Retry only transient lock/access failures, for at most 500ms.
        if (attempt < 20) Sleep(25);
    }
    DeleteFileW(temporary.c_str());
    throw std::runtime_error("A language file is busy or cannot be updated (Windows error " + std::to_string(error) + ").");
}
struct Change { std::wstring path; Bytes before, after; };
static void selectLanguage(const std::wstring& root, Language language) {
    verifyInventory(root, language);
    const auto inventory = readInventory(root);
    auto tablePath = localPath(root, "GAMEDATA/CONFIG/PATHS.DAT");
    Bytes table = readBytes(tablePath, 1520);
    require(knownPaths(table), "PATHS.DAT contains custom edits. They were preserved; restore a supported language table.");
    auto configPath = localPath(root, "nfs.cfg"); Bytes config = readBytes(configPath, 80);
    std::vector<Change> changes{{tablePath, table, pathTable(language)},
        {configPath, config, languageConfig(config, language)}};
    for (const char* name : voiceNames) {
        auto path = localPath(root, name); Bytes before = readBytes(path);
        const auto hash = hashFile(path); bool known = false;
        for (const auto& record : inventory)
            if ((record.group == 'E' && record.path == voiceSource(Language::English, name)) ||
                (record.group == 'D' && record.path == voiceSource(Language::German, name)))
                known |= hash == record.hash;
        require(known, "A race announcer file contains custom changes. They were preserved.");
        // Read only the chosen recording: a damaged unselected German pack
        // must not prevent recovery from German announcements to English.
        Bytes selected = readBytes(localPath(root, voiceSource(language, name)));
        changes.push_back({path, before, selected});
    }
    size_t written = 0;
    try {
        for (const auto& change : changes) {
            if (change.before != change.after) atomicWrite(change.path, change.after);
            ++written;
        }
    } catch (const std::exception& reason) {
        std::string error = std::string(reason.what()) + " The preceding language selection was restored.";
        while (written) {
            const auto& change = changes[--written];
            if (change.before == change.after) continue;
            try { atomicWrite(change.path, change.before); }
            catch (...) { error = "Language selection failed and a file could not be restored. Close other programs using this folder and select your language again."; }
        }
        throw std::runtime_error(error);
    }
}

#ifndef NFS_LANGUAGE_TEST
static std::wstring gameFolder;
static HWND mainWindow, buttons[3];
static int uiScale = 96;
static HFONT titleFont, bodyFont;
static bool chosen = false;
static bool available[3] = {true, true, true};
static int px(int n) { return MulDiv(n, uiScale, 96); }
static void fill(HDC dc, RECT rect, COLORREF color) {
    HBRUSH brush = CreateSolidBrush(color); FillRect(dc, &rect, brush); DeleteObject(brush);
}
static void drawFlag(HDC dc, RECT rect, Language language) {
    int saved = SaveDC(dc); IntersectClipRect(dc, rect.left, rect.top, rect.right, rect.bottom);
    const int w = rect.right - rect.left, h = rect.bottom - rect.top;
    if (language == Language::German) {
        RECT stripe = rect; stripe.bottom = rect.top + h / 3; fill(dc, stripe, RGB(15, 15, 15));
        stripe.top = stripe.bottom; stripe.bottom = rect.top + 2 * h / 3; fill(dc, stripe, RGB(208, 20, 32));
        stripe.top = stripe.bottom; stripe.bottom = rect.bottom; fill(dc, stripe, RGB(255, 205, 0));
    } else if (language == Language::Japanese) {
        fill(dc, rect, RGB(255, 255, 255));
        HBRUSH brush = CreateSolidBrush(RGB(188, 0, 45)); HGDIOBJ old = SelectObject(dc, brush);
        HGDIOBJ pen = SelectObject(dc, GetStockObject(NULL_PEN)); int radius = h * 3 / 10;
        Ellipse(dc, rect.left + w / 2 - radius, rect.top + h / 2 - radius,
            rect.left + w / 2 + radius, rect.top + h / 2 + radius);
        SelectObject(dc, pen); SelectObject(dc, old); DeleteObject(brush);
    } else {
        fill(dc, rect, RGB(1, 33, 105));
        for (int layer = 0; layer < 2; ++layer) {
            HPEN pen = CreatePen(PS_SOLID, std::max(1, h / (layer ? 9 : 4)), layer ? RGB(200, 16, 46) : RGB(255, 255, 255));
            HGDIOBJ old = SelectObject(dc, pen);
            MoveToEx(dc, rect.left, rect.top, nullptr); LineTo(dc, rect.right, rect.bottom);
            MoveToEx(dc, rect.right, rect.top, nullptr); LineTo(dc, rect.left, rect.bottom);
            SelectObject(dc, old); DeleteObject(pen);
        }
        for (int layer = 0; layer < 2; ++layer) {
            const int half = h / (layer ? 10 : 6);
            COLORREF color = layer ? RGB(200, 16, 46) : RGB(255, 255, 255);
            fill(dc, {rect.left, rect.top + h / 2 - half, rect.right, rect.top + h / 2 + half}, color);
            fill(dc, {rect.left + w / 2 - half, rect.top, rect.left + w / 2 + half, rect.bottom}, color);
        }
    }
    RestoreDC(dc, saved);
}
static void launchLanguage(Language language) {
    if (chosen || !available[static_cast<int>(language)]) return;
    chosen = true;
    try {
        // Held by the selector until the child exits: a second selector cannot
        // change language files underneath a running game.
        Handle session(CreateFileW((gameFolder + L"\\.language-session.lock").c_str(),
            GENERIC_READ | GENERIC_WRITE, 0, nullptr, OPEN_ALWAYS, FILE_ATTRIBUTE_HIDDEN, nullptr));
        require(session.value != INVALID_HANDLE_VALUE, "This game is already open. Close it before choosing another language.");
        const std::wstring engine = localPath(gameFolder, "NFSSE-Game.exe");
        {
            Handle probe(CreateFileW(engine.c_str(), GENERIC_READ | GENERIC_WRITE, 0, nullptr, OPEN_EXISTING, 0, nullptr));
            require(probe.value != INVALID_HANDLE_VALUE, "Close the running game before choosing another language.");
        }
        SetCursor(LoadCursorW(nullptr, IDC_WAIT));
        verifyRuntime(gameFolder);
        selectLanguage(gameFolder, language);
        SetCursor(LoadCursorW(nullptr, IDC_ARROW));
        std::wstring command = L"\"" + engine + L"\"";
        STARTUPINFOW startup = {}; startup.cb = sizeof(startup); PROCESS_INFORMATION process = {};
        require(CreateProcessW(engine.c_str(), &command[0], nullptr, nullptr, FALSE, 0,
            nullptr, gameFolder.c_str(), &startup, &process) != FALSE, "Windows could not start the game.");
        Handle child(process.hProcess), thread(process.hThread);
        ShowWindow(mainWindow, SW_HIDE);
        // Keep processing messages while the selector owns the session lock.
        while (MsgWaitForMultipleObjects(1, &child.value, FALSE, INFINITE, QS_ALLINPUT) == WAIT_OBJECT_0 + 1) {
            MSG message;
            while (PeekMessageW(&message, nullptr, 0, 0, PM_REMOVE)) {
                if (message.message != WM_QUIT) { TranslateMessage(&message); DispatchMessageW(&message); }
            }
        }
        DestroyWindow(mainWindow);
    } catch (const std::exception& error) {
        SetCursor(LoadCursorW(nullptr, IDC_ARROW)); chosen = false;
        MessageBoxW(mainWindow, wide(error.what()).c_str(), L"The Need for Speed: Special Edition", MB_OK | MB_ICONERROR);
    }
}
static LRESULT CALLBACK selectorProc(HWND window, UINT message, WPARAM wparam, LPARAM lparam) {
    if (message == WM_COMMAND && HIWORD(wparam) == BN_CLICKED && LOWORD(wparam) >= 100 && LOWORD(wparam) <= 102) {
        launchLanguage(static_cast<Language>(LOWORD(wparam) - 100)); return 0;
    }
    if (message == WM_DRAWITEM) {
        auto item = reinterpret_cast<DRAWITEMSTRUCT*>(lparam);
        RECT rect = item->rcItem; bool focused = (item->itemState & ODS_FOCUS) != 0;
        fill(item->hDC, rect, (item->itemState & ODS_SELECTED) ? RGB(221, 233, 245) : RGB(255, 255, 255));
        HBRUSH border = CreateSolidBrush(focused ? RGB(0, 99, 180) : RGB(196, 204, 214));
        FrameRect(item->hDC, &rect, border); DeleteObject(border);
        int cx = (rect.left + rect.right) / 2;
        drawFlag(item->hDC, {cx - px(54), rect.top + px(23), cx + px(54), rect.top + px(83)},
            static_cast<Language>(item->CtlID - 100));
        wchar_t label[80]; GetWindowTextW(item->hwndItem, label, ARRAYSIZE(label));
        SelectObject(item->hDC, bodyFont); SetBkMode(item->hDC, TRANSPARENT);
        SetTextColor(item->hDC, item->itemState & ODS_DISABLED ? RGB(128, 128, 128) : RGB(28, 39, 53));
        RECT text = {rect.left, rect.top + px(101), rect.right, rect.bottom - px(15)};
        DrawTextW(item->hDC, label, -1, &text, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
        if (item->itemState & ODS_DISABLED) {
            RECT note = {rect.left, rect.top + px(135), rect.right, rect.bottom};
            DrawTextW(item->hDC, L"Not installed", -1, &note, DT_CENTER | DT_SINGLELINE);
        }
        if (focused) { InflateRect(&rect, -px(4), -px(4)); DrawFocusRect(item->hDC, &rect); }
        return TRUE;
    }
    if (message == WM_PAINT) {
        PAINTSTRUCT paint; HDC dc = BeginPaint(window, &paint); RECT client; GetClientRect(window, &client);
        fill(dc, client, RGB(244, 247, 251)); SetBkMode(dc, TRANSPARENT); SetTextColor(dc, RGB(28, 39, 53));
        SelectObject(dc, titleFont); RECT title = {px(24), px(22), client.right - px(24), px(60)};
        DrawTextW(dc, L"The Need for Speed: Special Edition", -1, &title, DT_CENTER | DT_SINGLELINE);
        SelectObject(dc, bodyFont); RECT subtitle = {px(24), px(65), client.right - px(24), px(96)};
        DrawTextW(dc, L"Choose your language", -1, &subtitle, DT_CENTER | DT_SINGLELINE);
        EndPaint(window, &paint); return 0;
    }
    if (message == WM_CLOSE) { if (!chosen) DestroyWindow(window); return 0; }
    if (message == WM_DESTROY) { PostQuitMessage(0); return 0; }
    return DefWindowProcW(window, message, wparam, lparam);
}
int WINAPI wWinMain(HINSTANCE instance, HINSTANCE, PWSTR, int show) {
    try {
        SetProcessDPIAware(); wchar_t path[32768];
        DWORD length = GetModuleFileNameW(nullptr, path, ARRAYSIZE(path));
        require(length && length < ARRAYSIZE(path), "The game folder could not be located.");
        wchar_t* end = wcsrchr(path, L'\\'); require(end != nullptr, "The game folder is invalid."); *end = 0;
        gameFolder = path;
        for (int i = 0; i < 3; ++i) available[i] = languageAvailable(gameFolder, static_cast<Language>(i));
        require(available[0] && available[1], "The English/German language installation is incomplete.");
        HDC screen = GetDC(nullptr); uiScale = GetDeviceCaps(screen, LOGPIXELSX); ReleaseDC(nullptr, screen);
        titleFont = CreateFontW(-px(22), 0, 0, 0, FW_SEMIBOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, 0, L"Segoe UI");
        bodyFont = CreateFontW(-px(18), 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, 0, L"Segoe UI");
        WNDCLASSW klass = {}; klass.lpfnWndProc = selectorProc; klass.hInstance = instance;
        klass.lpszClassName = L"NFSSELanguageSelector"; klass.hCursor = LoadCursorW(nullptr, IDC_ARROW);
        klass.hIcon = LoadIconW(instance, MAKEINTRESOURCEW(1));
        require(RegisterClassW(&klass) != 0, "The language window could not be prepared.");
        const DWORD style = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;
        RECT bounds = {0, 0, px(620), px(300)}; AdjustWindowRect(&bounds, style, FALSE);
        RECT work; SystemParametersInfoW(SPI_GETWORKAREA, 0, &work, 0);
        int width = bounds.right - bounds.left, height = bounds.bottom - bounds.top;
        mainWindow = CreateWindowExW(0, klass.lpszClassName, L"The Need for Speed: Special Edition", style,
            work.left + (work.right - work.left - width) / 2, work.top + (work.bottom - work.top - height) / 2,
            width, height, nullptr, nullptr, instance, nullptr);
        require(mainWindow != nullptr, "The language window could not be opened.");
        const wchar_t* labels[] = {L"English", L"Deutsch", L"\u65e5\u672c\u8a9e"};
        for (int i = 0; i < 3; ++i) {
            buttons[i] = CreateWindowExW(0, L"BUTTON", labels[i], WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_OWNERDRAW,
                px(28 + i * 198), px(112), px(168), px(158), mainWindow,
                reinterpret_cast<HMENU>(static_cast<INT_PTR>(100 + i)), instance, nullptr);
            require(buttons[i] != nullptr, "A language button could not be created.");
            EnableWindow(buttons[i], available[i]);
        }
        ShowWindow(mainWindow, show); UpdateWindow(mainWindow); SetFocus(buttons[0]);
        MSG message;
        while (GetMessageW(&message, nullptr, 0, 0) > 0) {
            if (message.message == WM_KEYDOWN) {
                if (message.wParam == VK_ESCAPE) { SendMessageW(mainWindow, WM_CLOSE, 0, 0); continue; }
                int selected = -1;
                if (message.wParam >= '1' && message.wParam <= '3') selected = static_cast<int>(message.wParam - '1');
                if (message.wParam == VK_RETURN || message.wParam == VK_SPACE)
                    for (int i = 0; i < 3; ++i) if (GetFocus() == buttons[i]) selected = i;
                if (selected >= 0) { SendMessageW(mainWindow, WM_COMMAND, 100 + selected, 0); continue; }
                if (message.wParam == VK_LEFT || message.wParam == VK_RIGHT) {
                    for (int i = 0; i < 3; ++i) if (GetFocus() == buttons[i]) {
                        int next = i;
                        do { next = (next + (message.wParam == VK_LEFT ? 2 : 1)) % 3; } while (!available[next]);
                        SetFocus(buttons[next]); break;
                    }
                    continue;
                }
            }
            if (!IsDialogMessageW(mainWindow, &message)) { TranslateMessage(&message); DispatchMessageW(&message); }
        }
        DeleteObject(titleFont); DeleteObject(bodyFont); return 0;
    } catch (const std::exception& error) {
        MessageBoxW(nullptr, wide(error.what()).c_str(), L"The Need for Speed: Special Edition", MB_OK | MB_ICONERROR); return 1;
    }
}
#endif
