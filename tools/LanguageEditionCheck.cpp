// Development-only driver for the same functions used by the native selector.
// It never creates a window or starts the game.
#define NFS_LANGUAGE_TEST
#include "../src/LanguageLauncher.cpp"
int wmain(int argc, wchar_t** argv) {
    if (argc != 3) { std::fprintf(stderr, "Supply game folder and English, German, Japanese or --verify\n"); return 2; }
    try {
        Language language;
        if (wcscmp(argv[2], L"English") == 0) language = Language::English;
        else if (wcscmp(argv[2], L"German") == 0) language = Language::German;
        else if (wcscmp(argv[2], L"Japanese") == 0) language = Language::Japanese;
        else if (wcscmp(argv[2], L"--verify") == 0) language = Language::English;
        else throw std::runtime_error("Unknown language");
        std::wstring root = argv[1];
        Handle session(CreateFileW((root + L"\\.language-session.lock").c_str(), GENERIC_READ | GENERIC_WRITE,
            0, nullptr, OPEN_ALWAYS, FILE_ATTRIBUTE_HIDDEN, nullptr));
        require(session.value != INVALID_HANDLE_VALUE, "Game session is busy");
        verifyRuntime(root);
        if (wcscmp(argv[2], L"--verify") == 0) {
            for (auto selected : {Language::English, Language::German, Language::Japanese})
                if (languageAvailable(root, selected)) verifyInventory(root, selected);
        } else selectLanguage(root, language);
        std::puts("Selected and verified; no UI or game launched."); return 0;
    } catch (const std::exception& error) { std::fprintf(stderr, "%s\n", error.what()); return 1; }
}
