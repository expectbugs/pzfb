-- Framebuffer test via patched Color class.
-- INSERT: create framebuffer (GL init queued to render thread)
-- HOME: fill red (only works after GL init completes)

local fbTexture = nil
local fbPanel = nil

local function onKeyPressed(key)
    if key == Keyboard.KEY_INSERT then
        print("[RTZ] FB: Creating framebuffer...")
        local ok, r = pcall(function()
            print("[RTZ] FB: fbPing = " .. tostring(Color.fbPing()))
            fbTexture = Color.fbCreate(64, 64)
            return "fbCreate done, w=" .. tostring(fbTexture:getWidth())
        end)
        print("[RTZ] FB: " .. (ok and tostring(r) or "ERROR: " .. tostring(r)))
        print("[RTZ] FB: GL init queued. Wait a moment, then press HOME.")

        -- Create display panel (big enough to see at 4K)
        if not fbPanel then
            fbPanel = ISPanel:new(100, 100, 512, 512)
            fbPanel:initialise()
            fbPanel.background = true
            fbPanel.backgroundColor = {r = 0.2, g = 0.2, b = 0.2, a = 1}
            fbPanel.render = function(self)
                ISPanel.render(self)
                if fbTexture and Color.fbIsReady() then
                    self:drawTextureScaled(fbTexture, 10, 10, 492, 492, 1, 1, 1, 1)
                end
            end
            fbPanel:addToUIManager()
            fbPanel:setVisible(true)
            print("[RTZ] FB: Display panel created (512x512)")
        end
    end

    if key == Keyboard.KEY_HOME then
        print("[RTZ] FB: Loading gradient from raw file...")
        local ok, r = pcall(function()
            local ready = Color.fbIsReady()
            print("[RTZ] FB: ready = " .. tostring(ready))
            if not ready then return "NOT READY -- wait longer" end
            if not fbTexture then return "no texture" end
            local path = "/home/user/Zomboid/Lua/RTZomboid_Bridge/test_frame.raw"
            local loaded = Color.fbLoadRaw(fbTexture, path)
            return "fbLoadRaw = " .. tostring(loaded) .. " -- should see gradient"
        end)
        print("[RTZ] FB: " .. (ok and tostring(r) or "ERROR: " .. tostring(r)))
    end

    if key == Keyboard.KEY_END then
        print("[RTZ] FB: Filling red...")
        local ok, r = pcall(function()
            if not Color.fbIsReady() or not fbTexture then return "not ready" end
            Color.fbFill(fbTexture, 255, 0, 0, 255)
            return "fbFill queued -- red next frame"
        end)
        print("[RTZ] FB: " .. (ok and tostring(r) or "ERROR: " .. tostring(r)))
    end
end

Events.OnKeyPressed.Add(onKeyPressed)

print("[RTZ] Framebuffer test: INSERT=create, HOME=fill red")
