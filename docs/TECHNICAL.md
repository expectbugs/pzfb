# PZFB — Project Zomboid FrameBuffer: Technical Documentation

## What This Is

A system for rendering arbitrary pixel data inside Project Zomboid's UI. This enables emulators, video playback, dynamic graphical content, and anything else that produces a framebuffer — all rendered at GPU speed inside PZ's own UI panels.

## How It Works

### The Core Problem

PZ's Lua VM (Kahlua) can create Texture objects and draw them, but cannot write pixel data to them. The `Texture.setData(ByteBuffer)` method exists but calls `glTexSubImage2D` directly — and PZ's Lua runs on the MainThread which does NOT have the OpenGL context. The GL context lives on a separate render thread. Any direct GL call from Lua/Kahlua crashes the JVM with "No context is current."

### The Solution

We replace `zombie.core.Color` (a whitelisted Java class exposed to Kahlua) with a patched version that adds static methods for framebuffer operations. These methods use `RenderThread.queueInvokeOnRenderContext(Runnable)` to dispatch all OpenGL calls to the correct thread.

### The Pipeline (v1.0)

```
1. Lua calls Color.fbCreate(width, height)
   → Java creates Texture(width, height, 3) — PZ allocates GL texture on render thread
   → Texture is registered in ConcurrentHashMap for tracking
   → Returns Texture to Lua immediately (GL init is async)

2. Lua polls Color.fbIsReady(texture)
   → Checks TextureID.getID() != -1 (render thread has allocated the GL texture)
   → No reflection needed — getID() is public

3. Lua calls Color.fbFill(texture, r, g, b, a) — OR — Color.fbLoadRaw(texture, path)
   → Java allocates a FRESH ByteBuffer (copy-on-queue, thread-safe)
   → Fills buffer with pixel data (solid color or from file)
   → Reads GL id via texture.getTextureId().getID()
   → Queues glBindTexture + glTexSubImage2D on render thread

4. Lua draws in a UI panel's render() method:
   → self:drawTextureScaled(texture, x, y, w, h, 1, 1, 1, 1)
   → PZ queues this through its SpriteRenderer
   → Render thread draws the texture
```

### Key improvements over PoC
- **No reflection** — uses TextureID.getID() (public method) instead of reflective field access
- **No GL leak** — uses PZ's own GL texture instead of creating a second one via glGenTextures
- **Multi-framebuffer** — ConcurrentHashMap tracks per-texture state, not static globals
- **Thread-safe** — fresh ByteBuffer per update prevents race between MainThread writes and RenderThread reads
- **NEAREST by default** — flags=3 on Texture constructor for pixel-perfect rendering

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

### Low-level Java API (Color.fb* methods):

```lua
Color.fbPing()                              -- Returns "PZFB 1.0.0"
Color.fbVersion()                           -- Returns "1.0.0"
Color.fbCreate(width, height)               -- Returns Texture (NEAREST filtering)
Color.fbCreateLinear(width, height)         -- Returns Texture (LINEAR filtering)
Color.fbIsReady(tex)                        -- Returns boolean (per-texture)
Color.fbFill(tex, r, g, b, a)              -- Fills solid color (0-255 each)
Color.fbLoadRaw(tex, path)                  -- Loads raw RGBA file, returns boolean
Color.fbLoadRawFrame(tex, path, frameIndex)  -- Loads frame from concatenated raw file
Color.fbFileSize(path)                       -- Returns file size in bytes, or -1
Color.fbDestroy(tex)                         -- Frees GL resources
```

### High-level Lua API (recommended — see docs/API_REFERENCE.md):

```lua
require "PZFB/PZFBApi"
PZFB.isAvailable()                          -- Check if class files deployed
PZFB.create(width, height)                  -- Returns fb handle table
PZFB.createLinear(width, height)            -- Returns fb handle (LINEAR)
PZFB.isReady(fb)                            -- Check GL readiness
PZFB.fill(fb, r, g, b, a)                  -- Fill solid color
PZFB.loadRaw(fb, path)                      -- Load raw RGBA file
PZFB.loadRawFrame(fb, path, frameIndex)      -- Load frame from concatenated raw file
PZFB.fileSize(path)                          -- Get file size in bytes
PZFB.getTexture(fb)                          -- Get Texture for drawing
PZFB.destroy(fb)                             -- Clean up
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

## Verified Working

### PoC (2026-04-03, single-buffer version)
- [x] `Color.fbPing()` — custom Java code executes from Lua
- [x] `Color.fbCreate(64, 64)` — creates texture, returns to Lua, no crash
- [x] `Color.fbIsReady()` — returns true after GL init completes
- [x] `Color.fbFill(tex, 255, 0, 0, 255)` — solid red fill, visible on screen
- [x] `Color.fbLoadRaw(tex, path)` — loads gradient from raw file, visible on screen
- [x] `drawTextureScaled()` — renders at any size in UI panel
- [x] Multiple updates (fill red, then load gradient, then fill red again)
- [x] No crashes across all tests
- [x] Game functions normally with patched Color class

### v1.0.0 (2026-04-03, multi-buffer refactor)
- [x] Compiles clean with Java 25, no warnings
- [x] No reflection used — TextureID.getID() is public
- [x] No manual glGenTextures — PZ's own Texture constructor handles GL allocation
- [x] ConcurrentHashMap for multi-framebuffer state
- [x] Fresh ByteBuffer per update (copy-on-queue thread safety)
- [x] Two independent framebuffers created and displayed simultaneously
- [x] fbFill: independent colors (red + blue) on separate framebuffers
- [x] fbLoadRaw: gradient loaded into one FB without affecting the other
- [x] fbDestroy: both framebuffers destroyed cleanly, no crash
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
For a proper Steam Workshop release, the mod needs to work without manual file copying.

### Possible Solutions to Investigate
1. **Lua-side auto-deploy:** On game start, a Lua script copies the .class files from the mod's media directory to the PZ install directory. Would require a game restart to take effect (classes loaded at JVM startup). Could detect if deployment is needed and prompt the user.

2. **PZ's `-classpath` or `-cp` manipulation:** The native launcher (`ProjectZomboid64`) reads `ProjectZomboid64.json` for classpath. If mod directories could be added to this JSON, or if there's an environment variable override, class files could stay in the mod directory.

3. **Java agent / instrumentation:** A Java agent can modify classes at load time. If PZ supports `-javaagent` JVM args, an agent could intercept Color class loading and inject our methods without replacing the file on disk.

4. **Custom classloader hook:** If PZ's code has any mod-loading hook that touches the classloader, we could exploit it to add our mod directory to the class search path.

5. **Self-extracting on first run:** The Lua mod detects the classes aren't deployed, extracts them from a bundled location (e.g., base64-encoded in a Lua string or as a binary file in media/), writes them to the PZ install dir, and prompts for restart. Ugly but functional.

The fresh instance should investigate these approaches. The TrueVideo author's approach is the strongest lead — if he claimed Workshop-only distribution, one of these methods works.

## Input Capture System (v2.0 — Solved)

### How PZ Keyboard Input Actually Works (Verified from Java Decompile)

The full pipeline, decompiled from `GameKeyboard.java` and `UIElement.java`:

```
KEY DOWN → GameKeyboard.update() → UIManager.onKeyPress(n)
  → iterates UI stack TOP-DOWN (last added = highest priority)
  → for each visible element with wantKeyEvents=true:
    → Java calls Lua onKeyPress(key)     [ALWAYS runs]
    → Java calls Lua isKeyConsumed(key)  [if true → consumed, stop walk]
  → if NOT consumed AND doLuaKeyPressed:
    → triggers Events.OnKeyStartPressed(key)
  → always: Events.OnCustomUIKeyPressed(key)

KEY HELD → UIManager.onKeyRepeat(n)  [same walk with onKeyRepeat]
KEY UP   → UIManager.onKeyRelease(n) [same walk with onKeyRelease]
  → if NOT consumed: Events.OnKeyPressed(key)  [NOTE: RELEASE triggers OnKeyPressed!]
```

Key insight: `onKeyPress(key)` runs BEFORE `isKeyConsumed(key)`. The handler always fires — consumption only controls whether the event propagates further.

### The Solution: PZFBInputPanel (ISPanelJoypad subclass)

`PZFBInput.lua` provides `PZFBInputPanel`, which uses three verified PZ mechanisms:

1. **`setWantKeyEvents(true)`** — opt into the UIManager key dispatch walk
2. **`isKeyConsumed(key)` returning true** — prevents key from reaching game bindings and lower UI elements
3. **`GameKeyboard.eatKeyPress(key)`** — belt-and-suspenders: sets per-key flag that suppresses the next release event entirely

For gamepad: raw polling via `isJoypadPressed(cid, n)`, `isJoypadUp/Down/Left/Right(cid)`, and `getJoypadMovementAxisX/Y(cid)` provides frame-accurate input. `setJoypadFocus(playerNum, self)` is used as a best-effort for PZ-routed events but is **not required** — raw polling works independently of PZ's joypad focus system.

**Controller auto-detection:** When `grabInput()` is called, all 16 GLFW controller slots are scanned via `isJoypadConnected(cid)`. Connected controllers are assigned to input slots (starting at slot 2) and immediately available for polling. Initial hardware state is seeded into each slot to prevent false press/axis events on the first polling frame. Hot-plug is supported via `Events.OnGamepadConnect` / `Events.OnGamepadDisconnect` listeners. Auto-detected slots are marked with `_autoDetected = true` and excluded from config persistence to avoid stale entries.

For mouse: ISPanelJoypad's `onMouseDown/Up/Move/Wheel` handlers are overridden. `setCapture(true)` grabs mouse events even when cursor leaves the panel. `setWantExtraMouseEvents(true)` enables middle button and beyond.

### Known PZ Limitations (Verified)
- **`onMouseButtonUp` (inside panel) does not exist** — only `onMouseButtonUpOutside`. Extra mouse button (2+) releases are detected via raw `Mouse.isButtonDown(btn)` polling in prerender as a fallback.
- **`Events.OnKeyPressed` fires on key RELEASE**, not press. `OnKeyStartPressed` is the actual press event.
- **Two keyboards/mice on one machine are not distinguishable** — GLFW/LWJGL sees one keyboard state globally. Multiple controllers + keyboard is the realistic co-op path.

## Potential Future Enhancements

- **fbSetPixelData(Texture, byte[])** — accept pixel data directly from Java without file I/O
- **Multiple framebuffers** — current implementation uses static state (one FB at a time). Could be refactored to support multiple independent framebuffers.
- **Different pixel formats** — currently RGBA only. Could add RGB, grayscale, indexed color.
- **Texture resize** — recreate GL texture at different dimensions without creating a new Lua Texture.
- **Double buffering** — write to back buffer while front buffer displays, swap on vsync.
