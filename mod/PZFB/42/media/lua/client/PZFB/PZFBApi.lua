-- PZFB — Video Framebuffer: Public API
-- Usage: require "PZFB/PZFBApi"
--
-- Example:
--   local fb = PZFB.create(256, 240)
--   -- In render():
--   if PZFB.isReady(fb) then
--       self:drawTextureScaled(PZFB.getTexture(fb), x, y, w, h, 1, 1, 1, 1)
--   end

require "PZFB/PZFBInit"

PZFB = PZFB or {}

--- Check if PZFB is available (class files deployed).
--- @return boolean
function PZFB.isAvailable()
    return PZFB.AVAILABLE == true
end

--- Get the PZFB version string.
--- @return string|nil version string, or nil if unavailable
function PZFB.getVersion()
    return PZFB.VERSION
end

--- Create a framebuffer with NEAREST filtering (pixel-perfect for emulators/pixel art).
--- GL texture allocation is async — poll isReady() before drawing or filling.
--- @param width number pixel width
--- @param height number pixel height
--- @return table|nil framebuffer handle, or nil if unavailable
function PZFB.create(width, height)
    if not PZFB.AVAILABLE then
        print("[PZFB] create() called but class files not deployed.")
        return nil
    end
    local tex = Color.fbCreate(width, height)
    if not tex then return nil end
    return { texture = tex, width = width, height = height }
end

--- Create a framebuffer with LINEAR filtering (smoother, better for video playback).
--- @param width number pixel width
--- @param height number pixel height
--- @return table|nil framebuffer handle, or nil if unavailable
function PZFB.createLinear(width, height)
    if not PZFB.AVAILABLE then
        print("[PZFB] createLinear() called but class files not deployed.")
        return nil
    end
    local tex = Color.fbCreateLinear(width, height)
    if not tex then return nil end
    return { texture = tex, width = width, height = height }
end

--- Check if a framebuffer's GL texture is ready for use.
--- @param fb table framebuffer handle from PZFB.create()
--- @return boolean
function PZFB.isReady(fb)
    if not fb or not fb.texture then return false end
    if not PZFB.AVAILABLE then return false end
    return Color.fbIsReady(fb.texture)
end

--- Fill a framebuffer with a solid RGBA color.
--- @param fb table framebuffer handle
--- @param r number red (0-255)
--- @param g number green (0-255)
--- @param b number blue (0-255)
--- @param a number alpha (0-255)
function PZFB.fill(fb, r, g, b, a)
    if not fb or not fb.texture then return end
    if not PZFB.AVAILABLE then return end
    Color.fbFill(fb.texture, r, g, b, a)
end

--- Load raw RGBA pixel data from a file into the framebuffer.
--- File must be exactly width * height * 4 bytes, raw RGBA, no header.
--- @param fb table framebuffer handle
--- @param path string absolute file path to raw RGBA data
--- @return boolean true if loaded successfully
function PZFB.loadRaw(fb, path)
    if not fb or not fb.texture then return false end
    if not PZFB.AVAILABLE then return false end
    return Color.fbLoadRaw(fb.texture, path)
end

--- Load a single frame from a concatenated raw RGBA file.
--- The file contains multiple frames of w*h*4 bytes each, back to back.
--- @param fb table framebuffer handle
--- @param path string absolute file path to concatenated raw RGBA data
--- @param frameIndex number zero-based frame index
--- @return boolean true if loaded successfully, false if out of range or error
function PZFB.loadRawFrame(fb, path, frameIndex)
    if not fb or not fb.texture then return false end
    if not PZFB.AVAILABLE then return false end
    return Color.fbLoadRawFrame(fb.texture, path, frameIndex)
end

--- Get the size of a file in bytes.
--- Useful for calculating total frame count: fileSize / (width * height * 4)
--- @param path string absolute file path
--- @return number file size in bytes, or -1 if file doesn't exist
function PZFB.fileSize(path)
    if not PZFB.AVAILABLE then return -1 end
    return Color.fbFileSize(path)
end

--- Get the underlying PZ Texture object for drawing.
--- Use with drawTextureScaled() in a UI panel's render() method.
--- @param fb table framebuffer handle
--- @return Texture|nil
function PZFB.getTexture(fb)
    if not fb then return nil end
    return fb.texture
end

--- Destroy a framebuffer and free its GL resources.
--- @param fb table framebuffer handle
function PZFB.destroy(fb)
    if not fb or not fb.texture then return end
    if PZFB.AVAILABLE then
        Color.fbDestroy(fb.texture)
    end
    fb.texture = nil
end
