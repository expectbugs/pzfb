-- PZFB — Video Framebuffer: Startup Detection
-- Checks if patched Color class files are deployed and sets PZFB.AVAILABLE.

PZFB = PZFB or {}
PZFB.AVAILABLE = false
PZFB.VERSION = nil
PZFB._checked = false

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
            -- Fallback: parse from ping response ("PZFB 1.0.0")
            local ver = tostring(result)
            PZFB.VERSION = ver:match("PZFB (.+)") or ver
        end
        print("[PZFB] Video Framebuffer v" .. PZFB.VERSION .. " loaded.")
    else
        PZFB.AVAILABLE = false
        print("[PZFB] WARNING: Class files not deployed. Framebuffer unavailable.")
        print("[PZFB] Run install.sh (Linux) or install.bat (Windows) from the PZFB mod folder, then restart.")
    end
end

local function showInstallPrompt()
    if PZFB.AVAILABLE then return end

    local w = 500
    local h = 200
    local sx = (getCore():getScreenWidth() - w) / 2
    local sy = (getCore():getScreenHeight() - h) / 2

    local panel = ISPanel:new(sx, sy, w, h)
    panel:initialise()
    panel.background = true
    panel.backgroundColor = {r = 0.1, g = 0.1, b = 0.1, a = 0.95}
    panel.borderColor = {r = 0.6, g = 0.2, b = 0.2, a = 1}
    panel.moveWithMouse = true

    panel.render = function(self)
        ISPanel.render(self)
        self:drawText("Video Framebuffer - Setup Required",
            20, 15, 1, 0.4, 0.4, 1, UIFont.Medium)
        self:drawText("PZFB class files are not installed.",
            20, 55, 1, 1, 1, 1, UIFont.Small)
        self:drawText("Run install.sh (Linux) or install.bat (Windows)",
            20, 80, 0.8, 0.8, 0.8, 1, UIFont.Small)
        self:drawText("from the PZFB mod folder, then restart the game.",
            20, 100, 0.8, 0.8, 0.8, 1, UIFont.Small)
        self:drawText("See the Workshop page for detailed instructions.",
            20, 130, 0.5, 0.5, 0.5, 1, UIFont.Small)
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
