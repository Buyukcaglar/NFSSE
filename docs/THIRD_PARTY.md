# Third-party components and provenance

| Component | Source and role | Distribution |
| --- | --- | --- |
| cnc-ddraw 7.1.0.0 | [Official upstream release](https://github.com/FunkyFr3sh/cnc-ddraw/releases/tag/v7.1.0.0); DirectDraw wrapper using the selected GDI renderer | Exact verified DLL in the patch-kit release, with [MIT license](../licenses/cnc-ddraw-MIT.txt) |
| Original game, video/art/audio, icon, I-Force and legacy DirectPlay DLLs | User's supported installation media | Local installer inputs; absent from repository and release |
| FFmpeg `eatgv` decoder | [Official source](https://github.com/FFmpeg/FFmpeg/blob/master/libavcodec/eatgv.c); independent comparison during video diagnosis | Reference only; no FFmpeg executable or library shipped |
| DirectDraw/PE diagnostic tools and alternate wrapper experiments | Local analysis and upstream research, summarized in the session record | No third-party tools or alternate runtime DLLs shipped |

The new project code and documentation use the root MIT license. That grant does not apply to the original game or its assets. Keep original media files out of public issues and pull requests.

The cnc-ddraw DLL is pinned because the helper uses a verified private presentation critical section and, from v0.1.3, guarded window-configuration fields in that specific binary. The renderer remains unmodified. Its archive and DLL hashes are listed in [Building](BUILDING.md); upgrading the wrapper requires code review and runtime validation, not just changing a download URL.

Microsoft's [PE/COFF specification](https://learn.microsoft.com/en-us/windows/win32/debug/pe-format) is the reference for the appended bootstrap/resource sections. Icon extraction uses the normal [Windows `ExtractIconEx` interface](https://learn.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-extracticonexw).
