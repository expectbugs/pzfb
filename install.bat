@echo off
REM PZFB — Video Framebuffer: Windows Installer
REM Copies patched Color class files to the PZ install directory.
REM Run once after subscribing, then restart Project Zomboid.

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "CLASS_DIR=%SCRIPT_DIR%class_files"

REM Verify class files exist
if not exist "%CLASS_DIR%\Color.class" (
    echo ERROR: class_files\Color.class not found.
    echo Make sure you're running this from the PZFB mod directory.
    pause
    exit /b 1
)

REM Auto-detect PZ install directory
set "PZ_DIR="

REM Check common Steam locations
for %%P in (
    "C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\projectzomboid"
    "C:\Program Files\Steam\steamapps\common\ProjectZomboid\projectzomboid"
    "D:\Steam\steamapps\common\ProjectZomboid\projectzomboid"
    "D:\SteamLibrary\steamapps\common\ProjectZomboid\projectzomboid"
    "E:\Steam\steamapps\common\ProjectZomboid\projectzomboid"
    "E:\SteamLibrary\steamapps\common\ProjectZomboid\projectzomboid"
) do (
    if exist "%%~P\projectzomboid.jar" (
        set "PZ_DIR=%%~P"
        goto :found
    )
)

REM Check registry for Steam install path
for /f "tokens=2*" %%A in ('reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /v InstallPath 2^>nul') do (
    set "STEAM_PATH=%%B"
)
if defined STEAM_PATH (
    if exist "%STEAM_PATH%\steamapps\common\ProjectZomboid\projectzomboid\projectzomboid.jar" (
        set "PZ_DIR=%STEAM_PATH%\steamapps\common\ProjectZomboid\projectzomboid"
        goto :found
    )
)

REM Allow manual path via argument
if not "%~1"=="" (
    if exist "%~1\projectzomboid.jar" (
        set "PZ_DIR=%~1"
        goto :found
    ) else (
        echo ERROR: %~1\projectzomboid.jar not found.
        pause
        exit /b 1
    )
)

echo ERROR: Could not find Project Zomboid installation.
echo.
echo Please drag-and-drop your projectzomboid folder onto this script,
echo or run: install.bat "C:\path\to\ProjectZomboid\projectzomboid"
pause
exit /b 1

:found
echo PZ install: %PZ_DIR%

REM Deploy class files
if not exist "%PZ_DIR%\zombie\core" mkdir "%PZ_DIR%\zombie\core"
copy /Y "%CLASS_DIR%\Color*.class" "%PZ_DIR%\zombie\core\" >nul

echo.
echo SUCCESS: Class files deployed to %PZ_DIR%\zombie\core\
echo Restart Project Zomboid to activate Video Framebuffer.
pause
