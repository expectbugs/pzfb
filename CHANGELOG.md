# Changelog

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
