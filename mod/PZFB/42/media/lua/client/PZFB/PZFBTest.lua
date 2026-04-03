-- PZFB Test Script
-- INSERT: create two framebuffers (tests multi-FB)
-- HOME: fill FB1 red, FB2 blue
-- END: load raw file into FB1 (if test_frame.raw exists)
-- DELETE: destroy both framebuffers

require "PZFB/PZFBApi"

local fb1 = nil
local fb2 = nil
local testPanel = nil

local function onKeyPressed(key)
    if not PZFB.isAvailable() then
        if key == Keyboard.KEY_INSERT then
            print("[PZFB TEST] Not available — run install script and restart.")
        end
        return
    end

    if key == Keyboard.KEY_INSERT then
        print("[PZFB TEST] Creating two framebuffers...")
        fb1 = PZFB.create(64, 64)
        fb2 = PZFB.create(64, 64)
        print("[PZFB TEST] fb1=" .. tostring(fb1) .. " fb2=" .. tostring(fb2))

        if not testPanel then
            testPanel = ISPanel:new(100, 100, 540, 280)
            testPanel:initialise()
            testPanel.background = true
            testPanel.backgroundColor = {r = 0.15, g = 0.15, b = 0.15, a = 1}
            testPanel.moveWithMouse = true
            testPanel.render = function(self)
                ISPanel.render(self)
                self:drawText("PZFB v" .. tostring(PZFB.getVersion()), 10, 5, 0.5, 1, 0.5, 1, UIFont.Small)
                self:drawText("FB1:", 10, 25, 1, 1, 1, 1, UIFont.Small)
                self:drawText("FB2:", 275, 25, 1, 1, 1, 1, UIFont.Small)
                if fb1 and PZFB.isReady(fb1) then
                    self:drawTextureScaled(PZFB.getTexture(fb1), 10, 45, 256, 256, 1, 1, 1, 1)
                else
                    self:drawText("(not ready)", 10, 45, 1, 0.3, 0.3, 1, UIFont.Small)
                end
                if fb2 and PZFB.isReady(fb2) then
                    self:drawTextureScaled(PZFB.getTexture(fb2), 275, 45, 256, 256, 1, 1, 1, 1)
                else
                    self:drawText("(not ready)", 275, 45, 1, 0.3, 0.3, 1, UIFont.Small)
                end
            end
            testPanel:addToUIManager()
            testPanel:setVisible(true)
            print("[PZFB TEST] Panel created. Press HOME to fill colors.")
        end
    end

    if key == Keyboard.KEY_HOME then
        if not fb1 then print("[PZFB TEST] No framebuffers. Press INSERT first.") return end
        print("[PZFB TEST] Filling fb1=red, fb2=blue...")
        PZFB.fill(fb1, 255, 0, 0, 255)
        PZFB.fill(fb2, 0, 0, 255, 255)
        print("[PZFB TEST] Fill queued. Should see colors next frame.")
    end

    if key == Keyboard.KEY_END then
        if not fb1 then print("[PZFB TEST] No framebuffers. Press INSERT first.") return end
        local path = "/home/user/Zomboid/Lua/RTZomboid_Bridge/test_frame.raw"
        print("[PZFB TEST] Loading raw: " .. path)
        local ok = PZFB.loadRaw(fb1, path)
        print("[PZFB TEST] loadRaw = " .. tostring(ok))
    end

    if key == Keyboard.KEY_DELETE then
        print("[PZFB TEST] Destroying framebuffers...")
        if fb1 then PZFB.destroy(fb1); fb1 = nil end
        if fb2 then PZFB.destroy(fb2); fb2 = nil end
        print("[PZFB TEST] Destroyed.")
    end
end

Events.OnKeyPressed.Add(onKeyPressed)
print("[PZFB TEST] Keys: INSERT=create, HOME=fill, END=loadRaw, DELETE=destroy")
