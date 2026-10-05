@echo off
setlocal
set "NFS_VS="
for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "NFS_VS=%%i"
if not defined NFS_VS (
    echo Install Visual Studio C++ Build Tools with the x86 compiler.
    exit /b 1
)
call "%NFS_VS%\VC\Auxiliary\Build\vcvarsall.bat" x86 >nul
if errorlevel 1 exit /b 1
pushd "%~dp0.."
if not exist build mkdir build
cl /nologo /LD /MT /O2 /W4 /EHsc /Fo:build\NFSPortable.obj src\NFSPortable.cpp /link /DEF:src\NFSPortable.def /OUT:build\NFSPortable.dll /IMPLIB:build\NFSPortable.lib user32.lib
set "NFS_RESULT=%ERRORLEVEL%"
popd
exit /b %NFS_RESULT%
