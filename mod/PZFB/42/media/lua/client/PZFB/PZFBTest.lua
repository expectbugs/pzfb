-- PZFB Test Script
-- HOME: create framebuffer in a resizable window
-- END: destroy framebuffer and close window

require "PZFB/PZFBApi"
require "ISUI/ISCollapsableWindow"
require "ISUI/ISPanel"

local fb = nil
local fbWindow = nil

-- Change these to remap the keys
local KEY_CREATE = Keyboard.KEY_HOME
local KEY_DESTROY = Keyboard.KEY_END

-- ISPanel subclass that draws the framebuffer scaled to fit
PZFBDisplayPanel = ISPanel:derive("PZFBDisplayPanel")

function PZFBDisplayPanel:new(x, y, w, h)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    o.anchorLeft = true
    o.anchorRight = true
    o.anchorTop = true
    o.anchorBottom = true
    return o
end

function PZFBDisplayPanel:render()
    ISPanel.render(self)
    if fb and PZFB.isReady(fb) then
        local tex = PZFB.getTexture(fb)
        local w = self:getWidth()
        local h = self:getHeight()
        local fbAspect = fb.width / fb.height
        local panelAspect = w / h
        local drawW, drawH, drawX, drawY
        if panelAspect > fbAspect then
            drawH = h
            drawW = h * fbAspect
            drawX = (w - drawW) / 2
            drawY = 0
        else
            drawW = w
            drawH = w / fbAspect
            drawX = 0
            drawY = (h - drawH) / 2
        end
        self:drawTextureScaled(tex, drawX, drawY, drawW, drawH, 1, 1, 1, 1)
    else
        self:drawText("Waiting for GL...", 10, 10, 0.5, 0.5, 0.5, 1, UIFont.Small)
    end
end

local function createFBWindow()
    if fbWindow then return end

    fb = PZFB.create(64, 64)
    if not fb then
        print("[PZFB TEST] Failed to create framebuffer.")
        return
    end

    fbWindow = ISCollapsableWindow:new(100, 100, 400, 400)
    fbWindow.minimumWidth = 150
    fbWindow.minimumHeight = 150
    fbWindow:initialise()
    fbWindow:instantiate()
    fbWindow:setTitle("PZFB Test")
    fbWindow:setResizable(true)
    fbWindow.backgroundColor = {r = 0.05, g = 0.05, b = 0.05, a = 1}

    fbWindow.close = function(self)
        destroyFBWindow()
    end

    local th = fbWindow:titleBarHeight()
    local rh = fbWindow:resizeWidgetHeight()
    local inner = PZFBDisplayPanel:new(0, th, fbWindow:getWidth(), fbWindow:getHeight() - th - rh)
    inner:initialise()
    inner:instantiate()
    fbWindow:addChild(inner)

    -- Resize widgets were created in createChildren() but our inner panel
    -- was added after, putting it on top in z-order and eating mouse events.
    fbWindow.resizeWidget:bringToTop()
    fbWindow.resizeWidget2:bringToTop()

    fbWindow:addToUIManager()
    fbWindow:setVisible(true)

    -- Delay the fill so we can see the window appear first, then the FB fills
    local fillTimer = 120 -- ~2 seconds at 60fps
    local function tickFill()
        fillTimer = fillTimer - 1
        if fillTimer <= 0 then
            if fb then
                PZFB.fill(fb, 0, 200, 0, 255)
                print("[PZFB TEST] Filled green.")
            end
            Events.OnTick.Remove(tickFill)
        end
    end
    Events.OnTick.Add(tickFill)
    print("[PZFB TEST] Window created. Framebuffer 64x64. Green fill in ~2s. Press END to close.")
end

function destroyFBWindow()
    if fb then
        PZFB.destroy(fb)
        fb = nil
    end
    if fbWindow then
        fbWindow:setVisible(false)
        fbWindow:removeFromUIManager()
        fbWindow = nil
    end
    print("[PZFB TEST] Destroyed.")
end

local function onKeyPressed(key)
    -- Other mods (e.g. PZVP) can disable the test keys by setting this flag
    if PZFB.TEST_DISABLED then return end

    if not PZFB.isAvailable() then
        if key == KEY_CREATE then
            print("[PZFB TEST] Not available — run install script and restart.")
        end
        return
    end

    if key == KEY_CREATE then
        createFBWindow()
    elseif key == KEY_DESTROY then
        destroyFBWindow()
    end
end

Events.OnKeyPressed.Add(onKeyPressed)
if not PZFB.TEST_DISABLED then
    print("[PZFB TEST] Keys: HOME=create, END=destroy")
end
