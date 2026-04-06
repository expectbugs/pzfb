# PZFB — Project Zomboid FrameBuffer Mod: Development Rules

## RULE ZERO: Verify Before Execute

***NEVER run commands based on guesses or assumptions. Before any PZ Lua API call, read the actual PZ source for correct function signatures. Before any Java class modification, verify the method exists and its signature matches. Before any GL call, verify the constant values. One correct approach beats three failed attempts.***

***NEVER GUESS. ALWAYS VERIFY. ALWAYS check the real source.***

## Critical: Source Code Verification

- **B42 client source (AUTHORITATIVE):** `/home/user/.local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid/media/lua/`
- **PZ Java jar:** `/home/user/.local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid/projectzomboid.jar`
- **DO NOT USE the Dedicated Server source** at `/opt/steamcmd/` — it is STALE, OUTDATED, and WRONG for Build 42.
- **Workshop mods at user's ~/Zomboid/mods/ are the user's own experiments** — do NOT use them as reliable references.
- **Verified Workshop mods** are at: `/home/user/.local/share/Steam/steamapps/workshop/content/108600/`

## System Environment

- **Machine:** beardos — Gentoo Linux, OpenRC (NOT systemd), RTX 3090, 32GB RAM
- **Python 3.13** — use `./venv/bin/python` (no system pip)
- **Java 25 JDK:** `/usr/lib64/openjdk-25/bin/javac` and `/usr/lib64/openjdk-25/bin/java`
  - MUST use Java 25 to compile against PZ's classes (class file version 69.0)
  - System default is Java 21 — always use the full path to Java 25
- **Java 21 JDK (system default):** `/usr/bin/javac` — DO NOT USE for PZ compilation
- **CFR Decompiler:** download from `https://github.com/leibnitz27/cfr/releases/download/0.152/cfr-0.152.jar`
- **PZ Install:** `/home/user/.local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid/`
- **Claude Code CLI:** `/usr/bin/claude` on beardos (Max subscription, Opus 4.6)

## Project Structure

```
~/pzfb/
├── CLAUDE.md              # This file
├── README.md              # Public-facing documentation
├── CHANGELOG.md           # Version history
├── LICENSE                # MIT
├── build.sh               # Compile + package
├── install.sh / .bat      # Deploy class files to PZ
├── uninstall.sh / .bat    # Remove class files
├── docs/
│   ├── TECHNICAL.md       # Complete technical docs (READ THIS FIRST)
│   ├── API_REFERENCE.md   # Full Lua API docs
│   └── test_framebuffer.lua
├── java/zombie/core/
│   └── Color.java         # Patched Color class source
├── build/                 # Compiled output (git-ignored)
├── class_files/           # Distribution .class files (Color + 4 inner)
└── mod/PZFB/
    ├── common/            # Required empty dir for B42
    └── 42/
        ├── mod.info       # B42 mod metadata
        ├── poster.png / icon.png
        └── media/lua/client/PZFB/
            ├── PZFBInit.lua   # Startup detection + error UI
            ├── PZFBApi.lua    # Public API
            └── PZFBInput.lua  # Input capture module
```

## The Core Technique

We replace `zombie.core.Color` (a Kahlua-whitelisted Java class) with a version that adds static methods for framebuffer operations. All OpenGL calls are dispatched via `RenderThread.queueInvokeOnRenderContext(Runnable)` to the render thread.

**Read `docs/TECHNICAL.md` for the complete explanation of what works, what doesn't, and why.**

## Key Facts (Verified — Do Not Re-Investigate)

1. **Kahlua whitelist is hardcoded** — `LuaManager$Exposer.exposeAll()` lists ~990 classes. New classes CANNOT be added without replacing the Exposer itself.
2. **New .class files on classpath are invisible to Lua** — even in existing packages. Only whitelisted classes are accessible.
3. **Class replacement works** — a `.class` file at `<PZ install>/zombie/core/Color.class` overrides the jar version because `"."` is first on the classpath.
4. **PZ Lua runs on MainThread** — which does NOT have the GL context. ALL OpenGL calls must go through `RenderThread.queueInvokeOnRenderContext()`.
5. **PZ's UI `render()` also runs on MainThread** — PZ's own draw methods (`drawTextureScaled` etc.) queue commands to SpriteRenderer, they don't call GL directly.
6. **`Texture.setData(ByteBuffer)` crashes from Lua** — it calls `glTexSubImage2D` on the wrong thread.
7. **`Texture.getData()` crashes from Lua** — cause unknown, crashes immediately on any texture.
8. **Anonymous inner classes** compile to `Color$1.class` through `Color$4.class`. ALL must be deployed.
9. **No reflection needed** — `TextureID.getID()` is public. PZ's own Texture constructor handles GL allocation; we just read the id and upload pixels via `glTexSubImage2D`.
10. **The decompiled Color.class recompiles cleanly** via CFR decompiler + Java 25 javac. No modifications needed to the original methods.

## Build Process

```bash
PZ="/home/user/.local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid"
JAVAC="/usr/lib64/openjdk-25/bin/javac"
JAVA="/usr/lib64/openjdk-25/bin/java"

# Decompile
$JAVA -jar cfr.jar --outputdir build "$PZ/projectzomboid.jar" zombie.core.Color

# Patch (append methods before final brace)
# ... edit build/zombie/core/Color.java ...

# Compile
$JAVAC -cp "$PZ/projectzomboid.jar" build/zombie/core/Color.java -d out

# Deploy ALL class files
cp out/zombie/core/Color*.class "$PZ/zombie/core/"


# Clean previous deployment
rm -f "$PZ/zombie/core/Color"*.class
```

## Lua API (v1.4.0)

### Framebuffer (Color.fb* static methods / PZFB.* wrappers):
```lua
PZFB.isAvailable()                    -- Class files deployed?
PZFB.create(w, h) / createLinear(w,h) -- Returns fb handle table
PZFB.isReady(fb)                      -- GL texture ready?
PZFB.fill(fb, r, g, b, a)            -- Fill solid color
PZFB.loadRaw(fb, path)               -- Load raw RGBA file
PZFB.loadRawFrame(fb, path, idx)      -- Load frame from concatenated raw file
PZFB.fileSize(path)                   -- Get file size in bytes
PZFB.getTexture(fb)                   -- Get Texture for drawing
PZFB.destroy(fb)                      -- Clean up
```

### Audio (direct FMOD — bypasses sound bank system):
```lua
PZFB.audioLoad(path)                  -- Load any audio file from absolute path
PZFB.audioPlay()                      -- Start playback
PZFB.audioPause() / audioResume()     -- True pause/resume
PZFB.audioStop()                      -- Stop and release
PZFB.audioSetVolume(vol)              -- 0.0–1.0
PZFB.audioSeek(posMs)                 -- Seek to millisecond position
PZFB.audioGetPosition()               -- Current position in ms
PZFB.audioGetLength()                 -- Total length in ms
PZFB.audioIsPlaying()                 -- Boolean
```

### Video conversion (ffmpeg via ProcessBuilder, async):
```lua
PZFB.convertStart(input, outDir, w, h) -- Start background conversion
PZFB.convertStatus()                   -- 0=idle, 1=running, 2=done, 3=error
PZFB.convertError()                    -- Error message string
PZFB.convertReset()                    -- Reset to idle
PZFB.ffmpegAvailable()                 -- Is ffmpeg on PATH?
```

### Utilities:
```lua
PZFB.listDir(path)                     -- Newline-separated filenames
PZFB.readTextFile(path)                -- Read text file from any path
```

### Input System (PZFBInput.lua — ISPanelJoypad subclass):
```lua
-- Capture modes:
PZFBInput.MODE_EXCLUSIVE               -- All keys consumed, game blocked
PZFBInput.MODE_SELECTIVE               -- Only registered keys consumed
PZFBInput.MODE_PASSIVE                 -- Read-only, no consumption
PZFBInput.MODE_FOCUS                   -- Exclusive when mouse over panel

-- Constructor:
PZFBInputPanel:new(x, y, w, h, {
    mode, captureToggleKey, escapeCloses, escapeReleasesCapture,
    playerNum, forceCursorVisible, autoGrab
})

-- Capture control:
panel:grabInput() / releaseInput() / isCapturing()
panel:setMode(mode) / getMode()

-- Keyboard callbacks: onPZFBKeyDown(key), onPZFBKeyRepeat(key), onPZFBKeyUp(key)
-- Mouse callbacks: onPZFBMouseDown(x,y,btn), onPZFBMouseUp(x,y,btn),
--                  onPZFBMouseMove(x,y,dx,dy), onPZFBMouseWheel(delta)
-- Gamepad callbacks: onPZFBGamepadDown(slot,btn), onPZFBGamepadUp(slot,btn),
--                    onPZFBGamepadAxis(slot,name,val), onPZFBGamepadTrigger(slot,side,pressed)

-- Polling: isKeyDown(key), isModifierDown(name), getMousePos(), isMouseButtonDown(btn)
--          getGamepadAxis(slot,name), isGamepadDown(slot,btn), isGamepadTriggerDown(slot,side)

-- Action mapping:
panel:mapAction(name, {key=, gamepad=, axis=, keyNeg=, keyPos=})
panel:isActionDown(name) / getActionValue(name)

-- Selective capture: captureKey(k), captureBinding(name), releaseAllCaptures()
-- Input slots: setSlotDevice(slot, type, id), setSlotAutoAssign(slot, bool)
-- Config: saveInputConfig(name), loadInputConfig(name) → ~/Zomboid/Lua/PZFB_input_*.cfg
```

### Input System Key Facts (Verified):
- **Base class is ISPanelJoypad** — provides joypad focus infrastructure
- **`isKeyConsumed(key)`** is called by Java AFTER `onKeyPress(key)` — both always run, consumption only controls propagation
- **`GameKeyboard.eatKeyPress(key)`** suppresses the next release event entirely (per-key flag)
- **`setJoypadFocus(playerNum, self)`** is required to receive PZ-routed gamepad events (sets `joypadData.focus`)
- **Gamepad callbacks fire from raw polling only** (not PZ-routed) to prevent duplicate events
- **D-pad is polled via `isJoypadUp/Down/Left/Right(cid)`** — separate from `isJoypadPressed` button polling
- **`Events.OnKeyPressed` fires on key RELEASE** (not press). `OnKeyStartPressed` fires on press.
- **`getFileWriter` method is `writeln(str)`** not `writeLine(str)`. `getFileReader` method is `readLine()`.
- **`Mouse.isButtonDown(btn)`** reads raw HW state — used as fallback for extra mouse button release detection
- **Safety cleanup** runs on close/hide/remove/player death/main menu return — all route through `_safeRelease()`

## B42 PZ Lua Sandbox Limitations

- **No `io.*` or `os.*` modules.** Lua is sandboxed.
- **No `next()`, `rawget(table, number)`, `string.byte()`, `math.huge`** — Kahlua VM limitations.
- **No `string.format(%g)`, `string.gsub(str, pat, TABLE)`** — Kahlua limitations.
- **File I/O:** `getFileWriter(filename, createIfNull, append)` and `getFileReader(filename, createIfNull)` write to `~/Zomboid/Lua/`. Writer methods: `writeln(str)`, `write(str)`, `close()`. Reader methods: `readLine()`, `close()`. **NOT `writeLine` — that does not exist.**
- **Events (verified names):** `Events.EveryOneMinute`, `Events.EveryTenMinutes`, `Events.OnGameStart`, `Events.OnTick`, `Events.OnKeyPressed` (fires on key RELEASE), `Events.OnKeyStartPressed` (fires on press), `Events.OnKeyKeepPressed` (fires while held), `Events.OnPlayerDeath`, `Events.OnMainMenuEnter`
- **B42 Stats API:** `stats:get(CharacterStat.HUNGER)` not `stats:getHunger()`
- **All UI APIs verified against B42 client source** — ISPanel, ISCollapsableWindow, ISRichTextPanel, etc.

## Related Projects

- **RT-Zomboid** (`~/rt-zomboid/`) — AI companion mod (Krang/Eris) that discovered this framebuffer technique during development. Separate project, separate repo.
- **ARIA** (`~/aria/`) — Separate project. Do not modify. Copy patterns if needed.

## User Profile

- **Name:** Adam (expectbugs)
- **System:** Gentoo Linux, OpenRC, XFCE4 desktop, RTX 3090, 32GB RAM, 4K display
- **Communication style:** Direct, casual, moves fast. Don't over-explain. Get to the point.
- **Key rule:** NEVER GUESS. Always verify against real source code. One correct approach beats three failed attempts. This was learned the hard way through multiple crashes.
