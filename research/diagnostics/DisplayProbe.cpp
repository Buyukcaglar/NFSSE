#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <cstdio>
int main() {
    puts("[");
    DISPLAY_DEVICEW device{};
    device.cb = sizeof(device);
    bool comma = false;
    for (DWORD index = 0; EnumDisplayDevicesW(nullptr, index, &device, 0); ++index) {
        if (!(device.StateFlags & DISPLAY_DEVICE_ATTACHED_TO_DESKTOP)) continue;
        DEVMODEW mode{};
        mode.dmSize = sizeof(mode);
        if (!EnumDisplaySettingsW(device.DeviceName, ENUM_CURRENT_SETTINGS, &mode)) continue;
        if (comma) puts(",");
        printf("{\"index\":%lu,\"primary\":%s,\"width\":%lu,\"height\":%lu,\"bpp\":%lu,\"hz\":%lu,\"x\":%ld,\"y\":%ld}",
            index, (device.StateFlags & DISPLAY_DEVICE_PRIMARY_DEVICE) ? "true" : "false",
            mode.dmPelsWidth, mode.dmPelsHeight, mode.dmBitsPerPel, mode.dmDisplayFrequency,
            mode.dmPosition.x, mode.dmPosition.y);
        comma = true;
    }
    puts("\n]");
    return 0;
}
