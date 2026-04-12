# Changelog

## 1.5.2 (2026-04-12)

- **Gamepad suppression** — PZ character no longer responds to captured gamepad input
  - Three-layer suppression: Lua `connected = false`, Java `setJoypadBind(-1)`, `JoypadState.controllerTest = true`
  - Per-frame enforcement in prerender prevents PZ's joypad re-activation from overriding suppression
  - All modes (EXCLUSIVE, SELECTIVE, FOCUS) correctly suppress; PASSIVE correctly does not
- **Key press consumption via `eatKeyPress`** — ALL captured keys now use `GameKeyboard.eatKeyPress(key)` to prevent any PZ release handling, including `Events.OnKeyPressed` and Java-level debug key handlers (e.g., F7 vehicle texture editor). Key releases detected via raw `Keyboard.isKeyDown` polling in prerender.
- **PlayStation controller position-based button remapping** — on PS controllers (DualSense, DualShock, etc.), A↔B and X↔Y are swapped in `_translateButton` so `onPZFBGamepadDown` delivers physical-position-correct button constants. Detection via PZ's `isPlaystationController()` plus name/GUID checks for DualSense.
- **Mouse no longer captured globally in toggle mode** — removed `setCapture(true)` from `_toggleCapture()`, allowing parent window UI (title bar, close button) to remain functional during exclusive capture
- **SELECTIVE mode gamepad enforcement** — per-frame controller suppression now includes SELECTIVE mode

## 1.5.1 (2026-04-12)

- **Gamepad auto-detection** — controllers are now automatically detected and assigned to input slots when `grabInput()` is called. Zero configuration required from mod authors.
  - Scans all 16 GLFW controller slots for connected devices
  - Seeds initial hardware state to prevent phantom button/axis events
  - Respects manually-assigned slots (`setSlotDevice`) and auto-assign slots (`setSlotAutoAssign`)
- **Hot-plug support** — controllers connected/disconnected mid-session are handled automatically via `Events.OnGamepadConnect` / `Events.OnGamepadDisconnect`
- **New public API: `getConnectedControllers()`** — returns `{id, name}` table for building controller selection UIs
- **Fix: `_slotForController` fallback** — no longer incorrectly returns keyboard slot (1) when no controller matches; returns nil
- **Fix: `saveInputConfig` no longer persists auto-detected slots** — only manually-assigned controller slots are saved

## 1.5.0 (2026-04-07)

- **`fbCopyFile(src, dst)`** — copy any file to any path, creating parent directories. Useful for deploying binaries from Workshop mods (which block `.exe` uploads — bundle as `.bin`/`.dat`, copy at runtime).
- **Game process API** — bidirectional process I/O for interactive applications (emulators, games)
  - `fbGameStart(binaryPath, width, height, extraArgs)` — launch a game binary with stdin/stdout I/O
  - `fbGameSendInput(keycode, pressed)` — send key events to the game via stdin
  - `fbGameIsRunning()` — check if game process is alive
  - `fbGameStatus()` — 0=idle, 1=starting, 2=running, 3=exited, 4=error
  - `fbGameError()` / `fbGameStop()` — error handling and cleanup
  - Reuses stream ring buffer — game stdout frames uploaded via `fbStreamFrame()`
  - **Wire protocol note:** `fbGameSendInput(keycode, pressed)` sends bytes in order `[pressed, keycode]` on the wire (pressed byte first, then keycode byte), despite the Lua parameter order being keycode first
- **Pressure-vessel fix** — `buildHostProcess` now passes absolute paths through unchanged (previously all paths were prefixed with `/run/host/usr/bin/`, breaking game binaries at absolute paths)
- **Stream/game mutual exclusion** — `fbStreamStart` now stops any running game process, and `fbGameStart` stops any running stream (shared ring buffer)
- Lua wrappers: `PZFB.gameStart()`, `gameSendInput()`, `gameIsRunning()`, `gameStatus()`, `gameError()`, `gameStop()`
- Class file count: 11 (was 10 in v1.3.0)

## 1.4.0 (2026-04-05)

- **Input system v2.0** — complete rewrite of `PZFBInput.lua`
  - Base class changed from ISPanel to ISPanelJoypad for full gamepad support
  - Four capture modes: EXCLUSIVE, SELECTIVE, PASSIVE, FOCUS
  - **Capture toggle key** — user-definable key to lock/unlock input to framebuffer panel
  - **Keyboard**: `onPZFBKeyDown`, `onPZFBKeyRepeat` (held keys), `onPZFBKeyUp` callbacks + polling
  - **Mouse**: click, release, move, wheel callbacks with panel-relative coordinates
  - **Gamepad**: button press/release, analog stick axes, trigger callbacks + polling
  - **Multi-controller input slots** — keyboard+mouse as slot 1, controllers as slot 2+
  - **Auto-assign** — controller auto-detection on button press
  - **Action mapping** — named actions with multiple bindings (keyboard + gamepad + analog axes)
  - **Selective capture** — consume keys by keycode or game binding name (follows user rebinds)
  - **Automatic cleanup** — input released on close, hide, remove, player death, or menu return
  - **Config persistence** — save/load action mappings and settings to `~/Zomboid/Lua/`
  - Modifier key polling (`isModifierDown("shift"/"ctrl"/"alt")`)
  - Configurable escape handling (close panel, release capture, or treat as regular key)

## 1.3.0 (2026-04-03)

- **Streaming video playback** — zero disk usage for video
  - `fbStreamStart(path, qualityScale, bufferFrames)` — quality as fraction of source resolution (0.0-1.0)
  - `fbStreamFrame/Seek/Stop` — ring buffer with correct slot mapping
  - Auto-detects source dimensions, FPS, duration via ffprobe
  - Configurable buffer size (default 120 frames)
  - Writer thread throttles to playback speed (waits when buffer full)
  - Separate stderr handling — binary stdout stays clean for raw RGBA data
- **Streaming audio** — near-instant start (~2 sec), no OGG encoding
  - ffmpeg decodes audio to raw PCM, Java writes WAV with streaming header
  - FMOD loads with CREATESTREAM + ACCURATETIME for stream seeking
  - `fbAudioPlayFrom(posMs)` — reliable seek via stop/play-paused/seek/unpause
  - `fbStreamAudioDone()` — signals when WAV extraction is complete
  - Audio auto-reloads after extraction completes for full-duration seek support
  - Temp WAV auto-deleted on stop
- **Pressure-vessel container support** (Steam Linux Runtime)
  - Uses host's ld-linux with LD_LIBRARY_PATH from host's ld.so.conf
  - Reads host's /etc/ld.so.conf + includes for complete library path discovery
  - Clears JVM's LD_PRELOAD for child processes
  - Separate stderr handling for binary vs text process output
- `fbFFmpegDiag()` / `fbAudioSeekDiag()` — troubleshooting helpers
- Lua API wrappers for all stream methods
- Class file count: 10 (was 6 in v1.2.0)

## 1.2.0 (2026-04-03)

- **Audio playback via FMOD direct** — bypasses PZ's sound bank system entirely
  - `fbAudioLoad(path)` — load any audio file from any absolute path (OGG, WAV, MP3, etc.)
  - `fbAudioPlay()` / `fbAudioStop()` — start/stop playback
  - `fbAudioPause()` / `fbAudioResume()` — true pause/resume (freezes position)
  - `fbAudioSeek(posMs)` — seek to position in milliseconds
  - `fbAudioGetPosition()` / `fbAudioGetLength()` — query playback state
  - `fbAudioSetVolume(vol)` — volume control (0.0–1.0)
  - `fbAudioIsPlaying()` — check if audio is playing
- **Video conversion via ffmpeg** — runs ffmpeg in a background thread via ProcessBuilder
  - `fbConvertStart(input, outputDir, w, h)` — start async conversion
  - `fbConvertStatus()` — poll: 0=idle, 1=running, 2=done, 3=error
  - `fbConvertError()` / `fbConvertReset()` — error handling
  - `fbFFmpegAvailable()` — detect if ffmpeg is on PATH
- **Utility methods**
  - `fbListDir(path)` — list files in a directory (newline-separated)
  - `fbReadTextFile(path)` — read a small text file from any absolute path
- **Test script:** `PZFB.TEST_DISABLED` flag allows dependent mods to reclaim test keybindings. Test keys remapped from INSERT/END to HOME/END.
- Lua API wrappers for all new methods added to PZFBApi.lua
- Class file count: 6 (was 5 in v1.1.0)

## 1.1.0 (2026-04-03)

- Added `fbLoadRawFrame(tex, path, frameIndex)` — load a single frame from a concatenated raw RGBA file (for video playback, animations, etc.)
- Added `fbFileSize(path)` — get file size in bytes from Lua (needed to calculate total frame count since Lua sandbox has no io.*)
- Lua API wrappers: `PZFB.loadRawFrame()` and `PZFB.fileSize()`
- Class file count: 5 (was 4 in v1.0.0)

## 1.0.0 (2026-04-03)

Initial release.

- Multi-framebuffer support (create unlimited independent framebuffers)
- Thread-safe pixel updates (copy-on-queue, no shared buffer races)
- No reflection required (uses PZ's own GL texture allocation)
- Clean Lua API (`PZFB` module) with wrapper table handles
- Input capture module (`PZFBInputPanel`) for stealing keyboard from game
- NEAREST filtering by default (pixel-perfect for emulators)
- Optional LINEAR filtering for video playback (`PZFB.createLinear()`)
- Cross-platform install scripts (Linux + Windows)
- Deployment detection with user-friendly error UI on game start
- Resource cleanup via `PZFB.destroy()`
