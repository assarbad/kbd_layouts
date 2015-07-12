@echo off
setlocal ENABLEEXTENSIONS
set MAKENSIS=%ProgramFiles(x86)%\NSIS\Unicode\makensis.exe
for %%i in (kbdru_us kbdus_xx) do @(
    call "%~dp0sign-msklc-output.cmd" %%i
    "%MAKENSIS%" "%%i.nsi"
    call ollisign.cmd "%%i.exe" "https://assarbad.net/en/stuff/MSKLC/" "%%i"
)
endlocal
