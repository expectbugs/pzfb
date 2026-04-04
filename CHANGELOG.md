# Changelog

## 1.3.0 (2026-04-03)

- **Streaming video playback** — zero disk usage for video
  - `fbStreamStart/Frame/Seek/Stop` — ffmpeg pipes raw frames to in-memory ring buffer
  - Auto-detects source dimensions, FPS, duration via ffprobe
  - Aspect-ratio-correct scaling (target width, height computed from source)
  - ~42-56MB RAM for 300-frame video ring buffer
- **Streaming audio** — near-instant start (~2 sec), no OGG encoding
  - ffmpeg decodes audio to raw PCM, Java writes WAV with streaming header
  - FMOD loads growing WAV file with CREATESTREAM
  - Full seek support via FMOD (random access within WAV)
  - Temp WAV (~486MB for 44 min) auto-deleted on stop
- **Pressure-vessel container support** (Steam Linux Runtime)
  - Uses host's ld-linux with LD_LIBRARY_PATH from host's ld.so.conf
  - Clears JVM's LD_PRELOAD for child processes
  - Reads host's /etc/ld.so.conf for complete library path discovery
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
