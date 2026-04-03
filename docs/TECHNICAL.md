# PZFB — Project Zomboid FrameBuffer: Technical Documentation

## What This Is

A system for rendering arbitrary pixel data inside Project Zomboid's UI. This enables emulators, video playback, dynamic graphical content, and anything else that produces a framebuffer — all rendered at GPU speed inside PZ's own UI panels.

## How It Works

### The Core Problem

PZ's Lua VM (Kahlua) can create Texture objects and draw them, but cannot write pixel data to them. The `Texture.setData(ByteBuffer)` method exists but calls `glTexSubImage2D` directly — and PZ's Lua runs on the MainThread which does NOT have the OpenGL context. The GL context lives on a separate render thread. Any direct GL call from Lua/Kahlua crashes the JVM with "No context is current."

### The Solution

We replace `zombie.core.Color` (a whitelisted Java class exposed to Kahlua) with a patched version that adds static methods for framebuffer operations. These methods use `RenderThread.queueInvokeOnRenderContext(Runnable)` to dispatch all OpenGL calls to the correct thread.

### The Pipeline

```
1. Lua calls Color.fbCreate(width, height)
   → Java allocates a ByteBuffer (width * height * 4 bytes, RGBA)
   → Java creates a Texture(width, height, 0) wrapper
   → Java queues GL work to render thread:
       - glGenTextures() → allocates GPU texture
       - glBindTexture(GL_TEXTURE_2D, id)
       - glTexImage2D(..., buffer) → uploads initial pixel data
       - glTexParameteri(..., NEAREST filtering)
       - Reflection sets GL id + dimensions on PZ's TextureID
   → Returns Texture to Lua

2. Lua calls Color.fbFill(texture, r, g, b, a) — OR — Color.fbLoadRaw(texture, path)
   → Java fills ByteBuffer with pixel data (solid color or from file)
   → Java queues GL work to render thread:
       - glBindTexture(GL_TEXTURE_2D, id)
       - glTexSubImage2D(..., buffer) → uploads new pixel data

3. Lua draws in a UI panel's render() method:
   → self:drawTextureScaled(texture, x, y, w, h, 1, 1, 1, 1)
   → PZ queues this through its SpriteRenderer
   → Render thread draws the texture
```

### Why This Works

- `RenderThread.queueInvokeOnRenderContext(Runnable)` is PZ's own mechanism for dispatching GL work. It's what `reloadFromFile()` uses internally. It's a public static method on `zombie.core.opengl.RenderThread`.
- The `Runnable` executes on the render thread where the GL context is bound.
- PZ's `Texture` class is on Kahlua's exposure whitelist (hardcoded in `LuaManager$Exposer.exposeAll()`), so Lua can call methods on Texture objects and draw them.
- `Color` is also on the whitelist, so Lua can call our added static methods.

### The Class Replacement Mechanism

PZ's Java classpath is `"."` (the install directory) and `projectzomboid.jar`. A `.class` file placed at `<PZ install>/zombie/core/Color.class` takes priority over the version inside `projectzomboid.jar` because `"."` comes first in the classpath.

The patched `Color.class` is compiled from a decompiled version of the original (via CFR decompiler) with our static methods appended. ALL original Color methods are preserved exactly — the game functions normally.

Anonymous inner classes (the Runnables) compile to `Color$1.class`, `Color$2.class`, `Color$3.class`. ALL of these must be deployed alongside `Color.class`.

## API Reference

### From Lua:

```lua
-- Create a framebuffer texture (GL init is async — queued to render thread)
local tex = Color.fbCreate(width, height)

-- Check if GL initialization is complete (call before fbFill/fbLoadRaw)
local ready = Color.fbIsReady()  -- returns boolean

-- Fill entire texture with solid RGBA color (values 0-255)
Color.fbFill(tex, r, g, b, a)

-- Load raw RGBA pixel data from a file
-- File must be exactly width * height * 4 bytes, raw RGBA, no header
Color.fbLoadRaw(tex, "/full/path/to/file.raw")

-- Verify our patched code is loaded
local msg = Color.fbPing()  -- returns "RT-Zomboid FrameBuffer active!"

-- Draw in a UI panel's render() method:
self:drawTextureScaled(tex, x, y, w, h, 1, 1, 1, 1)
```

### Timing:

- `fbCreate()` returns immediately. GL allocation happens on next render thread cycle (~16ms at 60fps).
- `fbFill()` and `fbLoadRaw()` queue pixel uploads. Visible on next frame.
- `fbIsReady()` returns true once GL init completes. Poll it before writing pixels.
- For continuous updates (emulator/video), call `fbLoadRaw()` every frame from a render() method or periodic tick.

### File Format for fbLoadRaw:

- Raw RGBA bytes, no header, no compression
- 4 bytes per pixel: R, G, B, A (each 0-255)
- Total file size must be exactly `width * height * 4` bytes
- Example: 64x64 texture = 16,384 bytes
- Example: 160x144 (Gameboy) = 92,160 bytes
- Example: 256x240 (NES) = 245,760 bytes

## Verified Working (Tested 2026-04-03)

- [x] `Color.fbPing()` — custom Java code executes from Lua
- [x] `Color.fbCreate(64, 64)` — creates texture, returns to Lua, no crash
- [x] `Color.fbIsReady()` — returns true after GL init completes
- [x] `Color.fbFill(tex, 255, 0, 0, 255)` — solid red fill, visible on screen
- [x] `Color.fbLoadRaw(tex, path)` — loads gradient from raw file, visible on screen
- [x] `drawTextureScaled()` — renders at any size in UI panel
- [x] Multiple updates (fill red, then load gradient, then fill red again)
- [x] No crashes across all tests
- [x] Game functions normally with patched Color class

## What Does NOT Work

### Direct GL calls from Lua/Kahlua thread
Any `GL11.glGenTextures()`, `glBindTexture()`, `glTexImage2D()`, `glTexSubImage2D()` called from the MainThread (where Kahlua runs) crashes the JVM with:
```
FATAL ERROR in native method: Thread[#66,MainThread,5,Main]:
No context is current or a function that is not available in the
current context was called.
```
**Must use `RenderThread.queueInvokeOnRenderContext()`.**

### Texture.setData(ByteBuffer) from Lua
Crashes for the same reason — it calls `glTexSubImage2D` directly inside `TextureID.setData()`. Cannot be used from Lua.

### Texture.getData() from Lua
Crashes the game immediately when called on any texture (blank or loaded). Cause unknown but likely GL-thread related.

### New Java classes in new packages
A class at `zombie/rtzomboid/FrameBufferTest.class` on the classpath is NOT visible to Lua. Kahlua's `LuaManager$Exposer.exposeAll()` is a hardcoded whitelist of ~990 specific classes. New classes are invisible to Lua regardless of package.

### New Java classes in existing packages
A class at `zombie/core/textures/FrameBufferTexture.class` (same package as exposed Texture class) is also NOT visible to Lua. The whitelist is per-class, not per-package.

### Custom Java class loaded from mod directory
`.class` files placed in the mod's directory structure (`mod/RTZomboid/zombie/...`) are NOT loaded by PZ. The classpath does not include mod directories. Only the PZ install directory `"."` and `projectzomboid.jar` are on the classpath.

### Extending PZ classes with Java 21
PZ is compiled with Java 25 (class file version 69.0). Java 21 javac (class version 65.0) cannot compile against PZ's jar — "class file has wrong version" error. **Must use Java 25 javac.**

## Build Requirements

- **Java 25 JDK** — required to compile against PZ's classes
  - PZ ships Zulu JRE 25.0.1 (no javac)
  - System needs JDK 25: on Gentoo, `dev-java/openjdk-25.0.2`
  - Path on this system: `/usr/lib64/openjdk-25/bin/javac`

- **CFR Decompiler** — for decompiling Color.class to patch it
  - Downloaded to `/tmp/cfr.jar`
  - URL: `https://github.com/leibnitz27/cfr/releases/download/0.152/cfr-0.152.jar`

- **PZ install directory**: `/home/user/.local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid/`

## Build Process

```bash
PZ="/home/user/.local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid"
JAVAC="/usr/lib64/openjdk-25/bin/javac"
JAVA="/usr/lib64/openjdk-25/bin/java"

# 1. Decompile Color
$JAVA -jar cfr.jar --outputdir /tmp/pzfb_build "$PZ/projectzomboid.jar" zombie.core.Color

# 2. Patch Color.java (append framebuffer methods before final closing brace)

# 3. Compile
$JAVAC -cp "$PZ/projectzomboid.jar" /tmp/pzfb_build/zombie/core/Color.java -d /tmp/pzfb_out

# 4. Deploy ALL class files (Color.class + Color$1.class + Color$2.class + Color$3.class)
mkdir -p "$PZ/zombie/core"
cp /tmp/pzfb_out/zombie/core/Color*.class "$PZ/zombie/core/"
```

## Key Java Classes and Methods (Verified)

### Exposed to Lua (in LuaManager$Exposer whitelist):
- `zombie.core.textures.Texture` — the main texture class
- `zombie.core.textures.VideoTexture` — extends Texture, Bink video
- `zombie.core.textures.ColorInfo` — RGBA floats
- `zombie.core.Color` — RGBA floats (OUR REPLACEMENT TARGET)
- `zombie.core.textures.TextureID` — internal, holds GL id and dimensions
- `zombie.core.textures.TileDepthTexture` — has setPixel but only for depth maps

### Not exposed but accessible from Java:
- `zombie.core.opengl.RenderThread` — `queueInvokeOnRenderContext(Runnable)` dispatches GL work
- `org.lwjgl.opengl.GL11` — direct OpenGL calls (glGenTextures, glTexImage2D, etc.)
- `zombie.core.textures.TextureID` — private fields (id, width, height, widthHw, heightHw) accessed via reflection

### GL Constants Used:
- `0x0DE1` = GL_TEXTURE_2D
- `0x1908` = GL_RGBA
- `0x1401` = GL_UNSIGNED_BYTE
- `0x2801` = GL_TEXTURE_MIN_FILTER
- `0x2800` = GL_TEXTURE_MAG_FILTER
- `0x2600` = GL_NEAREST

### TextureID Private Fields (set via reflection):
- `id` (int) — OpenGL texture handle
- `width` (int) — logical width
- `height` (int) — logical height
- `widthHw` (int) — hardware/GPU width
- `heightHw` (int) — hardware/GPU height

## Architecture Notes

### Thread Model
- **MainThread** — runs Kahlua Lua VM, game logic, events, UI logic (render/prerender Lua calls)
- **RenderThread** — owns the OpenGL context, processes SpriteRenderer queue, executes RenderContext queue
- UI's `render()` method runs on MainThread, NOT RenderThread. PZ's `drawTextureScaled` etc. queue draw commands to SpriteRenderer's ring buffer, which the RenderThread processes.

### Kahlua Exposure System
- `LuaManager$Exposer` extends `LuaJavaClassExposer`
- `exposeAll()` hardcodes ~990 classes via `setExposed(Class<?>)`
- `shouldExpose(Class<?>)` checks the `exposed` HashSet
- Only whitelisted classes have their methods/constructors accessible from Lua
- Methods of whitelisted classes that return non-whitelisted types: the returned Java object can be passed around in Lua but its methods cannot be called

### PZ Classpath
- Defined in `ProjectZomboid64.json`: `[".", "projectzomboid.jar"]`
- `"."` = PZ install directory. Class files here override jar contents.
- PZ does NOT add mod directories to the classpath.
- Workshop mod `.class` files (like MultiHitLimiter) replace vanilla classes in the `zombie/` package hierarchy. They work because they override existing classes at the same package path.

## Performance Expectations

- `fbLoadRaw` reads a file and queues a GL upload. For a 256x240 NES frame (245KB), this should easily sustain 30fps.
- File I/O is the bottleneck, not GL upload. `glTexSubImage2D` for small textures is microseconds.
- For higher performance, `fbFill`-style direct ByteBuffer writes (no file I/O) could sustain 60fps easily.
- A future `fbSetPixels(texture, luaTable)` or similar could bypass file I/O entirely if Kahlua can pass arrays to Java efficiently.

## Distribution / Installation Problem

### Current State
The patched `Color*.class` files (Color.class, Color$1.class, Color$2.class, Color$3.class) must be placed in the PZ install directory at `<PZ>/zombie/core/`. PZ does NOT load .class files from mod directories — the classpath is `"."` (install dir) + `projectzomboid.jar` only.

This means the current install is two steps:
1. Copy 4 class files to PZ install directory
2. Enable the Lua mod from Workshop

### Goal: One-Click Workshop Install
For a proper Steam Workshop release, the mod needs to work without manual file copying. The TrueVideo mod author (Workshop ID 3665970132) claimed his "real version" would be a simple Workshop download, implying he solved this distribution problem. Since his framebuffer technique appears to be the same as ours (he got it working with no slowdowns), he likely also solved the deployment problem.

### Possible Solutions to Investigate
1. **Lua-side auto-deploy:** On game start, a Lua script copies the .class files from the mod's media directory to the PZ install directory. Would require a game restart to take effect (classes loaded at JVM startup). Could detect if deployment is needed and prompt the user.

2. **PZ's `-classpath` or `-cp` manipulation:** The native launcher (`ProjectZomboid64`) reads `ProjectZomboid64.json` for classpath. If mod directories could be added to this JSON, or if there's an environment variable override, class files could stay in the mod directory.

3. **Java agent / instrumentation:** A Java agent can modify classes at load time. If PZ supports `-javaagent` JVM args, an agent could intercept Color class loading and inject our methods without replacing the file on disk.

4. **Custom classloader hook:** If PZ's code has any mod-loading hook that touches the classloader, we could exploit it to add our mod directory to the class search path.

5. **Self-extracting on first run:** The Lua mod detects the classes aren't deployed, extracts them from a bundled location (e.g., base64-encoded in a Lua string or as a binary file in media/), writes them to the PZ install dir, and prompts for restart. Ugly but functional.

The fresh instance should investigate these approaches. The TrueVideo author's approach is the strongest lead — if he claimed Workshop-only distribution, one of these methods works.

## Input Capture Problem

### The Problem
The framebuffer solves OUTPUT (pixels on screen). INPUT (keystrokes to an emulator) is a separate challenge. `Events.OnKeyPressed` gives raw key codes, but:

1. **Key conflict:** When the player presses arrow keys for an emulator, PZ also moves their character. Keypresses go to BOTH the game and our code. We need to "eat" the keystroke so PZ doesn't see it.
2. **Key-down/key-up timing:** Emulators expect press/release events. `OnKeyPressed` may only fire on press. Need to investigate `OnKeyStartPressed` vs `OnKeyPressed` and whether there's an `OnKeyReleased`.
3. **Modifier keys:** Shift, Ctrl, Alt combinations for emulator hotkeys (save state, speed up, etc.)

### Approaches to Investigate

1. **ISTextEntryBox focus model:** PZ's own text entry boxes capture keyboard focus and prevent game input while typing. Study how this works — it's the proven pattern for stealing keyboard from the game. The relevant code is in `ISTextEntryBox` and the Java `UIElement` focus system.

2. **Timed action / seated state:** When a character is "using" the terminal furniture, lock them in place like sitting in a vehicle. WASD does nothing in-game, freeing those keys for the emulator. PZ already has this concept for vehicle seats and timed actions.

3. **Fallback: movement lock + WASD:** At worst, freeze the character in place when the emulator tab is open (simulate sitting at the computer desk like sitting in a dead vehicle) and remap WASD as directional input for the emulator. This works even if we can't fully steal keyboard focus.

4. **ISPanel:setKeyboardFocus()** or similar — check if UI panels have a method to claim keyboard focus. If so, the emulator tab could grab focus when active and release it when closed.

### What the Fresh Instance Should Do
Look at how `ISTextEntryBox` steals keyboard focus from the game (verified to work — typing in chat doesn't move the character). Replicate that pattern for the emulator panel. Also check timed actions and vehicle seat states for movement locking.

## Potential Future Enhancements

- **fbSetPixelData(Texture, byte[])** — accept pixel data directly from Java without file I/O
- **Multiple framebuffers** — current implementation uses static state (one FB at a time). Could be refactored to support multiple independent framebuffers.
- **Different pixel formats** — currently RGBA only. Could add RGB, grayscale, indexed color.
- **Texture resize** — recreate GL texture at different dimensions without creating a new Lua Texture.
- **Double buffering** — write to back buffer while front buffer displays, swap on vsync.
