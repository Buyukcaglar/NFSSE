@echo off
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-NFSSE.ps1"
if errorlevel 1 (
    echo Installation failed. See the message above.
    pause
)
