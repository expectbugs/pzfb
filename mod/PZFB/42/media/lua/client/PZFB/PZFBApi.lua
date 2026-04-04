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

-- === Audio — Direct FMOD playback (bypasses sound bank system) ===

--- Load an audio file for playback. Stops any previously loaded audio.
--- @param path string absolute file path (OGG, WAV, MP3, etc.)
--- @return boolean true if loaded successfully
function PZFB.audioLoad(path)
    if not PZFB.AVAILABLE then return false end
    return Color.fbAudioLoad(path)
end

--- Start audio playback from the beginning.
--- @return boolean true if playback started
function PZFB.audioPlay()
    if not PZFB.AVAILABLE then return false end
    return Color.fbAudioPlay()
end

--- Pause audio playback (freezes position).
function PZFB.audioPause()
    if not PZFB.AVAILABLE then return end
    Color.fbAudioPause()
end

--- Resume audio playback from paused position.
function PZFB.audioResume()
    if not PZFB.AVAILABLE then return end
    Color.fbAudioResume()
end

--- Stop audio and release resources.
function PZFB.audioStop()
    if not PZFB.AVAILABLE then return end
    Color.fbAudioStop()
end

--- Set audio volume.
--- @param volume number 0.0 to 1.0
function PZFB.audioSetVolume(volume)
    if not PZFB.AVAILABLE then return end
    Color.fbAudioSetVolume(volume)
end

--- Seek audio to a position in milliseconds.
--- @param positionMs number position in milliseconds
function PZFB.audioSeek(positionMs)
    if not PZFB.AVAILABLE then return end
    Color.fbAudioSeek(positionMs)
end

--- Get current audio playback position in milliseconds.
--- @return number position in milliseconds
function PZFB.audioGetPosition()
    if not PZFB.AVAILABLE then return 0 end
    return Color.fbAudioGetPosition()
end

--- Get total audio length in milliseconds.
--- @return number length in milliseconds
function PZFB.audioGetLength()
    if not PZFB.AVAILABLE then return 0 end
    return Color.fbAudioGetLength()
end

--- Check if audio is currently playing.
--- @return boolean
function PZFB.audioIsPlaying()
    if not PZFB.AVAILABLE then return false end
    return Color.fbAudioIsPlaying()
end

-- === Video Conversion (ffmpeg) ===

--- Start async video conversion. Non-blocking.
--- @param inputPath string absolute path to input video file
--- @param outputDir string absolute path to output directory
--- @param width number target width in pixels
--- @param height number target height in pixels
--- @return boolean true if conversion started
function PZFB.convertStart(inputPath, outputDir, width, height)
    if not PZFB.AVAILABLE then return false end
    return Color.fbConvertStart(inputPath, outputDir, width, height)
end

--- Poll conversion status.
--- @return number 0=idle, 1=running, 2=done, 3=error
function PZFB.convertStatus()
    if not PZFB.AVAILABLE then return 0 end
    return Color.fbConvertStatus()
end

--- Get conversion error message.
--- @return string error message, or empty string
function PZFB.convertError()
    if not PZFB.AVAILABLE then return "" end
    return Color.fbConvertError()
end

--- Reset conversion status to idle.
function PZFB.convertReset()
    if not PZFB.AVAILABLE then return end
    Color.fbConvertReset()
end

--- Check if ffmpeg is available on the system PATH.
--- @return boolean
function PZFB.ffmpegAvailable()
    if not PZFB.AVAILABLE then return false end
    return Color.fbFFmpegAvailable()
end

--- Get ffmpeg diagnostic info (for troubleshooting).
--- @return string diagnostic details
function PZFB.ffmpegDiag()
    if not PZFB.AVAILABLE then return "PZFB not available" end
    return Color.fbFFmpegDiag()
end

-- === Utilities ===

--- List files in a directory.
--- @param dirPath string absolute path to directory
--- @return string newline-separated filenames, or empty string
function PZFB.listDir(dirPath)
    if not PZFB.AVAILABLE then return "" end
    return Color.fbListDir(dirPath)
end

--- Read a text file and return its contents as a string.
--- @param path string absolute file path
--- @return string file contents, or empty string if file doesn't exist
function PZFB.readTextFile(path)
    if not PZFB.AVAILABLE then return "" end
    return Color.fbReadTextFile(path)
end

-- === Streaming Video/Audio Playback ===

function PZFB.streamStart(inputPath, targetWidth)
    if not PZFB.AVAILABLE then return end
    Color.fbStreamStart(inputPath, targetWidth)
end

function PZFB.streamFrame(fb, frameIndex)
    if not fb or not fb.texture then return false end
    if not PZFB.AVAILABLE then return false end
    return Color.fbStreamFrame(fb.texture, frameIndex)
end

function PZFB.streamSeek(timeSec)
    if not PZFB.AVAILABLE then return end
    Color.fbStreamSeek(timeSec)
end

function PZFB.streamStop()
    if not PZFB.AVAILABLE then return end
    Color.fbStreamStop()
end

function PZFB.streamStatus()
    if not PZFB.AVAILABLE then return 0 end
    return Color.fbStreamStatus()
end

function PZFB.streamError()
    if not PZFB.AVAILABLE then return "" end
    return Color.fbStreamError()
end

function PZFB.streamWidth()
    if not PZFB.AVAILABLE then return 0 end
    return Color.fbStreamWidth()
end

function PZFB.streamHeight()
    if not PZFB.AVAILABLE then return 0 end
    return Color.fbStreamHeight()
end

function PZFB.streamFps()
    if not PZFB.AVAILABLE then return 24 end
    return Color.fbStreamFps()
end

function PZFB.streamDuration()
    if not PZFB.AVAILABLE then return 0 end
    return Color.fbStreamDuration()
end

function PZFB.streamAudioPath()
    if not PZFB.AVAILABLE then return "" end
    return Color.fbStreamAudioPath()
end

function PZFB.streamAudioReady()
    if not PZFB.AVAILABLE then return false end
    return Color.fbStreamAudioReady()
end

function PZFB.streamTotalFrames()
    if not PZFB.AVAILABLE then return 0 end
    return Color.fbStreamTotalFrames()
end

function PZFB.streamBufferStart()
    if not PZFB.AVAILABLE then return 0 end
    return Color.fbStreamBufferStart()
end

function PZFB.streamBufferCount()
    if not PZFB.AVAILABLE then return 0 end
    return Color.fbStreamBufferCount()
end
