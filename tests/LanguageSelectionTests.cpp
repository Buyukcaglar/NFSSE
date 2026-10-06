// Exercise production selection on tiny synthetic resources; no game or UI.
#define NFS_LANGUAGE_TEST
#include "../src/LanguageLauncher.cpp"
#include <cstdlib>

static void check(bool condition, const char* message) {
    if (!condition) { std::fprintf(stderr, "%s\n", message); std::exit(1); }
}
static void write(const std::wstring& path, const Bytes& bytes) {
    Handle file(CreateFileW(path.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr));
    check(file.value != INVALID_HANDLE_VALUE, "Fixture write failed"); DWORD count;
    check(WriteFile(file.value, bytes.data(), static_cast<DWORD>(bytes.size()), &count, nullptr) && count == bytes.size(), "Fixture write failed");
}
static Bytes text(const char* value) { return Bytes(value, value + strlen(value)); }
template<class F> static void rejects(F function, const char* message) {
    bool rejected = false; try { function(); } catch (const std::exception&) { rejected = true; }
    check(rejected, message);
}
int wmain(int argc, wchar_t** argv) {
    check(argc == 2, "Supply a new test fixture folder"); std::wstring root = argv[1];
    check(CreateDirectoryW(root.c_str(), nullptr) != FALSE, "Test fixture folder must be new");
    const wchar_t* folders[] = {L"\\LANG", L"\\FRONTEND", L"\\FRONTEND\\SPEECH",
        L"\\FRONTEND\\GSPEECH", L"\\GAMEDATA", L"\\GAMEDATA\\CONFIG", L"\\GAMEDATA\\SAVEGAME"};
    for (auto name : folders) check(CreateDirectoryW((root + name).c_str(), nullptr) != FALSE, "Fixture mkdir failed");
    write(root + L"\\GAMEDATA\\CONFIG\\PATHS.DAT", pathTable(Language::English));
    Bytes cfg = text("NOSOUND LOWVIDEO ENGLISH NOREMOTE \r\n"); write(root + L"\\nfs.cfg", cfg);
    write(root + L"\\GAMEDATA\\SAVEGAME\\preserved.sav", text("USER SAVE"));
    std::string inventory = "NFSSE-LANGUAGES-1\n";
    auto record = [&](char group, const std::string& relative) {
        inventory += group; inventory += "\t" + hashFile(localPath(root, relative)) + "\t" + relative + "\n";
    };
    for (auto name : {"common-a", "common-b", "common-c"}) {
        write(root + L"\\" + wide(name), text(name)); record('C', name);
    }
    for (const char* name : voiceNames) {
        write(root + L"\\FRONTEND\\SPEECH\\" + wide(name), text("English original"));
        write(root + L"\\FRONTEND\\GSPEECH\\" + wide(name), text("German original"));
        write(root + L"\\" + wide(name), text("English original"));
        record('E', voiceSource(Language::English, name)); record('D', voiceSource(Language::German, name));
        record('J', voiceSource(Language::English, name));
    }
    write(root + L"\\LANG\\language-edition.index", Bytes(inventory.begin(), inventory.end()));
    check(languageAvailable(root, Language::English) && languageAvailable(root, Language::German) && languageAvailable(root, Language::Japanese), "Installed languages missing");
    std::string twoLanguages;
    size_t start = 0;
    while (start < inventory.size()) {
        size_t end = inventory.find('\n', start);
        if (inventory[start] != 'J') twoLanguages += inventory.substr(start, end + 1 - start);
        start = end + 1;
    }
    write(root + L"\\LANG\\language-edition.index", Bytes(twoLanguages.begin(), twoLanguages.end()));
    check(languageAvailable(root, Language::English) && languageAvailable(root, Language::German) && !languageAvailable(root, Language::Japanese), "Optional Japanese availability wrong");
    rejects([&] { selectLanguage(root, Language::Japanese); }, "Uninstalled Japanese accepted");
    write(root + L"\\LANG\\language-edition.index", Bytes(inventory.begin(), inventory.end()));
    rejects([&] { verifyRuntime(root); }, "Fixture was accepted as a supported game engine");
    check(safeRelative("FRONTEND/SPEECH/FIRST.EAS"), "Normal path rejected");
    for (auto name : {"../escape", "x/../y", "/absolute", "C:/outside", "x\\y", "x//y", "x/", "x./y", "x /y"})
        check(!safeRelative(name), "Unsafe path accepted");
    check(knownPaths(pathTable(Language::English)) && knownPaths(pathTable(Language::German)) && knownPaths(pathTable(Language::Japanese)), "Known paths rejected");
    rejects([&] { languageConfig(text("NOSOUND LOWVIDEO ENGLISH NOREMOTE\r\n"), Language::German); }, "Missing trailing space accepted");
    rejects([&] { languageConfig(text("NOSOUND LOWVIDEO JAPANESE NOREMOTE \r\n"), Language::English); }, "Unsupported config accepted");
    for (Language language : {Language::German, Language::Japanese, Language::English, Language::German, Language::English}) {
        selectLanguage(root, language);
        check(readBytes(root + L"\\GAMEDATA\\CONFIG\\PATHS.DAT") == pathTable(language), "Wrong language routing");
        check(readBytes(root + L"\\nfs.cfg") == languageConfig(cfg, language), "Other configuration choices changed");
        for (const char* name : voiceNames)
            check(readBytes(root + L"\\" + wide(name)) == text(language == Language::German ? "German original" : "English original"), "Incorrect race announcer");
        selectLanguage(root, language); // Repeated selection must preserve bytes.
    }
    auto tablePath = root + L"\\GAMEDATA\\CONFIG\\PATHS.DAT";
    Bytes en = pathTable(Language::English), custom = en; custom[0] = 'X'; write(tablePath, custom);
    rejects([&] { selectLanguage(root, Language::German); }, "Custom table accepted");
    check(readBytes(tablePath) == custom && readBytes(root + L"\\nfs.cfg") == cfg, "Rejected selection changed files"); write(tablePath, en);
    auto germanVoice = root + L"\\FRONTEND\\GSPEECH\\FIRST.EAS"; write(germanVoice, text("Damaged"));
    rejects([&] { selectLanguage(root, Language::German); }, "Damaged language resource accepted");
    check(readBytes(tablePath) == en && readBytes(root + L"\\FIRST.EAS") == text("English original"), "Integrity rejection changed files");
    selectLanguage(root, Language::English); // Unselected damaged language can recover to English.
    write(germanVoice, text("German original"));
    selectLanguage(root, Language::German);
    write(germanVoice, text("Damaged"));
    selectLanguage(root, Language::English);
    check(readBytes(root + L"\\FIRST.EAS") == text("English original"), "Damaged German pack blocked recovery to English");
    write(germanVoice, text("German original"));
    {
        // Fail at the config write after PATHS.DAT has already changed. Rollback
        // must restore it and leave every announcer file intact.
        Handle lock(CreateFileW((root + L"\\nfs.cfg").c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, 0, nullptr));
        check(lock.value != INVALID_HANDLE_VALUE, "Could not lock config fixture");
        rejects([&] { selectLanguage(root, Language::German); }, "Locked write accepted");
        check(readBytes(tablePath) == en, "Failed multi-file selection did not roll back");
    }
    check(readBytes(root + L"\\nfs.cfg") == cfg, "Config rollback did not preserve original bytes");
    for (const char* name : voiceNames) check(readBytes(root + L"\\" + wide(name)) == text("English original"), "Rollback changed an announcer");
    write(root + L"\\FIRST.EAS", text("CUSTOM AUDIO"));
    rejects([&] { selectLanguage(root, Language::German); }, "Custom announcer overwritten");
    check(readBytes(root + L"\\FIRST.EAS") == text("CUSTOM AUDIO") && readBytes(tablePath) == en, "Custom announcer rejection wrote files");
    check(readBytes(root + L"\\GAMEDATA\\SAVEGAME\\preserved.sav") == text("USER SAVE"), "Save data changed");
    // OS-level exclusive session lock prevents a second selector from opening it.
    {
        auto path = root + L"\\.language-session.lock";
        Handle first(CreateFileW(path.c_str(), GENERIC_READ | GENERIC_WRITE, 0, nullptr, OPEN_ALWAYS, 0, nullptr));
        Handle second(CreateFileW(path.c_str(), GENERIC_READ | GENERIC_WRITE, 0, nullptr, OPEN_ALWAYS, 0, nullptr));
        check(first.value != INVALID_HANDLE_VALUE && second.value == INVALID_HANDLE_VALUE, "Session exclusion failed");
    }
    std::puts("Three-language selection, original voices, integrity rejection, rollback, session exclusion and save preservation passed. No game or UI launched.");
    return 0;
}
