# Validation results

These checks execute the actual modular game source or the Lua section extracted from the generated standalone cartridge. The desktop harness supplies PICO-8 APIs, turn-based trigonometry and deterministic seeded random input. It uses Lua 5.5 floating-point numbers: it is **not** a PICO-8 emulator and does not validate fixed-point rounding, rendering quality, audio playback or CPU/RAM limits.

## Executed checks

- `python3 tools/build.py`: generated the standalone cartridge with 21,605 Lua characters; cartridge SHA256 `7040c31f888c74793f1de630efeeb258c018fada59800aac6ad467a202bda77a`.
- `lua tests/run.lua --cart`: **21 groups and 389,418 assertions passed**, including 96 seeded full matches, against that generated cartridge.
- This final run includes the bounded global AI budget, adaptive prediction samples, equal top-speed human movement, corrected spin orientation, signed-angle normalization and bounded timer corrections.
- `--quick` skips only the full tournament and CSV write, allowing focused regressions without replacing the balance sample.


Coverage includes all 48 combinations of opponent count, difficulty and arena; all 15 nonempty survivor masks in all four arenas; inactive-side walls; movement bounds; finite coordinates and speed caps; DASH/GRAB cooldowns; offset throws and timeout release; deflection and spin; obstacle collisions and corner chamfers; shield consumption; power-up durations and multiball caps; extra-ball and round progression; every seat winning a match; rematch reset; deterministic replay; leading trajectory prediction and prediction-state isolation. Rendering paths execute with drawing stubs, which is a code-path check only.

## Deterministic gameplay sample

Two seeds per configuration, five starting points, first to one round, power-ups and timed extra balls enabled. The bottom human seat is driven by a deliberately simple keyboard bot that follows the nearest ball's current coordinate; it does not use abilities. CPU seats use cartridge AI. Durations are simulated game time, not benchmark execution time. These results measure this particular opponent, not human difficulty or fairness.

| Difficulty | Bottom agent wins / games | Win rate | Mean match time |
| --- | ---: | ---: | ---: |
| Easy | 23 / 24 | 95.8% | 89.97 s |
| Normal | 20 / 24 | 83.3% | 113.47 s |
| Hard | 16 / 24 | 66.7% | 118.54 s |
| Insane | 13 / 24 | 54.2% | 112.20 s |

Full per-configuration results are in `tests/tournament-results.csv`. These samples demonstrate a large gap between Easy and the higher settings, but do not establish strict difficulty ordering. The sample is small, the simple bottom bot is unusually fast and ability-free, and multi-opponent targeting affects outcomes. Human playtesting and a broader balance sample remain necessary.

## Unverified release requirements

No graphical PICO-8 playtest was performed. Official runtime launch, game feel, controller mapping, builtin pause/resume, readable presentation at native resolution, audio mixing, CPU profiling and fixed-point edge cases require an official PICO-8 installation. Static parser/token/compressed-size validation is recorded separately by the validator; desktop source tests cannot establish cartridge hardware compliance. Android/JVM tests were not run, and no source-engine behavioral equivalence is claimed.

## Static cartridge budget

`python3 tools/validate.py --shrinko8 /tmp/orbit-shrinko8/shrinko8.py --require-budget` passed against the final tested cartridge. Pinned shrinko8 revision: `d26c7d0abd6561b998ed6f530fed0ed3bc2216c9`. PICO-specific parse/lint passed. Counts: **6147 tokens**, **21604 source characters**, **7568 compressed code bytes**. Token ceiling8192; source ceiling65535; project compressed gate15360 (tool reports15616). This is a console-specific compatible measurement, not official-runtime certification. See resource-report.txt.

`lua tools/profile_prediction.lua` also executed: sampled peak desktop VM instruction counts for1..5 balls were17k/35k/44k/44k/45k. These are diagnostic counts, not PICO-8 CPU percentages, and exclude native API/render work.

## Creator playtest update

The creator reports that the current game "plays perfectly." This is user-reported runtime success, not an assistant-run graphical test. Runtime version, configuration coverage, CPU readings, controller/audio checks and final PNG export verification remain to be recorded. See docs/release-guide.md for the final publishing workflow.

## Official-runtime media capture

The installed runtime was subsequently found at `/home/spike/Downloads/pico-8/pico8`. It successfully rendered the title and all four gameplay arenas using native headless/off-screen capture. Its native GIF recorder produced240 gameplay frames (384x384,7.2-second GIF). Scripted input drives the human seat during these captures. This verifies these rendering/gameplay paths in the official runtime, but is not a human/controller/audio playtest or a comprehensive fixed-point/performance certification.

The official runtime exported `release/orbit_rush.p8.png`. Decoding it with shrinko8 verified its Lua and label exactly match the assembled cartridge. The new source cover is preserved across builds. PICO-specific lint/budget checks passed unchanged at6147 tokens/7568 compressed bytes, and the focused assembled-cart suite passed20 groups/389 assertions after the asset/pipeline changes. Gameplay Lua was not changed.
