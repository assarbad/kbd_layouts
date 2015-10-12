@echo off
:: Calls ollisign.cmd to sign all files in the given folder
setlocal ENABLEEXTENSIONS
set DIR=%~1
if "%DIR%" == "" echo You must give the path to the MSKLC output & exit /b 1
if exist "%~dp0\clean-msklc-output.cmd" call "%~dp0\clean-msklc-output.cmd" "%DIR%"
for /f %%i in ('dir /a-d /b /s "%DIR%"') do @(
  echo Signing %%i
  call ollisign "%%i" "https://assarbad.net" "%~1"
)
endlocal
