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
├── docs/
│   └── TECHNICAL.md       # Complete technical documentation (READ THIS FIRST)
├── java/
│   └── zombie/core/
│       └── Color.java     # Patched Color class source
├── mod/                   # PZ mod (Lua side)
│   └── PZFB/
│       ├── 42/
│       │   ├── mod.info
│       │   └── media/lua/client/
│       └── common/
└── tools/                 # Build scripts, test utilities
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
8. **Anonymous inner classes** compile to `Color$1.class`, `Color$2.class`, etc. ALL must be deployed.
9. **Reflection works** — we use it to set private `TextureID` fields (id, width, height, widthHw, heightHw).
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

## Lua API (Current)

```lua
Color.fbPing()                        -- Returns string, verifies patch loaded
Color.fbCreate(width, height)         -- Returns Texture, queues GL init
Color.fbIsReady()                     -- Returns boolean, true when GL init done
Color.fbFill(tex, r, g, b, a)        -- Fills solid color (0-255 each)
Color.fbLoadRaw(tex, path)            -- Loads raw RGBA file, returns boolean
-- Draw in UI panel render():
self:drawTextureScaled(tex, x, y, w, h, 1, 1, 1, 1)
```

## B42 PZ Lua Sandbox Limitations

- **No `io.*` or `os.*` modules.** Lua is sandboxed.
- **No `next()`, `rawget(table, number)`, `string.byte()`, `math.huge`** — Kahlua VM limitations.
- **No `string.format(%g)`, `string.gsub(str, pat, TABLE)`** — Kahlua limitations.
- **File I/O:** `getFileWriter(filename, createIfNull, append)` and `getFileReader(filename, createIfNull)` write to `~/Zomboid/Lua/`.
- **Events (verified names):** `Events.EveryOneMinute`, `Events.EveryTenMinutes`, `Events.OnGameStart`, `Events.OnTick`, `Events.OnKeyPressed`
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
