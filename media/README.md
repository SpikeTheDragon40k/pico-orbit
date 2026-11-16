# Orbit Rush promotional media

- `cartridge-label.png`: 512x512 nearest-neighbour preview of the original128x128 cover. This is promotional artwork, not a gameplay screenshot.
- `01-title.png`: actual PICO-8 title screen.
- `02-neon-grid.png`, `03-solar-core.png`, `04-void-nebula.png`, `05-ion-reactor.png`: actual gameplay screenshots, four participants. 512x512 captures; `*-native.png` retains128x128.
- `orbit-rush-gameplay.gif`:384x384,240 frames,7.2 seconds at the native recorder's33.3fps. Shows about8 seconds of30Hz simulated gameplay. GIF has no audio.
- `../release/orbit_rush.p8.png`: runnable cartridge with embedded cover, exported by official PICO-8.

## Provenance

Screenshots and GIF were produced by the installed official Lexaloffle PICO-8 runtime (`/home/spike/Downloads/pico-8/pico8`), through native EXTCMD screen/video capture. SDL software/off-screen mode was used. The real game update, physics, CPUs and drawing functions execute. A temporary capture harness selects arenas and supplies scripted left/right controls and occasional ability input for the bottom player; no simulated framebuffer or mocked drawing API is used. These are automated gameplay captures, not footage of a human playtest. Audio was not listened to or validated in this capture run.

The capture harness is not embedded in the distributed cartridge. PNG cartridge code and embedded label were decoded with shrinko8 and compared with the assembled source/label successfully. Release certification, manual input checks and CPU benchmarking are separate from media generation.

## Reproduce

```sh
# Optional cover regeneration (requires Pillow):
python3 tools/create_label.py
# Actual captures and official PNG cartridge export:
python3 tools/capture_media.py --pico8 /path/to/pico8
```

The capture process uses temporary runtime configuration, leaves normal PICO-8 user settings alone, and preserves the release game code. Screenshots/covers use the native16-colour palette and integer scaling.
