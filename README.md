# PZFB — Video Framebuffer for Project Zomboid

The first-ever pixel-level framebuffer for Project Zomboid. Draw anything — emulators, video playback, dynamic visualizations, mini-games — all rendered at GPU speed inside PZ's UI.

PZFB is a **library mod**. It provides the framebuffer API that other mods use as a dependency.

## Installation

### From Steam Workshop

1. Subscribe to **Video Framebuffer** on the Steam Workshop
2. Run the install script (one-time setup):
   - **Linux:** Open a terminal in the mod folder and run `bash install.sh`
   - **Windows:** Double-click `install.bat` in the mod folder
3. Restart Project Zomboid
4. Enable "Video Framebuffer" in the mod list

The install script copies 4 small Java class files to your PZ install directory. This is required because PZ's mod system doesn't load Java classes from mod folders.

### From GitHub

```bash
git clone https://github.com/expectbugs/pzfb.git
cd pzfb
bash install.sh
# Symlink the mod into PZ's mod directory:
ln -s "$(pwd)/mod/PZFB" ~/Zomboid/mods/PZFB
```

## For Mod Authors

Add PZFB as a dependency in your `mod.info`:

```
require=PZFB
```

### Quick Start

```lua
require "PZFB/PZFBApi"

local fb = nil

Events.OnGameStart.Add(function()
    if PZFB.isAvailable() then
        fb = PZFB.create(256, 240)  -- NES resolution
    end
end)

-- In your UI panel's render():
function MyPanel:render()
    ISPanel.render(self)
    if fb and PZFB.isReady(fb) then
        self:drawTextureScaled(PZFB.getTexture(fb), 0, 0, 512, 480, 1, 1, 1, 1)
    end
end

-- Update pixels:
PZFB.fill(fb, 255, 0, 0, 255)              -- solid red
PZFB.loadRaw(fb, "/path/to/frame.raw")      -- raw RGBA file

-- Clean up when done:
PZFB.destroy(fb)
```

### Input Capture

For interactive content (emulators, games), `PZFBInputPanel` provides full keyboard, mouse, and gamepad capture with four modes:

```lua
require "PZFB/PZFBInput"

local panel = PZFBInputPanel:new(100, 100, 512, 512, {
    mode = PZFBInput.MODE_EXCLUSIVE,           -- block all game input
    captureToggleKey = Keyboard.KEY_SCROLL,    -- press Scroll Lock to toggle capture
})
panel:initialise()
panel:addToUIManager()
panel:grabInput()

-- Event-driven:
function panel:onPZFBKeyDown(key) print("Down: " .. key) end
function panel:onPZFBKeyRepeat(key) end  -- fires every frame while held
function panel:onPZFBKeyUp(key) end
function panel:onPZFBMouseDown(x, y, btn) end
function panel:onPZFBGamepadDown(slot, button) end

-- Polling:
if panel:isKeyDown(Keyboard.KEY_LEFT) then ... end
local lx = panel:getGamepadAxis(2, "leftX")  -- analog stick

-- Action mapping:
panel:mapAction("jump", { key = Keyboard.KEY_SPACE })
panel:mapAction("jump", { gamepad = Joypad.AButton })
if panel:isActionDown("jump") then ... end

-- Input is auto-released on close, hide, player death, or menu return.
```

Modes: `MODE_EXCLUSIVE` (all input), `MODE_SELECTIVE` (registered keys only), `MODE_PASSIVE` (read-only), `MODE_FOCUS` (exclusive when mouse over panel). See `docs/API_REFERENCE.md` for full documentation.

## API Reference

### Framebuffer

| Function | Returns | Description |
|----------|---------|-------------|
| `PZFB.isAvailable()` | `boolean` | Check if class files are deployed |
| `PZFB.getVersion()` | `string\|nil` | Get PZFB version string |
| `PZFB.create(w, h)` | `fb\|nil` | Create framebuffer (NEAREST filtering) |
| `PZFB.createLinear(w, h)` | `fb\|nil` | Create framebuffer (LINEAR filtering) |
| `PZFB.isReady(fb)` | `boolean` | Check if GL texture is allocated |
| `PZFB.fill(fb, r, g, b, a)` | — | Fill with solid color (0-255 each) |
| `PZFB.loadRaw(fb, path)` | `boolean` | Load raw RGBA file (w*h*4 bytes, no header) |
| `PZFB.loadRawFrame(fb, path, idx)` | `boolean` | Load frame from concatenated raw file |
| `PZFB.fileSize(path)` | `number` | Get file size in bytes (-1 if not found) |
| `PZFB.getTexture(fb)` | `Texture\|nil` | Get PZ Texture for `drawTextureScaled()` |
| `PZFB.destroy(fb)` | — | Free GL resources |

### Audio (Direct FMOD — bypasses sound bank system)

| Function | Returns | Description |
|----------|---------|-------------|
| `PZFB.audioLoad(path)` | `boolean` | Load audio file from any absolute path |
| `PZFB.audioPlay()` | `boolean` | Start playback from beginning |
| `PZFB.audioPause()` | — | True pause (freezes position) |
| `PZFB.audioResume()` | — | Resume from paused position |
| `PZFB.audioStop()` | — | Stop and release audio |
| `PZFB.audioSetVolume(vol)` | — | Set volume (0.0–1.0) |
| `PZFB.audioSeek(posMs)` | — | Seek to position in milliseconds |
| `PZFB.audioGetPosition()` | `number` | Current position in milliseconds |
| `PZFB.audioGetLength()` | `number` | Total length in milliseconds |
| `PZFB.audioIsPlaying()` | `boolean` | Check if audio is playing |

### Streaming Video/Audio (ffmpeg)

| Function | Returns | Description |
|----------|---------|-------------|
| `PZFB.streamStart(path, scale, bufFrames)` | — | Start streaming (scale=0.0-1.0 of source) |
| `PZFB.streamFrame(fb, frameIndex)` | `boolean` | Load frame from ring buffer to texture |
| `PZFB.streamSeek(timeSec)` | — | Seek video (kills/restarts ffmpeg) |
| `PZFB.streamStop()` | — | Stop streaming, free resources |
| `PZFB.streamStatus()` | `number` | 0=idle 1=probing 2=buffering 3=ready 4=done 5=error |
| `PZFB.streamWidth/Height()` | `number` | Detected scaled dimensions |
| `PZFB.streamFps()` | `number` | Detected FPS |
| `PZFB.streamDuration()` | `number` | Total duration in seconds |
| `PZFB.streamTotalFrames()` | `number` | Estimated total frames |
| `PZFB.streamAudioPath()` | `string` | Path to temp WAV (empty if not ready) |
| `PZFB.streamAudioReady()` | `boolean` | Enough audio data for playback |
| `PZFB.streamAudioDone()` | `boolean` | Audio extraction fully complete |
| `PZFB.audioPlayFrom(posMs)` | `boolean` | Stop + play from position (reliable seek) |
| `PZFB.ffmpegAvailable()` | `boolean` | Check if ffmpeg is on PATH |

### Video Conversion (ffmpeg, legacy)

| Function | Returns | Description |
|----------|---------|-------------|
| `PZFB.convertStart(input, outDir, w, h)` | `boolean` | Start async ffmpeg conversion |
| `PZFB.convertStatus()` | `number` | 0=idle, 1=running, 2=done, 3=error |
| `PZFB.convertError()` | `string` | Error message if status==3 |
| `PZFB.convertReset()` | — | Reset status to idle |

### Utilities

| Function | Returns | Description |
|----------|---------|-------------|
| `PZFB.listDir(path)` | `string` | List files in directory (newline-separated) |
| `PZFB.readTextFile(path)` | `string` | Read text file from any absolute path |

### Game Process (Interactive Applications)

| Function | Returns | Description |
|----------|---------|-------------|
| `PZFB.gameStart(path, w, h, extraArgs)` | — | Launch game binary (stdout=RGBA frames, stdin=key events) |
| `PZFB.gameSendInput(keycode, pressed)` | — | Send key event. **Wire order: [pressed, keycode]** (pressed byte first) |
| `PZFB.gameIsRunning()` | `boolean` | Check if game process is alive |
| `PZFB.gameStatus()` | `number` | 0=idle, 1=starting, 2=running, 3=exited, 4=error |
| `PZFB.gameError()` | `string` | Error message if status==4 |
| `PZFB.gameStop()` | — | Kill game process, free resources |

Frames are uploaded via `PZFB.streamFrame(fb, frameIndex)` — the game API shares the stream ring buffer. Cannot run simultaneously with `PZFB.streamStart()`.

### Input System

| Feature | API | Description |
|---------|-----|-------------|
| Capture modes | `PZFBInput.MODE_EXCLUSIVE/SELECTIVE/PASSIVE/FOCUS` | Control what gets consumed |
| Toggle key | `captureToggleKey` option | Lock/unlock input to panel with one key |
| Keyboard | `onPZFBKeyDown/Repeat/Up`, `isKeyDown()` | Full press/hold/release + polling |
| Mouse | `onPZFBMouseDown/Up/Move/Wheel`, `isMouseButtonDown()` | Click, drag, scroll |
| Gamepad | `onPZFBGamepadDown/Up`, `getGamepadAxis()` | Buttons, D-pad, analog sticks, triggers |
| Actions | `mapAction()`, `isActionDown()`, `getActionValue()` | Named actions with multi-input bindings |
| Multi-controller | `setSlotDevice()`, `setSlotAutoAssign()` | Keyboard+mouse + multiple controllers |
| Selective capture | `captureKey()`, `captureBinding()` | Consume specific keys or game bindings |
| Config | `saveInputConfig()`, `loadInputConfig()` | Persist to `~/Zomboid/Lua/` |
| Auto-cleanup | Automatic | Released on close, hide, death, menu return |

See [docs/API_REFERENCE.md](docs/API_REFERENCE.md) for full documentation.

## How It Works

PZ's Lua VM (Kahlua) has a hardcoded whitelist of ~990 Java classes. We replace `zombie.core.Color` — an already-whitelisted class — with a patched version that adds framebuffer methods. All OpenGL calls are dispatched to PZ's render thread via `RenderThread.queueInvokeOnRenderContext()`.

See [docs/TECHNICAL.md](docs/TECHNICAL.md) for the complete technical deep-dive.

## Building from Source

Requires Java 25 JDK (PZ B42 uses class file version 69.0).

```bash
./build.sh            # Compile only
./build.sh --deploy   # Compile + deploy to PZ install
```

## FAQ

**Q: The game says "PZFB: Java class files not installed"**
A: Run the install script (`install.sh` or `install.bat`) and restart PZ.

**Q: After a PZ update, PZFB stopped working**
A: Steam updates can overwrite the class files. Run the install script again and restart.

**Q: Can I use multiple framebuffers?**
A: Yes. Each `PZFB.create()` call returns an independent framebuffer. Create as many as you need.

**Q: What pixel format does `loadRaw` expect?**
A: Raw RGBA bytes, 4 bytes per pixel (R, G, B, A), no header, no compression. File size must be exactly `width * height * 4` bytes.

**Q: Does this work in multiplayer?**
A: The framebuffer is client-side only. Each client needs the class files installed. The Lua mod can be required like any other mod.

## License

MIT — see [LICENSE](LICENSE).
