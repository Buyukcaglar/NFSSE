@echo off
setlocal
set "NFS_VS="
for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "NFS_VS=%%i"
if not defined NFS_VS exit /b 1
call "%NFS_VS%\VC\Auxiliary\Build\vcvarsall.bat" x86 >nul
if errorlevel 1 exit /b 1
pushd "%~dp0.."
if not exist build mkdir build
cl /nologo /MT /O2 /W4 /EHsc /Fo:build\PlayerPersistenceTests.obj tests\PlayerPersistenceTests.cpp /link /BASE:0x20000000 /DYNAMICBASE:NO /OUT:build\PlayerPersistenceTests.exe user32.lib advapi32.lib
if errorlevel 1 goto fail
build\PlayerPersistenceTests.exe %*
set "NFS_RESULT=%ERRORLEVEL%"
popd
exit /b %NFS_RESULT%
:fail
popd
exit /b 1
