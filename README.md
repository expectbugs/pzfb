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

For interactive content (emulators, games), use `PZFBInputPanel` to steal keyboard focus:

```lua
require "PZFB/PZFBInput"

local panel = PZFBInputPanel:new(100, 100, 512, 512)
panel:initialise()
panel:addToUIManager()
panel:grabInput()  -- WASD no longer moves the character

function panel:onPZFBKeyPress(key)
    print("Key pressed: " .. tostring(key))
end

function panel:onPZFBKeyRelease(key)
    print("Key released: " .. tostring(key))
end

-- Poll style:
if panel:isKeyDown(Keyboard.KEY_LEFT) then ... end

-- When done:
panel:releaseInput()
```

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

### Video Conversion (ffmpeg)

| Function | Returns | Description |
|----------|---------|-------------|
| `PZFB.convertStart(input, outDir, w, h)` | `boolean` | Start async ffmpeg conversion |
| `PZFB.convertStatus()` | `number` | 0=idle, 1=running, 2=done, 3=error |
| `PZFB.convertError()` | `string` | Error message if status==3 |
| `PZFB.convertReset()` | — | Reset status to idle |
| `PZFB.ffmpegAvailable()` | `boolean` | Check if ffmpeg is on PATH |

### Utilities

| Function | Returns | Description |
|----------|---------|-------------|
| `PZFB.listDir(path)` | `string` | List files in directory (newline-separated) |
| `PZFB.readTextFile(path)` | `string` | Read text file from any absolute path |

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
