-- PZFB — Video Framebuffer: Input Capture Module
-- ISPanel subclass that captures keyboard input when active.
-- Prevents game from processing movement/action keys while the panel has focus.
--
-- Usage:
--   local panel = PZFBInputPanel:new(x, y, w, h)
--   panel:initialise()
--   panel:addToUIManager()
--   panel:grabInput()  -- start capturing
--
--   -- Override these for event-driven input:
--   function panel:onPZFBKeyPress(key) ... end
--   function panel:onPZFBKeyRelease(key) ... end
--
--   -- Or poll key state:
--   if panel:isKeyDown(Keyboard.KEY_LEFT) then ... end
--
--   panel:releaseInput()  -- stop capturing

require "ISUI/ISPanel"

PZFBInputPanel = ISPanel:derive("PZFBInputPanel")

function PZFBInputPanel:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.capturingInput = false
    o.keysDown = {}
    return o
end

function PZFBInputPanel:createChildren()
    ISPanel.createChildren(self)
    self:setWantKeyEvents(true)
end

--- Called by PZ UI system. Return true to prevent the game from processing the key.
function PZFBInputPanel:isKeyConsumed(key)
    return self.capturingInput
end

--- Called by PZ on key press.
function PZFBInputPanel:onKeyPress(key)
    if not self.capturingInput then return end
    GameKeyboard.eatKeyPress(key)
    self.keysDown[key] = true
    if self.onPZFBKeyPress then
        self:onPZFBKeyPress(key)
    end
end

--- Called by PZ on key release.
function PZFBInputPanel:onKeyRelease(key)
    if not self.capturingInput then return end
    self.keysDown[key] = nil
    if self.onPZFBKeyRelease then
        self:onPZFBKeyRelease(key)
    end
end

--- Start capturing keyboard input. Game movement/actions will be blocked.
function PZFBInputPanel:grabInput()
    self.capturingInput = true
    self.keysDown = {}
end

--- Stop capturing keyboard input. Game controls resume.
function PZFBInputPanel:releaseInput()
    self.capturingInput = false
    self.keysDown = {}
end

--- Check if a key is currently held down (polling-style input).
--- @param key number Keyboard constant (e.g. Keyboard.KEY_LEFT)
--- @return boolean
function PZFBInputPanel:isKeyDown(key)
    return self.keysDown[key] == true
end

--- Check if input capture is active.
--- @return boolean
function PZFBInputPanel:isCapturing()
    return self.capturingInput
end

--- Override in your subclass for event-driven key press handling.
-- function PZFBInputPanel:onPZFBKeyPress(key) end

--- Override in your subclass for event-driven key release handling.
-- function PZFBInputPanel:onPZFBKeyRelease(key) end
