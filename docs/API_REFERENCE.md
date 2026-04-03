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
