@echo off
setlocal
set "NFS_VS="
for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "NFS_VS=%%i"
if not defined NFS_VS exit /b 1
call "%NFS_VS%\VC\Auxiliary\Build\vcvarsall.bat" x86 >nul
if errorlevel 1 exit /b 1
pushd "%~dp0.."
if not exist build mkdir build
cl /nologo /MT /O2 /W4 /EHsc /Fo:build\WindowInputTests.obj tests\WindowInputTests.cpp /link /OUT:build\WindowInputTests.exe user32.lib
if errorlevel 1 goto fail
build\WindowInputTests.exe
if not "%ERRORLEVEL%"=="0" goto fail
build\WindowInputTests.exe --alt-f4
if not "%ERRORLEVEL%"=="0" goto fail
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File tests\GraphicsConfig.Tests.ps1
if errorlevel 1 goto fail
popd
exit /b 0
:fail
popd
exit /b 1
