-- PZFB — Video Framebuffer: Startup Detection & Auto-Install
-- Checks if patched Color class files are deployed and sets PZFB.AVAILABLE.
-- When class files are missing, generates a platform-specific install script
-- in ~/Zomboid/Lua/ and shows the user where to run it.

PZFB = PZFB or {}
PZFB.AVAILABLE = false
PZFB.VERSION = nil
PZFB._checked = false

local function isWindows()
    return getFileSeparator() == "\\"
end

-- Find a .dat file in the PZFB mod's media/pzfb/ directory.
-- Handles path uncertainty (getDir vs getVersionDir, with/without 42/).
local function findModFile(filename)
    local sep = getFileSeparator()
    local modInfo = getModInfoByID("PZFB")
    if not modInfo then return nil end

    local dir = modInfo:getDir()
    if dir then
        local p = dir .. sep .. "media" .. sep .. "pzfb" .. sep .. filename
        local reader = getFileInput(p)
        if reader then reader:close() return p end
        p = dir .. sep .. "42" .. sep .. "media" .. sep .. "pzfb" .. sep .. filename
        reader = getFileInput(p)
        if reader then reader:close() return p end
    end

    local ok, vdir = pcall(function() return modInfo:getVersionDir() end)
    if ok and vdir then
        local p = vdir .. sep .. "media" .. sep .. "pzfb" .. sep .. filename
        local reader = getFileInput(p)
        if reader then reader:close() return p end
    end
    return nil
end

-- Find the directory containing the .dat class files.
local function findDatDir()
    local sep = getFileSeparator()
    local modInfo = getModInfoByID("PZFB")
    if not modInfo then return nil end

    local dir = modInfo:getDir()
    if dir then
        local p = dir .. sep .. "media" .. sep .. "pzfb"
        local p2 = dir .. sep .. "42" .. sep .. "media" .. sep .. "pzfb"
        -- Try version dir path first (more specific)
        local ok2, vdir = pcall(function() return modInfo:getVersionDir() end)
        if ok2 and vdir then
            local vp = vdir .. sep .. "media" .. sep .. "pzfb"
            return vp
        end
        return p2
    end
    return nil
end

-- Generate a platform-specific install script in ~/Zomboid/Lua/.
-- The script copies .dat files from the mod directory to PZ's install
-- directory, renaming them back to .class.
local function generateInstallScript()
    local datDir = findDatDir()
    if not datDir then return nil end

    local datFiles = {
        "Color.dat", "Color$1.dat", "Color$2.dat", "Color$3.dat",
        "Color$4.dat", "Color$5.dat", "Color$6.dat", "Color$6$1.dat",
        "Color$7.dat", "Color$8.dat", "Color$9.dat", "Color$10.dat",
    }

    if isWindows() then
        -- Generate .bat script
        local writer = getFileWriter("pzfb_install.bat", true, false)
        if not writer then return nil end
        writer:writeln("@echo off")
        writer:writeln("REM PZFB Auto-Generated Installer")
        writer:writeln("REM Copies class files from mod to PZ install directory.")
        writer:writeln("setlocal enabledelayedexpansion")
        writer:writeln("")
        writer:writeln("set \"SRC_DIR=" .. datDir .. "\"")
        writer:writeln("")
        writer:writeln("REM Auto-detect PZ install directory")
        writer:writeln("set \"PZ_DIR=\"")
        writer:writeln("REM Windows: PZ jar is directly in ProjectZomboid\\ (no inner projectzomboid subdir)")
        writer:writeln("for %%P in (")
        writer:writeln("    \"C:\\Program Files (x86)\\Steam\\steamapps\\common\\ProjectZomboid\"")
        writer:writeln("    \"C:\\Program Files\\Steam\\steamapps\\common\\ProjectZomboid\"")
        writer:writeln("    \"D:\\Steam\\steamapps\\common\\ProjectZomboid\"")
        writer:writeln("    \"D:\\SteamLibrary\\steamapps\\common\\ProjectZomboid\"")
        writer:writeln("    \"E:\\Steam\\steamapps\\common\\ProjectZomboid\"")
        writer:writeln("    \"E:\\SteamLibrary\\steamapps\\common\\ProjectZomboid\"")
        writer:writeln(") do (")
        writer:writeln("    if exist \"%%~P\\projectzomboid.jar\" (")
        writer:writeln("        set \"PZ_DIR=%%~P\"")
        writer:writeln("        goto :found")
        writer:writeln("    )")
        writer:writeln(")")
        writer:writeln("for /f \"tokens=2*\" %%A in ('reg query \"HKLM\\SOFTWARE\\WOW6432Node\\Valve\\Steam\" /v InstallPath 2^>nul') do (")
        writer:writeln("    set \"STEAM_PATH=%%B\"")
        writer:writeln(")")
        writer:writeln("if defined STEAM_PATH (")
        writer:writeln("    if exist \"%STEAM_PATH%\\steamapps\\common\\ProjectZomboid\\projectzomboid.jar\" (")
        writer:writeln("        set \"PZ_DIR=%STEAM_PATH%\\steamapps\\common\\ProjectZomboid\"")
        writer:writeln("        goto :found")
        writer:writeln("    )")
        writer:writeln(")")
        writer:writeln("echo ERROR: Could not find Project Zomboid installation.")
        writer:writeln("pause")
        writer:writeln("exit /b 1")
        writer:writeln(":found")
        writer:writeln("echo PZ install: %PZ_DIR%")
        writer:writeln("if not exist \"%PZ_DIR%\\zombie\\core\" mkdir \"%PZ_DIR%\\zombie\\core\"")
        for _, dat in ipairs(datFiles) do
            local cls = dat:sub(1, -5) .. ".class"
            writer:writeln("copy /Y \"%SRC_DIR%\\" .. dat .. "\" \"%PZ_DIR%\\zombie\\core\\" .. cls .. "\" >nul")
        end
        writer:writeln("echo.")
        writer:writeln("echo SUCCESS: PZFB class files installed.")
        writer:writeln("echo Restart Project Zomboid to activate.")
        writer:writeln("pause")
        writer:close()
        return "pzfb_install.bat"
    else
        -- Generate .sh script
        local writer = getFileWriter("pzfb_install.sh", true, false)
        if not writer then return nil end
        writer:writeln("#!/bin/bash")
        writer:writeln("# PZFB Auto-Generated Installer")
        writer:writeln("# Copies class files from mod to PZ install directory.")
        writer:writeln("set -e")
        writer:writeln("")
        writer:writeln("SRC_DIR=\"" .. datDir .. "\"")
        writer:writeln("")
        writer:writeln("# Auto-detect PZ install directory")
        writer:writeln("PZ_DIR=\"\"")
        writer:writeln("DEFAULT_PATH=\"$HOME/.local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid\"")
        writer:writeln("FLATPAK_PATH=\"$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid\"")
        writer:writeln("if [ -f \"$DEFAULT_PATH/projectzomboid.jar\" ]; then PZ_DIR=\"$DEFAULT_PATH\"")
        writer:writeln("elif [ -f \"$FLATPAK_PATH/projectzomboid.jar\" ]; then PZ_DIR=\"$FLATPAK_PATH\"")
        writer:writeln("fi")
        writer:writeln("if [ -z \"$PZ_DIR\" ]; then")
        writer:writeln("    for VDF in \"$HOME/.local/share/Steam/steamapps/libraryfolders.vdf\" \\")
        writer:writeln("               \"$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/libraryfolders.vdf\"; do")
        writer:writeln("        if [ -f \"$VDF\" ]; then")
        writer:writeln("            while IFS= read -r line; do")
        writer:writeln("                path=$(echo \"$line\" | grep -oP '\"path\"\\s+\"\\K[^\"]+' 2>/dev/null)")
        writer:writeln("                if [ -n \"$path\" ] && [ -f \"$path/steamapps/common/ProjectZomboid/projectzomboid/projectzomboid.jar\" ]; then")
        writer:writeln("                    PZ_DIR=\"$path/steamapps/common/ProjectZomboid/projectzomboid\"")
        writer:writeln("                    break 2")
        writer:writeln("                fi")
        writer:writeln("            done < \"$VDF\"")
        writer:writeln("        fi")
        writer:writeln("    done")
        writer:writeln("fi")
        writer:writeln("if [ -z \"$PZ_DIR\" ]; then")
        writer:writeln("    echo \"ERROR: Could not find Project Zomboid installation.\"")
        writer:writeln("    echo \"Usage: $0 /path/to/ProjectZomboid/projectzomboid\"")
        writer:writeln("    exit 1")
        writer:writeln("fi")
        writer:writeln("if [ -n \"$1\" ] && [ -f \"$1/projectzomboid.jar\" ]; then PZ_DIR=\"$1\"; fi")
        writer:writeln("echo \"PZ install: $PZ_DIR\"")
        writer:writeln("mkdir -p \"$PZ_DIR/zombie/core\"")
        for _, dat in ipairs(datFiles) do
            local cls = dat:sub(1, -5) .. ".class"
            writer:writeln("cp \"$SRC_DIR/" .. dat .. "\" \"$PZ_DIR/zombie/core/" .. cls .. "\"")
        end
        writer:writeln("echo \"\"")
        writer:writeln("echo \"SUCCESS: PZFB class files installed.\"")
        writer:writeln("echo \"Restart Project Zomboid to activate.\"")
        writer:close()
        return "pzfb_install.sh"
    end
end

local function checkDeployment()
    if PZFB._checked then return end
    PZFB._checked = true

    local ok, result = pcall(function() return Color.fbPing() end)
    if ok and result then
        PZFB.AVAILABLE = true
        -- Read version from mod.info (authoritative, covers Lua-only updates)
        local modInfo = getModInfoByID("PZFB")
        if modInfo then
            PZFB.VERSION = modInfo:getModVersion()
        end
        if not PZFB.VERSION or PZFB.VERSION == "" then
            local ver = tostring(result)
            PZFB.VERSION = ver:match("PZFB (.+)") or ver
        end
        -- Compare the class-file's reported version to the mod.info version.
        -- A mismatch means Workshop pushed new mod files but the user hasn't
        -- re-run the install script yet — the deployed bytecode is stale.
        --
        -- Patch-level skew tolerance (1.7.1+): only compare major.minor. Lua-only
        -- patch releases bump mod.info but leave class files alone, so a 1.7.0
        -- class file satisfies any 1.7.x mod release without forcing every
        -- subscriber to re-run the install script. Minor (1.7 → 1.8) and major
        -- bumps still surface the "Update Required" panel.
        local pingVer = tostring(result):match("PZFB (.+)") or ""
        PZFB._classVersion = pingVer
        local function _majMinor(v)
            if not v or v == "" then return "" end
            local maj, min = string.match(v, "^(%d+)%.(%d+)")
            if maj and min then return maj .. "." .. min end
            return v
        end
        local pingMM = _majMinor(pingVer)
        local modMM  = _majMinor(PZFB.VERSION)
        if pingMM ~= "" and modMM ~= "" and pingMM ~= modMM then
            PZFB._needsUpdate = true
            PZFB._installScript = generateInstallScript()
            print("[PZFB] Video Framebuffer v" .. PZFB.VERSION
                  .. " — class files out of date (v" .. pingVer .. ").")
            if PZFB._installScript then
                print("[PZFB] Install script regenerated: ~/Zomboid/Lua/" .. PZFB._installScript)
            end
        else
            print("[PZFB] Video Framebuffer v" .. PZFB.VERSION .. " loaded.")
        end
    else
        PZFB.AVAILABLE = false
        -- Generate install script for user
        PZFB._installScript = generateInstallScript()
        if PZFB._installScript then
            print("[PZFB] WARNING: Class files not deployed. Framebuffer unavailable.")
            print("[PZFB] Install script generated: ~/Zomboid/Lua/" .. PZFB._installScript)
            if isWindows() then
                print("[PZFB] Open the Zomboid\\Lua folder and double-click " .. PZFB._installScript .. ", then restart.")
            else
                print("[PZFB] Run: bash ~/Zomboid/Lua/" .. PZFB._installScript .. " && restart PZ.")
            end
        else
            print("[PZFB] WARNING: Class files not deployed and could not generate install script.")
            print("[PZFB] See the Workshop page for manual installation instructions.")
        end
    end
end

local function showInstallPrompt()
    -- Show when class files are missing (first install) OR when class files
    -- are stale relative to the mod version (post-Workshop-update re-install).
    if PZFB.AVAILABLE and not PZFB._needsUpdate then return end

    local upgrade = PZFB._needsUpdate == true
    local w = 540
    local h = 230
    local sx = (getCore():getScreenWidth() - w) / 2
    local sy = (getCore():getScreenHeight() - h) / 2

    local panel = ISPanel:new(sx, sy, w, h)
    panel:initialise()
    panel.background = true
    panel.backgroundColor = {r = 0.1, g = 0.1, b = 0.1, a = 0.95}
    -- Orange border for upgrade, red for first-install
    if upgrade then
        panel.borderColor = {r = 0.7, g = 0.45, b = 0.15, a = 1}
    else
        panel.borderColor = {r = 0.6, g = 0.2, b = 0.2, a = 1}
    end
    panel.moveWithMouse = true

    local scriptName = PZFB._installScript
    local classVer = PZFB._classVersion or "?"
    local modVer   = PZFB.VERSION or "?"
    panel.render = function(self)
        ISPanel.render(self)
        if upgrade then
            self:drawText("Video Framebuffer - Update Required",
                20, 15, 1, 0.7, 0.3, 1, UIFont.Medium)
            self:drawText("Class files are out of date (installed v" .. classVer
                          .. ", mod v" .. modVer .. ").",
                20, 55, 1, 1, 1, 1, UIFont.Small)
        else
            self:drawText("Video Framebuffer - Setup Required",
                20, 15, 1, 0.4, 0.4, 1, UIFont.Medium)
            self:drawText("PZFB class files are not installed.",
                20, 55, 1, 1, 1, 1, UIFont.Small)
        end
        if scriptName then
            local verb = upgrade and "Re-run the install script:" or "An install script has been created for you:"
            self:drawText(verb, 20, 80, 0.8, 0.8, 0.8, 1, UIFont.Small)
            if isWindows() then
                self:drawText("Open your Zomboid\\Lua folder and double-click:",
                    20, 100, 0.8, 0.8, 0.8, 1, UIFont.Small)
                self:drawText(scriptName,
                    40, 120, 0.5, 1, 0.5, 1, UIFont.Small)
            else
                self:drawText("bash ~/Zomboid/Lua/" .. scriptName,
                    40, 100, 0.5, 1, 0.5, 1, UIFont.Small)
            end
            self:drawText("Then restart Project Zomboid.",
                20, 145, 0.8, 0.8, 0.8, 1, UIFont.Small)
        else
            self:drawText("See the Steam Workshop page for install instructions.",
                20, 80, 0.8, 0.8, 0.8, 1, UIFont.Small)
        end
        self:drawText("Workshop page has detailed instructions if needed.",
            20, 175, 0.5, 0.5, 0.5, 1, UIFont.Small)
    end

    local closeBtn = ISButton:new(w - 90, h - 40, 70, 25, "OK", panel, function(self)
        self.parent:setVisible(false)
        self.parent:removeFromUIManager()
    end)
    closeBtn:initialise()
    closeBtn:instantiate()
    panel:addChild(closeBtn)

    panel:addToUIManager()
    panel:setVisible(true)
end

Events.OnGameStart.Add(function()
    checkDeployment()
    showInstallPrompt()
end)
