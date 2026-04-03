@echo off
REM PZFB — Video Framebuffer: Windows Uninstaller
REM Removes patched Color class files from the PZ install directory.

setlocal enabledelayedexpansion

set "PZ_DIR="

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

for /f "tokens=2*" %%A in ('reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /v InstallPath 2^>nul') do (
    set "STEAM_PATH=%%B"
)
if defined STEAM_PATH (
    if exist "%STEAM_PATH%\steamapps\common\ProjectZomboid\projectzomboid\projectzomboid.jar" (
        set "PZ_DIR=%STEAM_PATH%\steamapps\common\ProjectZomboid\projectzomboid"
        goto :found
    )
)

if not "%~1"=="" (
    if exist "%~1\projectzomboid.jar" (
        set "PZ_DIR=%~1"
        goto :found
    )
)

echo ERROR: Could not find Project Zomboid installation.
pause
exit /b 1

:found
echo PZ install: %PZ_DIR%

del /Q "%PZ_DIR%\zombie\core\Color*.class" 2>nul

echo.
echo SUCCESS: PZFB class files removed.
echo Restart Project Zomboid to restore vanilla Color class.
pause
