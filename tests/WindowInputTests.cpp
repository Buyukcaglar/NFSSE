// Exercise the production message hook without starting the game or sending
// keyboard input to the desktop. The fake dispatcher models the game's held
// scan-code table and records which normal messages reach it.
#include "../src/NFSPortable.cpp"
#include <cstdlib>

static bool held[128];
static unsigned keyDowns, characters;
static const WNDCLASSA* registered;
static WNDPROC registeredProc;

static void check(bool condition, const char* message) {
    if (!condition) { std::fprintf(stderr, "%s\n", message); std::exit(1); }
}

static LRESULT CALLBACK fakeGameProc(HWND, UINT message, WPARAM, LPARAM flags) {
    const unsigned scan = (static_cast<unsigned>(flags) >> 16) & 127;
    if (message == WM_KEYDOWN || message == WM_SYSKEYDOWN) { held[scan] = true; ++keyDowns; }
    if (message == WM_KEYUP || message == WM_SYSKEYUP) held[scan] = false;
    if (message == WM_CHAR) ++characters;
    return 71;
}

static ATOM WINAPI fakeRegisterClass(const WNDCLASSA* description) {
    registered = description;
    registeredProc = description ? description->lpfnWndProc : nullptr;
    return 42;
}

int main(int argc, char**) {
    gameWindowProc = fakeGameProc;
    if (argc > 1) {
        portableWindowProc(nullptr, WM_SYSKEYDOWN, VK_F4, (1u << 29) | (0x3eu << 16) | 1);
        return 9; // Alt+F4 must terminate the process with code 0 before here.
    }
    realRegisterClass = fakeRegisterClass;
    gameBase = static_cast<BYTE*>(VirtualAlloc(nullptr, 0x100000, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE));
    check(gameBase != nullptr, "Test allocation failed");
    WNDCLASSA description = {};
    description.lpszClassName = "OtherWindow";
    description.lpfnWndProc = fakeGameProc;
    check(portableRegisterClass(&description) == 42 && registered == &description,
        "Unrelated window class was modified");
    description.lpszClassName = "EACLibWindow";
    check(portableRegisterClass(&description) == 0 && GetLastError() == ERROR_INVALID_DATA,
        "Unexpected game dispatcher was accepted");
    description.lpfnWndProc = reinterpret_cast<WNDPROC>(gameBase + 0x9bb7c);
    check(portableRegisterClass(&description) == 42 && registeredProc == portableWindowProc,
        "Game message hook was not registered");
    check(description.lpfnWndProc != portableWindowProc, "Caller-owned class description was changed");
    VirtualFree(gameBase, 0, MEM_RELEASE);
    gameWindowProc = fakeGameProc;

    BYTE keys[256] = {};
    keys[VK_MENU] = keys[VK_LMENU] = keys[VK_RETURN] = 0x80;
    keys[VK_CAPITAL] = keys[VK_NUMLOCK] = 1;
    check(SetKeyboardState(keys) != FALSE, "Unable to seed local keyboard state");
    portableWindowProc(nullptr, WM_SYSKEYDOWN, VK_MENU, (0x38u << 16) | 1);
    portableWindowProc(nullptr, WM_KEYDOWN, VK_RETURN, (0x1cu << 16) | 1);
    held[0x48] = true; // Arrow key also released while the game is unfocused.
    portableWindowProc(nullptr, WM_KILLFOCUS, 0, 0);
    for (bool pressed : held) check(!pressed, "Focus loss left a game key pressed");
    check(GetKeyboardState(keys) != FALSE, "Unable to read local keyboard state");
    check(!(keys[VK_MENU] & 0x80) && !(keys[VK_RETURN] & 0x80), "Stale thread modifiers survived");
    check((keys[VK_CAPITAL] & 1) && (keys[VK_NUMLOCK] & 1), "Keyboard toggle settings were lost");
    held[0x38] = held[0x1c] = true;
    portableWindowProc(nullptr, WM_SETFOCUS, 0, 0);
    check(!held[0x38] && !held[0x1c], "Focus gain did not recover missing release messages");
    const unsigned beforeDowns = keyDowns, beforeCharacters = characters;
    check(portableWindowProc(nullptr, WM_KEYDOWN, VK_RETURN, (0x1cu << 16) | 1) == 71,
        "Normal Enter was swallowed");
    portableWindowProc(nullptr, WM_CHAR, '\r', (0x1cu << 16) | 1);
    portableWindowProc(nullptr, WM_KEYUP, VK_RETURN, 0xc01c0001u);
    check(keyDowns == beforeDowns + 1 && characters == beforeCharacters + 1 && !held[0x1c],
        "Enter press/character/release did not reach the game");
    portableWindowProc(nullptr, WM_KEYDOWN, VK_F4, (0x3eu << 16) | 1);
    check(held[0x3e], "Ordinary F4 was treated as a close shortcut");
    check(portableWindowProc(nullptr, WM_SYSKEYDOWN, VK_F4, (0x3eu << 16) | 1) == 71,
        "F4 without Alt context was treated as a close shortcut");
    std::puts("Window input regression checks passed (no game launch or desktop input).");
    return 0;
}
