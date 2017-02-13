@echo off
setlocal ENABLEEXTENSIONS
set MAKENSIS=%ProgramFiles(x86)%\NSIS\Unicode\makensis.exe
for %%i in (kbdru_us kbdus_xx) do @(
    call "%~dp0sign-msklc-output.cmd" %%i
    "%MAKENSIS%" "%%i.nsi"
    call ollisign.cmd "%%i.exe" "https://assarbad.net/en/stuff/MSKLC/" "%%i"
    if exist "%%i.sha2" rd /q /s "%%i.sha2"
    xcopy /e /i /y "%%i" "%%i.sha2"
    copy /y "%%i.nsi" "%%i.sha2.nsi"
)
for %%i in (kbdru_us.sha2 kbdus_xx.sha2) do @(
    call "%~dp0sign-msklc-output.cmd" /a %%i
    "%MAKENSIS%" /DBASENAME=%%i "%%i.nsi"
    call ollisign.cmd /a "%%i.exe" "https://assarbad.net/en/stuff/MSKLC/" "%%i"
    if exist "%%i" rd /q /s "%%i"
    if exist "%%i.nsi" del /f "%%i.nsi"
)
endlocal
