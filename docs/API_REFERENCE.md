# PZFB API Reference

## Setup

```lua
require "PZFB/PZFBApi"
```

All functions are on the global `PZFB` table. All functions are safe to call even if class files aren't deployed — they return nil/false gracefully.

---

## Core API

### `PZFB.isAvailable()`

Check if PZFB class files are deployed and functional.

- **Returns:** `boolean`
- **When to use:** Before creating framebuffers, typically in `OnGameStart`.

```lua
Events.OnGameStart.Add(function()
    if not PZFB.isAvailable() then
        print("PZFB not installed")
        return
    end
    -- safe to create framebuffers
end)
```

### `PZFB.getVersion()`

Get the PZFB version string.

- **Returns:** `string|nil` — e.g. `"1.0.0"`, or nil if unavailable.

### `PZFB.create(width, height)`

Create a framebuffer with NEAREST filtering (pixel-perfect, ideal for emulators and pixel art).

- **Parameters:**
  - `width` (number) — pixel width
  - `height` (number) — pixel height
- **Returns:** `table|nil` — framebuffer handle, or nil if unavailable
- **Note:** GL texture allocation is async. Poll `PZFB.isReady(fb)` before drawing or filling.

```lua
local fb = PZFB.create(160, 144)  -- Game Boy resolution
```

### `PZFB.createLinear(width, height)`

Create a framebuffer with LINEAR filtering (smoother scaling, better for video playback).

- **Parameters:** same as `create()`
- **Returns:** same as `create()`

### `PZFB.isReady(fb)`

Check if a framebuffer's GL texture has been allocated by the render thread.

- **Parameters:**
  - `fb` (table) — framebuffer handle from `create()`
- **Returns:** `boolean`
- **Note:** Typically becomes ready within one frame (~16ms at 60fps). Poll in `render()` or `OnTick`.

### `PZFB.fill(fb, r, g, b, a)`

Fill the entire framebuffer with a solid RGBA color.

- **Parameters:**
  - `fb` (table) — framebuffer handle
  - `r` (number) — red, 0-255
  - `g` (number) — green, 0-255
  - `b` (number) — blue, 0-255
  - `a` (number) — alpha, 0-255
- **Note:** The fill is queued to the render thread. Visible on the next frame.

```lua
PZFB.fill(fb, 255, 0, 0, 255)    -- solid red
PZFB.fill(fb, 0, 0, 0, 0)        -- fully transparent
```

### `PZFB.loadRaw(fb, path)`

Load raw RGBA pixel data from a file into the framebuffer.

- **Parameters:**
  - `fb` (table) — framebuffer handle
  - `path` (string) — absolute file path to raw RGBA data
- **Returns:** `boolean` — true if loaded successfully, false on error
- **File format:** Raw RGBA bytes, 4 bytes per pixel (R, G, B, A), no header, no compression.
- **File size:** Must be exactly `width * height * 4` bytes.

```lua
-- 256x240 NES frame = 245,760 bytes
local ok = PZFB.loadRaw(fb, "/home/user/Zomboid/Lua/emulator/frame.raw")
```

**Common resolutions and file sizes:**

| Resolution | Use case | File size |
|-----------|----------|-----------|
| 64x64 | Test/icon | 16,384 bytes |
| 160x144 | Game Boy | 92,160 bytes |
| 256x240 | NES | 245,760 bytes |
| 320x240 | General | 307,200 bytes |
| 640x480 | VGA | 1,228,800 bytes |

### `PZFB.loadRawFrame(fb, path, frameIndex)`

Load a single frame from a concatenated raw RGBA file. The file contains multiple frames of `width * height * 4` bytes each, back to back (e.g., output from `ffmpeg -f rawvideo`).

- **Parameters:**
  - `fb` (table) — framebuffer handle
  - `path` (string) — absolute file path to concatenated raw RGBA data
  - `frameIndex` (number) — zero-based frame index
- **Returns:** `boolean` — true if loaded, false if out of range or error
- **Note:** Uses `RandomAccessFile` for seeking — does not read the entire file into memory.

```lua
-- Play video frames sequentially
local frameNum = 0
function MyPanel:onTick()
    if PZFB.loadRawFrame(fb, "/path/to/video.raw", frameNum) then
        frameNum = frameNum + 1
    else
        frameNum = 0  -- loop or stop
    end
end
```

### `PZFB.fileSize(path)`

Get the size of a file in bytes. Useful for calculating total frame count.

- **Parameters:**
  - `path` (string) — absolute file path
- **Returns:** `number` — file size in bytes, or -1 if file doesn't exist

```lua
local totalFrames = PZFB.fileSize("/path/to/video.raw") / (width * height * 4)
```

### `PZFB.getTexture(fb)`

Get the underlying PZ `Texture` object for drawing.

- **Parameters:**
  - `fb` (table) — framebuffer handle
- **Returns:** `Texture|nil`
- **Usage:** Pass to `drawTextureScaled()` in a UI panel's `render()` method.

```lua
function MyPanel:render()
    ISPanel.render(self)
    if fb and PZFB.isReady(fb) then
        local tex = PZFB.getTexture(fb)
        self:drawTextureScaled(tex, 10, 10, 492, 492, 1, 1, 1, 1)
    end
end
```

### `PZFB.destroy(fb)`

Destroy a framebuffer and free its GL resources.

- **Parameters:**
  - `fb` (table) — framebuffer handle
- **Note:** Always call this when you're done with a framebuffer to prevent resource leaks.

---

## Audio Playback (Direct FMOD)

Bypasses PZ's sound bank system entirely. Load and play any audio file from any absolute path — no script registration, no `media/sound/` directory required. Supports true pause/resume and seeking.

**Note:** One audio track at a time. Loading a new file releases the previous one.

### `PZFB.audioLoad(path)`

Load an audio file for playback.

- **Parameters:**
  - `path` (string) — absolute file path (OGG, WAV, MP3, FLAC — anything FMOD supports)
- **Returns:** `boolean` — true if loaded successfully
- **Note:** Stops and releases any previously loaded audio.

```lua
PZFB.audioLoad("/home/user/Zomboid/PZVP/converted/myvideo/audio.ogg")
```

### `PZFB.audioPlay()`

Start playback from the beginning.

- **Returns:** `boolean` — true if playback started

### `PZFB.audioPause()`

Pause playback. Position is preserved — call `audioResume()` to continue.

### `PZFB.audioResume()`

Resume playback from the paused position.

### `PZFB.audioStop()`

Stop playback and release the audio resource.

### `PZFB.audioSetVolume(volume)`

Set playback volume.

- **Parameters:**
  - `volume` (number) — 0.0 (silent) to 1.0 (full volume)

### `PZFB.audioSeek(positionMs)`

Seek to a position in milliseconds.

- **Parameters:**
  - `positionMs` (number) — target position in milliseconds

### `PZFB.audioGetPosition()`

Get the current playback position.

- **Returns:** `number` — current position in milliseconds

### `PZFB.audioGetLength()`

Get the total audio length.

- **Returns:** `number` — total length in milliseconds

### `PZFB.audioIsPlaying()`

Check if audio is currently playing.

- **Returns:** `boolean`

### Audio Example

```lua
-- Load and play audio synced with video
PZFB.audioLoad("/path/to/audio.ogg")
PZFB.audioPlay()
PZFB.audioSetVolume(0.8)

-- Pause/resume
PZFB.audioPause()
PZFB.audioResume()

-- Seek to 5 seconds
PZFB.audioSeek(5000)

-- Check status
local pos = PZFB.audioGetPosition()    -- e.g. 5000
local len = PZFB.audioGetLength()      -- e.g. 30000
local playing = PZFB.audioIsPlaying()  -- true/false

-- Clean up
PZFB.audioStop()
```

---

## Video Conversion (ffmpeg)

Convert video files to raw RGBA frames + OGG audio using ffmpeg, running in a background thread. Non-blocking — poll `convertStatus()` to check progress.

**Requires:** ffmpeg and ffprobe on the system PATH.

### `PZFB.convertStart(inputPath, outputDir, width, height)`

Start an asynchronous video conversion.

- **Parameters:**
  - `inputPath` (string) — absolute path to source video (MP4, AVI, MKV, etc.)
  - `outputDir` (string) — absolute path to output directory (created if needed)
  - `width` (number) — target width in pixels
  - `height` (number) — target height in pixels
- **Returns:** `boolean` — true if conversion started, false if already running or file not found
- **Output files:**
  - `video.raw` — concatenated raw RGBA frames (use with `loadRawFrame()`)
  - `audio.ogg` — extracted audio track (if source has audio)
  - `meta.txt` — metadata (width, height, frames, fps, file paths)

### `PZFB.convertStatus()`

Poll the conversion status.

- **Returns:** `number` — 0=idle, 1=running, 2=done, 3=error

### `PZFB.convertError()`

Get the error message from a failed conversion.

- **Returns:** `string` — error message, or empty string

### `PZFB.convertReset()`

Reset the conversion status back to idle. Only works when not currently converting.

### `PZFB.ffmpegAvailable()`

Check if ffmpeg is available on the system PATH.

- **Returns:** `boolean`

### Conversion Example

```lua
-- Check ffmpeg first
if not PZFB.ffmpegAvailable() then
    print("ffmpeg not found!")
    return
end

-- Start conversion
PZFB.convertStart("/path/to/video.mp4", "/output/dir", 256, 192)

-- Poll in OnTick or render
local status = PZFB.convertStatus()
if status == 1 then
    -- still converting...
elseif status == 2 then
    -- done! Load the video
    PZFB.convertReset()
elseif status == 3 then
    print("Error: " .. PZFB.convertError())
    PZFB.convertReset()
end
```

---

## Utilities

### `PZFB.listDir(dirPath)`

List files in a directory.

- **Parameters:**
  - `dirPath` (string) — absolute path to directory
- **Returns:** `string` — newline-separated filenames (files only, not subdirectories), or empty string if directory doesn't exist

```lua
local files = PZFB.listDir("/home/user/Zomboid/PZVP")
-- "video1.mp4\nvideo2.avi\n..."
```

### `PZFB.readTextFile(path)`

Read a text file and return its contents as a string. Useful for reading metadata files from any location (not restricted to `~/Zomboid/Lua/` like `getFileReader`).

- **Parameters:**
  - `path` (string) — absolute file path
- **Returns:** `string` — file contents (UTF-8), or empty string if file doesn't exist

```lua
local meta = PZFB.readTextFile("/path/to/meta.txt")
```

---

## Input Capture

```lua
require "PZFB/PZFBInput"
```

### `PZFBInputPanel`

ISPanel subclass that captures keyboard input when active. When capturing, the game does not process movement, inventory, or other key bindings.

### Constructor

```lua
local panel = PZFBInputPanel:new(x, y, width, height)
panel:initialise()
panel:addToUIManager()
```

### `panel:grabInput()`

Start capturing keyboard input. Game controls are blocked while capturing.

### `panel:releaseInput()`

Stop capturing keyboard input. Game controls resume.

### `panel:isCapturing()`

- **Returns:** `boolean` — whether input capture is active.

### `panel:isKeyDown(key)`

Check if a key is currently held down (polling-style).

- **Parameters:**
  - `key` (number) — Keyboard constant (e.g. `Keyboard.KEY_LEFT`)
- **Returns:** `boolean`

### Callbacks

Override these in your subclass or instance for event-driven input:

```lua
function panel:onPZFBKeyPress(key)
    -- called on key down
end

function panel:onPZFBKeyRelease(key)
    -- called on key up
end
```

### Full Example

```lua
require "PZFB/PZFBApi"
require "PZFB/PZFBInput"

local MyScreen = PZFBInputPanel:derive("MyScreen")

function MyScreen:new(x, y)
    local o = PZFBInputPanel.new(self, x, y, 512, 512)
    o.fb = nil
    return o
end

function MyScreen:createChildren()
    PZFBInputPanel.createChildren(self)
    if PZFB.isAvailable() then
        self.fb = PZFB.create(256, 240)
    end
    self:grabInput()
end

function MyScreen:render()
    PZFBInputPanel.render(self)
    if self.fb and PZFB.isReady(self.fb) then
        self:drawTextureScaled(PZFB.getTexture(self.fb), 0, 0, 512, 512, 1, 1, 1, 1)
    end
end

function MyScreen:onPZFBKeyPress(key)
    if key == Keyboard.KEY_ESCAPE then
        self:releaseInput()
        self:setVisible(false)
        self:removeFromUIManager()
        return
    end
    -- Handle game input here
end

function MyScreen:close()
    if self.fb then
        PZFB.destroy(self.fb)
        self.fb = nil
    end
    self:releaseInput()
    self:removeFromUIManager()
end
```
