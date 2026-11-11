# Orbit Rush — PICO-8 Edition

A standalone single-player demake of [Orbit Rush](https://github.com/SpikeTheDragon40k/orbit-rush), created by SpikeTheDragon40k. Guard the bottom goal against 1–3 CPUs. Curve shots with paddle movement, lunge with DASH, and catch/aim/throw with GRAB. Lose all your points and your goal becomes a wall; the last pilot standing wins the round.

The cartridge implements all four arenas, four difficulties, cosmetic pilot selection, point and round presets, four pickups, five-ball support, menus, results, original chip audio and match music. **Release validation is incomplete:** no official PICO-8 runtime was available, so graphics, sound, fixed-point behavior and CPU performance have not been verified in the console. See [test results](docs/test-results.md) and [progress](docs/progress.md).

## Play

Install a licensed Linux build of [official PICO-8](https://www.lexaloffle.com/pico-8.php), then run from this directory:

```sh
pico8 -run carts/orbit_rush.p8
```

You can also drag `carts/orbit_rush.p8` into PICO-8 and type `run`. The cartridge needs no source files, network connection, Android app or desktop runtime after loading.

| Action | PICO-8 input | Default keyboard |
|---|---|---|
| Move bottom paddle | Left / right, buttons 0 / 1 | Arrow keys |
| DASH | O, button 4 | Z, N or C |
| GRAB / THROW | X, button 5 | X, M or V |
| Pause / resume | Console pause menu | Enter / P |
| Configure | Up/down select; left/right change | Arrow keys |
| Launch | O / X on launch row | Z / X |

Only controller zero is read. Controllers use PICO-8's own mapping. In the pause menu you can toggle music/effects, return to setup, or enable a CPU/memory diagnostic overlay. Keyboard and pause behavior follow the [official manual](https://www.lexaloffle.com/dl/docs/pico-8_manual.html).

DASH lunges forward and boosts impacts; recharge is 2.2 seconds. GRAB arms a 0.9-second catch window. A caught ball follows your paddle for up to 1.2 seconds. Press X again to throw; catch offset and paddle motion aim the shot. GRAB recharges in 4 seconds. Normal movement changes shot spin. Catching does not stop other balls.

Choose 5/10/15/20/25 starting points (default 15), first to 1/2/3/5 round wins (default 3), arena, difficulty and CPU count. The human always sits bottom; CPUs occupy top, left, then right. Empty/eliminated sides are walls. If eliminated early, you spectate until the remaining CPUs finish; the pause menu can return to setup.

A ball collects pickups for its last hitter: S blocks one goal shot for up to 12s; T slows incoming balls in your zone for 6s; M adds a ball; W widens your paddle for 10s. At most five balls/two pickups exist. Enabled timed progression adds a persistent ball each minute, up to three additions. Round 3 starts with two balls and round 5 with three, independently of timed progression.

## Build and validate on Linux

Requires Python 3 and Lua 5.3+ for tests. The game uses native PICO-8 Lua; desktop-only tests supply missing console APIs.

```sh
python3 tools/build.py
python3 tools/validate.py
lua tests/run.lua --cart
```

The builder assembles ordered modules and generates native SFX/music; it is deterministic and needs no downloaded dependencies. `--cart` executes the actual assembled Lua section in a desktop shim. `--quick` skips the tournament. Plain structural validation explicitly reports missing budget validation.

For PICO-specific syntax, lint, tokens and compressed-size checks, install the pinned third-party [shrinko8](https://github.com/thisismypassport/shrinko8) tool outside the project:

```sh
git clone https://github.com/thisismypassport/shrinko8.git /tmp/orbit-shrinko8
git -C /tmp/orbit-shrinko8 checkout d26c7d0abd6561b998ed6f530fed0ed3bc2216c9
python3 tools/validate.py --shrinko8 /tmp/orbit-shrinko8/shrinko8.py --require-budget
```

This reports console-specific counts; source characters are never used as a token estimate. The tool is not an official runtime and does not validate frame rate. Re-running the full suite writes `tests/tournament-results.csv`. Original Kotlin source was inspected in a separate `/tmp` clone and was not modified or copied as a runtime dependency.

## Project guide

- `src/`: arena geometry, physics, abilities, AI, rules, rendering, entrypoint.
- `carts/orbit_rush.p8`: assembled standalone cartridge.
- `tools/`: reproducible builder and validation.
- `tests/`: headless API shim, regression tests, seeded tournaments.
- `docs/original-game-analysis.md`: source audit and preservation matrix.
- `docs/demake-design.md`, `docs/porting-decisions.md`: design and explicit deviations.
- `docs/test-results.md`, `docs/progress.md`: evidence and remaining release gates.

Original names, pilot designs and game concept: SpikeTheDragon40k. PICO-8 reinterpretations use original primitive art and generated sequencer audio; no WebP or MP3 conversion is embedded. No third-party game assets are included.
