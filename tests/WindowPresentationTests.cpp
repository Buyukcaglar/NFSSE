// Map the pinned renderer without running its DllMain or resolving imports.
// Exercise the production policy against real relocated code/data, with no
// game, display changes, windows, renderer threads or desktop input.
#include "../src/NFSPortable.cpp"
#include <cstdlib>
#include <vector>

static void check(bool condition, const char* message) {
    if (!condition) { std::fprintf(stderr, "%s\n", message); std::exit(1); }
}

int main(int argc, char** argv) {
    check(argc == 2, "Supply the pinned cnc-ddraw DLL path");
    HMODULE module = LoadLibraryExA(argv[1], nullptr, DONT_RESOLVE_DLL_REFERENCES);
    check(module != nullptr, "Could not map renderer for static policy checks");
    BYTE* graphics = reinterpret_cast<BYTE*>(module);
    const DWORD fields[] = {0x58b88, 0x58b8c, 0x596fc, 0x59704};
    auto width = reinterpret_cast<LONG*>(graphics + fields[0]);
    auto height = reinterpret_cast<LONG*>(graphics + fields[1]);
    auto border = reinterpret_cast<BOOL*>(graphics + fields[2]);
    auto resizable = reinterpret_cast<BOOL*>(graphics + fields[3]);
    for (DWORD desktopHeight : {0u, 720u, 768u, 959u, 960u, 961u, 1080u, 1600u}) {
        *width = 800; *height = 600; *border = FALSE; *resizable = TRUE;
        std::vector<BYTE> before(graphics, graphics + 0x6c000);
        check(configureWindowPresentation(graphics, desktopHeight), "Pinned renderer layout was rejected");
        const bool doubled = desktopHeight > 960;
        check(*border == TRUE, "Window border was not enabled");
        check(*width == (doubled ? 1280 : 800) && *height == (doubled ? 960 : 600),
            "Desktop height threshold or client dimensions incorrect");
        check(*resizable == (doubled ? FALSE : TRUE), "Resize policy incorrect");
        for (DWORD index = 0; index < before.size(); ++index) {
            bool allowed = false;
            for (DWORD field : fields) allowed |= index >= field && index < field + sizeof(DWORD);
            check(allowed || before[index] == graphics[index], "Policy changed unrelated renderer bytes");
        }
    }
    // A changed configuration store must fail before any settings are written.
    DWORD protection;
    check(VirtualProtect(graphics + 0x1e2a4, 5, PAGE_EXECUTE_READWRITE, &protection) != FALSE,
        "Could not prepare mismatched-layout fixture");
    graphics[0x1e2a5] ^= 1;
    *width = 800; *height = 600; *border = FALSE; *resizable = TRUE;
    check(!configureWindowPresentation(graphics, 1080), "Unexpected renderer layout was accepted");
    check(*width == 800 && *height == 600 && *border == FALSE && *resizable == TRUE,
        "Rejected layout changed settings");
    graphics[0x1e2a5] ^= 1;
    DWORD ignored;
    VirtualProtect(graphics + 0x1e2a4, 5, protection, &ignored);
    FreeLibrary(module);
    std::puts("Window presentation checks passed (renderer mapped without initialization; no game launch).");
    return 0;
}
