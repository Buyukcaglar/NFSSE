#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <tlhelp32.h>
#include <cstdio>
#include <cstdlib>
#include <initializer_list>

int main(int argc, char** argv) {
    if (argc != 2) return 2;
    DWORD pid = strtoul(argv[1], nullptr, 10);
    HANDLE process = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, pid);
    if (!process) return 3;
    HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
    THREADENTRY32 entry{sizeof(entry)};
    if (Thread32First(snapshot, &entry)) do {
        if (entry.th32OwnerProcessID != pid) continue;
        HANDLE thread = OpenThread(THREAD_SUSPEND_RESUME | THREAD_GET_CONTEXT, FALSE, entry.th32ThreadID);
        if (!thread) continue;
        if (SuspendThread(thread) != static_cast<DWORD>(-1)) {
            CONTEXT context{};
            context.ContextFlags = CONTEXT_FULL;
            if (GetThreadContext(thread, &context)) {
                DWORD stack[512]{};
                SIZE_T read;
                ReadProcessMemory(process, reinterpret_cast<void*>(context.Esp), stack, sizeof(stack), &read);
                printf("thread=%lu EIP=%08lX ESP=%08lX EBP=%08lX EAX=%08lX EBX=%08lX ESI=%08lX EDI=%08lX stack:", entry.th32ThreadID, context.Eip, context.Esp, context.Ebp, context.Eax, context.Ebx, context.Esi, context.Edi);
                unsigned found=0;
                for (DWORD value : stack) {
                    MEMORY_BASIC_INFORMATION memory{};
                    if (VirtualQueryEx(process, reinterpret_cast<void*>(value), &memory, sizeof(memory)) &&
                        (memory.Protect & (PAGE_EXECUTE_READ | PAGE_EXECUTE_READWRITE | PAGE_EXECUTE)) && found++ < 45)
                        printf(" %08lX", value);
                }
                printf("\n");
            }
            ResumeThread(thread);
        }
        CloseHandle(thread);
    } while (Thread32Next(snapshot, &entry));
    for (DWORD address : {0x4c628cu,0x4c6290u,0x4c6294u,0x52cea8u,0x52d2f8u,0x52ee50u,0x52ee54u}) {
        DWORD value{}; SIZE_T read;
        if (ReadProcessMemory(process, reinterpret_cast<void*>(address), &value, sizeof(value), &read)) printf("%08lX=%08lX\n", address, value);
    }
    CloseHandle(snapshot);
    CloseHandle(process);
    return 0;
}
