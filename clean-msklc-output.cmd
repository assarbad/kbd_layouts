@echo off
:: This script removes setup.exe and the Itanium (IA-64) files
setlocal ENABLEEXTENSIONS
set DIR=%~1
if "%DIR%" == "" echo You must give the path to the MSKLC output & exit /b 1
echo Cleaning %DIR%
::if exist "%DIR%\ia64" rd /q /s "%DIR%\ia64"
::if exist "%DIR%\*_ia64.msi" del /f "%DIR%\*_ia64.msi"
if exist "%DIR%\setup.exe" del /f "%DIR%\setup.exe"
endlocal
