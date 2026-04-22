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

### `PZFB.copyFile(src, dst)`

Copy a file from any path to any path. Creates parent directories at the destination if they don't exist. Overwrites the destination if it already exists.

- **Parameters:**
  - `src` (string) — absolute source file path
  - `dst` (string) — absolute destination file path
- **Returns:** `boolean` — true if copied successfully, false on error or missing source
- **Use case:** Deploy binaries from Workshop mods (Steam blocks `.exe` uploads — bundle as `.bin`/`.dat`, copy to a working location at runtime, then launch via `PZFB.gameStart()`).

```lua
local modDir = "/path/to/workshop/mod"
local gameDir = Core.getMyDocumentFolder() .. "/PZFB/games"
PZFB.copyFile(modDir .. "/mygame.dat", gameDir .. "/mygame")
PZFB.gameStart(gameDir .. "/mygame", 320, 200)
```

---

## Game Process (Interactive Applications)

Launch an external game binary with bidirectional I/O. The game writes raw RGBA frames to stdout (read into the stream ring buffer) and reads key events from stdin. Frames are uploaded to a texture via `PZFB.streamFrame()`.

**Note:** The game API shares the stream ring buffer. It cannot run simultaneously with `PZFB.streamStart()` — starting one stops the other.

### `PZFB.gameStart(binaryPath, width, height, extraArgs)`

Launch a game process. Legacy string-based form.

- **Parameters:**
  - `binaryPath` (string) — absolute path to the game binary
  - `width` (number) — frame width in pixels
  - `height` (number) — frame height in pixels
  - `extraArgs` (string|nil) — space-separated additional command line arguments
- **Note:** Automatically sets the binary's execute permission (Workshop may strip +x). Works inside Steam's pressure-vessel container (uses host linker for absolute paths).

> **Important:** `extraArgs` is a single whitespace-separated string. Arguments containing spaces MUST be wrapped in double quotes: `"path with spaces"`. The splitter handles `"..."` only — no nested quotes, no backslash escapes, no single quotes. For any argument derived from user input (ROM paths, Documents folder, usernames with spaces or Unicode), **prefer `PZFB.gameStartArgs()` (1.7.0+)** which bypasses parsing entirely.

### `PZFB.gameStartArgs(binaryPath, width, height, argv)` *(1.7.0+)*

Launch a game process with an argv array. Preferred form for any argument that may contain spaces, quotes, backslashes, or non-ASCII characters.

- **Parameters:**
  - `binaryPath` (string) — absolute path to the game binary
  - `width` (number) — frame width in pixels
  - `height` (number) — frame height in pixels
  - `argv` (table|nil) — Lua array (1-based integer keys) of string arguments; each element is passed to the child process verbatim. `nil` and empty table both mean "no extra args".
- **Behaviour:** Identical to `PZFB.gameStart()` once the child process is running — same stdout/stdin wiring, same status states, same `gameSendInput`/`gameStatus`/`gameStop` lifecycle.
- **Why use this:** Windows usernames with spaces (`C:\Users\Adam Marzello\...`), OneDrive-redirected Documents folders, apostrophes in paths (`O'Brien`), Cyrillic/CJK/accented-Latin usernames all pass through unchanged. No quoting, no escaping.

```lua
-- Compose argv from any user-supplied strings without worrying about escaping:
PZFB.gameStartArgs(binaryPath, 256, 240, {
    corePath,                -- e.g. "C:/Users/Adam Marzello/Documents/Zomboid/PZEMU/fceumm_libretro.dll"
    romPath,                 -- e.g. "C:/Users/Adam Marzello/Documents/Zomboid/PZEMU/roms/nes/Super Mario.nes"
    tostring(width),
    tostring(height),
    saveDir,
    saveDir,
})
```

### `PZFB.gameSendInput(keycode, pressed)`

Send a key event to the game process via stdin.

- **Parameters:**
  - `keycode` (number) — key code (0-255)
  - `pressed` (number) — 1 for pressed, 0 for released
- **Wire protocol:** Bytes are sent in order `[pressed, keycode]` — the pressed byte is written first, then the keycode byte. This is the **opposite order** from the Lua parameter list. Game binaries reading stdin must read pressed first, then keycode.

### `PZFB.gameIsRunning()`

- **Returns:** `boolean` — true if the game process is alive.

### `PZFB.gameStatus()`

- **Returns:** `number` — 0=idle, 1=starting, 2=running, 3=exited, 4=error

### `PZFB.gameError()`

- **Returns:** `string` — error message, or empty string if no error.

### `PZFB.gameStop()`

Kill the game process and free all resources. Safe to call multiple times.

> **Auto-cleanup (1.7.0+):** `gameStop()` is also invoked automatically by a JVM shutdown hook when PZ exits normally, so consumers don't need to call it in every exit path. Caveat: the hook does not run on SIGKILL, power loss, or Windows Task Manager "End task" — for those cases, the child process will still survive until next PZ launch (where `gameStart()` will reclaim its place in the ring buffer, but the orphan is only cleaned up by a separate PZ restart + consumer mod initialization path today).

### Multiplayer considerations

The Game Process API is **client-local**. Each player's PZ spawns its own child process on its own machine, and frames are never transported over PZ's network protocol. A consumer showing the same in-world TV to two players will render independent frame streams — if both walk up to the same NES and press "Play", each sees the frames produced by their own bridge process, not the other player's. True frame-sharing across MP would require transporting roughly 17 MB/s of RGBA per concurrent stream plus an input-forwarding consensus layer; that is out of scope for PZFB at this time and deferred to a future major version.

### Game Example

```lua
-- Launch a game that outputs 256x240 RGBA frames to stdout
PZFB.gameStart("/path/to/mygame", 256, 240)

-- Create framebuffer to display frames
local fb = PZFB.create(256, 240)
local currentFrame = 0

-- In render():
if PZFB.gameStatus() >= 2 and fb and PZFB.isReady(fb) then
    if PZFB.streamFrame(fb, currentFrame) then
        currentFrame = currentFrame + 1
    end
    self:drawTextureScaled(PZFB.getTexture(fb), 0, 0, 512, 480, 1, 1, 1, 1)
end

-- Send input (from PZFBInputPanel callback):
function panel:onPZFBKeyDown(key)
    PZFB.gameSendInput(key, 1)  -- wire: [0x01, key]
end
function panel:onPZFBKeyUp(key)
    PZFB.gameSendInput(key, 0)  -- wire: [0x00, key]
end

-- Cleanup:
PZFB.gameStop()
PZFB.destroy(fb)
```

---

## Input Capture (v2.0)

```lua
require "PZFB/PZFBInput"
```

### `PZFBInputPanel`

ISPanelJoypad subclass providing comprehensive keyboard, mouse, and gamepad input capture. Supports four capture modes, a capture toggle key, action mapping, multi-controller input slots, and automatic cleanup on close/crash.

### Capture Modes

```lua
PZFBInput.MODE_EXCLUSIVE  -- Consume ALL keys, block game entirely
PZFBInput.MODE_SELECTIVE  -- Consume only registered keys
PZFBInput.MODE_PASSIVE    -- Read everything, consume nothing
PZFBInput.MODE_FOCUS      -- Exclusive when mouse over panel, passive otherwise
```

### Constructor

```lua
local panel = PZFBInputPanel:new(x, y, width, height, {
    mode              = PZFBInput.MODE_EXCLUSIVE,  -- capture mode
    captureToggleKey  = nil,          -- nil or Keyboard.KEY_* to toggle capture
    escapeCloses      = true,         -- ESC closes panel (default true)
    escapeReleasesCapture = true,     -- ESC releases toggle capture (safety)
    playerNum         = 0,            -- PZ player number (splitscreen)
    forceCursorVisible = true,        -- show cursor over panel
    autoGrab          = false,        -- grab input on createChildren
})
panel:initialise()
panel:addToUIManager()
```

### Capture Control

- `panel:grabInput()` — Start capturing input. Auto-detects connected controllers, suppresses PZ's gamepad and keyboard binding processing.
- `panel:releaseInput()` — Stop capturing, restore all state (bindings, gamepad, joypad bind).
- `panel:isCapturing()` — Returns `boolean`.
- `panel:setMode(mode)` — Change capture mode at runtime.
- `panel:getMode()` — Returns current mode.

### Keyboard Callbacks

```lua
function panel:onPZFBKeyDown(key) end    -- first frame of key press
function panel:onPZFBKeyRepeat(key) end  -- every frame while key is held
function panel:onPZFBKeyUp(key) end      -- key release
```

### Mouse Callbacks

```lua
function panel:onPZFBMouseDown(x, y, btn) end    -- btn: 0=left, 1=right, 2+=extra
function panel:onPZFBMouseUp(x, y, btn) end
function panel:onPZFBMouseMove(x, y, dx, dy) end  -- position (panel-relative) + delta
function panel:onPZFBMouseWheel(delta) end
```

### Gamepad Callbacks

```lua
function panel:onPZFBGamepadDown(slot, button) end   -- Joypad.AButton, DPadUp, etc.
function panel:onPZFBGamepadUp(slot, button) end
function panel:onPZFBGamepadAxis(slot, axisName, value) end  -- "leftX","leftY","rightX","rightY"
function panel:onPZFBGamepadTrigger(slot, side, pressed) end -- "left"/"right"
function panel:onPZFBCaptureToggle(active) end   -- toggle key state changed
function panel:onPZFBSlotAssigned(slot, controllerId) end  -- controller auto-assigned
```

**PlayStation position remapping:** On PS controllers (DualSense, DualShock), face button
constants are automatically swapped (A↔B, X↔Y) so they match physical position rather
than PZ's label-based mapping. Consumers always receive position-correct button constants
regardless of controller type — no per-mod remapping needed.

**Gamepad suppression:** When capturing (EXCLUSIVE, SELECTIVE, FOCUS+mouse over, or toggle
active), PZ's own gamepad processing is fully blocked — the game character will not respond
to the captured controller. Released automatically when capture ends.

### Keyboard Polling

- `panel:isKeyDown(key)` — Is key currently held?
- `panel:isModifierDown(name)` — `"shift"`, `"ctrl"`, or `"alt"` (checks both L+R variants).

### Mouse Polling

- `panel:getMousePos()` — Returns `x, y` relative to panel.
- `panel:isMouseButtonDown(btn)` — 0=left, 1=right, 2=middle.

### Gamepad Polling

- `panel:getGamepadAxis(slot, name)` — Returns `-1.0` to `1.0`. Names: `"leftX"`, `"leftY"`, `"rightX"`, `"rightY"`.
- `panel:isGamepadDown(slot, button)` — Joypad button constant.
- `panel:isGamepadTriggerDown(slot, side)` — `"left"` or `"right"`.

### Selective Capture (MODE_SELECTIVE)

Register which keys to consume. Unregistered keys pass through to the game.

```lua
panel:captureKey(Keyboard.KEY_SPACE)          -- single key
panel:captureKeys({Keyboard.KEY_LEFT, Keyboard.KEY_RIGHT})  -- batch
panel:captureBinding("Forward")               -- by game action name (follows rebinds)
panel:releaseKey(Keyboard.KEY_SPACE)
panel:releaseBinding("Forward")
panel:releaseAllCaptures()
```

### Action Mapping

Map named actions to physical inputs. Multiple bindings per action supported.

```lua
-- Define
panel:mapAction("jump", { key = Keyboard.KEY_SPACE })
panel:mapAction("jump", { gamepad = Joypad.AButton })
panel:mapAction("moveX", { axis = "leftX" })
panel:mapAction("moveX", { keyNeg = Keyboard.KEY_A, keyPos = Keyboard.KEY_D })
panel:unmapAction("jump")

-- Query
panel:isActionDown("jump")       -- true if ANY binding is active
panel:getActionValue("moveX")    -- -1.0 to 1.0 (analog-aware)
```

### Input Slots (Multi-Controller)

**Controllers are auto-detected** when `grabInput()` is called. Connected controllers
are automatically assigned to slots 2+ with no configuration required. Hot-plug is
supported — controllers connected or disconnected mid-session are handled automatically.

```lua
-- Auto-detection (default, zero config):
panel:grabInput()                           -- scans and assigns all connected controllers

-- Discovery API:
local controllers = panel:getConnectedControllers()
-- Returns: { {id=0, name="Xbox Controller"}, {id=1, name="PS5 Controller"}, ... }

-- Manual override (optional, for advanced use):
panel:setSlotDevice(1, "keyboard")          -- slot 1 = keyboard + mouse (default)
panel:setSlotDevice(2, "controller", 0)     -- slot 2 = controller #0
panel:setSlotAutoAssign(2, true)            -- auto-assign next controller press
```

### Config Persistence

Save/load action mappings and settings to `~/Zomboid/Lua/`.

```lua
panel:saveInputConfig("mymod")    -- writes PZFB_input_mymod.cfg
panel:loadInputConfig("mymod")    -- reads and applies
```

### Safety

Input capture is **automatically released** when:
- Panel is closed (`close()`)
- Panel is hidden (`setVisible(false)`)
- Panel is removed (`removeFromUIManager()`)
- Player dies
- Game returns to main menu

No manual cleanup needed. `_safeRelease()` is idempotent.

### Full Example — Emulator

```lua
require "PZFB/PZFBApi"
require "PZFB/PZFBInput"

local EmuScreen = PZFBInputPanel:derive("EmuScreen")

function EmuScreen:new(x, y)
    local o = PZFBInputPanel.new(self, x, y, 512, 512, {
        mode = PZFBInput.MODE_EXCLUSIVE,
        captureToggleKey = Keyboard.KEY_SCROLL,
        escapeCloses = false,
    })
    o.fb = nil
    return o
end

function EmuScreen:createChildren()
    PZFBInputPanel.createChildren(self)
    if PZFB.isAvailable() then
        self.fb = PZFB.create(256, 240)
    end
    self:grabInput()
    -- Map emulator controls
    self:mapAction("up",    { key = Keyboard.KEY_W, gamepad = Joypad.DPadUp })
    self:mapAction("down",  { key = Keyboard.KEY_S, gamepad = Joypad.DPadDown })
    self:mapAction("left",  { key = Keyboard.KEY_A, gamepad = Joypad.DPadLeft })
    self:mapAction("right", { key = Keyboard.KEY_D, gamepad = Joypad.DPadRight })
    self:mapAction("a",     { key = Keyboard.KEY_SPACE, gamepad = Joypad.AButton })
    self:mapAction("b",     { key = Keyboard.KEY_LSHIFT, gamepad = Joypad.BButton })
end

function EmuScreen:render()
    PZFBInputPanel.render(self)
    if self.fb and PZFB.isReady(self.fb) then
        self:drawTextureScaled(PZFB.getTexture(self.fb), 0, 0, 512, 512, 1, 1, 1, 1)
    end
end

function EmuScreen:onPZFBKeyDown(key)
    if key == Keyboard.KEY_ESCAPE then
        self:close()
    end
end

function EmuScreen:onPZFBCaptureToggle(active)
    -- Draw border glow or "INPUT LOCKED" indicator
end

function EmuScreen:close()
    if self.fb then PZFB.destroy(self.fb) end
    PZFBInputPanel.close(self)
    self:removeFromUIManager()
end
```

### Full Example — Video Player (Selective)

```lua
local VideoUI = PZFBInputPanel:derive("VideoUI")

function VideoUI:new(x, y)
    local o = PZFBInputPanel.new(self, x, y, 640, 480, {
        mode = PZFBInput.MODE_SELECTIVE,
    })
    return o
end

function VideoUI:createChildren()
    PZFBInputPanel.createChildren(self)
    self:grabInput()
    -- Only capture playback keys — WASD still moves character
    self:captureKey(Keyboard.KEY_SPACE)       -- pause/play
    self:captureKey(Keyboard.KEY_LEFT)        -- seek back
    self:captureKey(Keyboard.KEY_RIGHT)       -- seek forward
    self:captureKey(Keyboard.KEY_UP)          -- volume up
    self:captureKey(Keyboard.KEY_DOWN)        -- volume down
end

function VideoUI:onPZFBKeyDown(key)
    if key == Keyboard.KEY_SPACE then
        -- toggle pause
    elseif key == Keyboard.KEY_LEFT then
        -- seek back 5s
    elseif key == Keyboard.KEY_RIGHT then
        -- seek forward 5s
    end
end
```
