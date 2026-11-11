# Porting decisions and feasibility

The demake is feasible because the source's core is a bounded 2D simulation with simple collision primitives. The difficult work is preserving behavior within CPU/token limits and making four-sided survival readable at 128×128. This is an adaptation, not a Kotlin engine translation.

## Architecture

Keep development sources modular: arena data/helpers, physics, players/abilities, AI, game/rules, rendering and entrypoint/menu input. The release build concatenates those modules in a fixed order into `__lua__`, followed by generated native audio/asset sections. Ship a standalone cartridge without `#include` directives. Includes are convenient during editing but are filesystem-dependent at load/export time; assembly gives a reviewable release artifact with all dependencies present.

The original clone lives outside the demake and is read only. The cartridge contains no JVM, Compose, Android, networking or server code. Build tooling is desktop-only; the assembled game is offline and self-contained.

## Numerical model and collision approximations

Original world coordinates are divided by ten, giving a 100-unit square. Speeds are stored per 30Hz frame: original base 640u/s becomes approximately 2.133 units/frame, target cap 1500 becomes 5, hard cap 2000 becomes approximately 6.6. Ball radius becomes 1.6; paddle half-length 7.5 and inset 4.6. World-size scaling preserves obstacle placement and relative silhouettes.

Ten shared physics substeps give at most .66 units of individual travel at the cap, approximately .413 ball radii per check. Unlike an unbounded collision solver, cost stays bounded with five balls. The AI predictor divides each difficulty horizon into at most 24 coarse samples per ball, sharing at most 60 samples across the current ball set in a decision. Only one CPU decision batch runs per update; others retain cached targets. Sample spacing grows with ball count and difficulty horizon, so the predictor can miss small bumpers or estimate contact late. Live physics retains all ten collision substeps. This is an intentional accuracy reduction, not a reduction in gameplay collision quality. No simulation-time accumulator is needed inside native `_update()`; PICO-8 provides the fixed update cadence. Display interpolation and the source's 120Hz integrator are omitted.

Static side/chamfer collisions use inward constraints and circle bumper separation. Paddles use a simplified incoming front-face interception region, retaining offset deflection without the original full capsule tip and moving-normal collision calculation. Thus tip grazes and dash-versus-ball contact differ from the Android engine. Front-face returns preserve the 65% aiming/35% reflection blend and 4% acceleration; dash retains the 1.45× boost.

Spin is stored in frame-scaled units. Paddle movement transfers bounded spin directly rather than reproducing the complete moving-disc friction calculation; walls and bumpers still use tangential slip. Magnus curvature renormalizes speed. Exponential spin/overspeed decay is replaced with fixed-step linear factors. Slow-Mo halves incoming local ball movement/forces; timers remain in game frames. These choices aim to retain curve-shot behavior, not bit-exact trajectories.

GRAB is a 27-frame catch window, 36-frame maximum hold, 120-frame cooldown; DASH cooldown is 66 frames and its lunge approximately 6.6 frames. Catching stores offset; O and X are independent, and X while holding throws regardless of catch cooldown. Release preserves offset plus motion aiming and the 1.6× launch. Frame quantization makes boundary timings approximate.

## AI simplification

Reaction frames are nominally 10/7/4/3 with ±25% jitter, compared with upstream .34/.22/.13/.075 seconds. Nominal lookahead is 24/36/48/60 frames and bounce allowances 0/1/2/4. Tracking noise is bounded uniform noise rather than Gaussian, scaled by intercept time. Easy/Normal ignore spin, Hard/Insane model it. Cached paddle targets avoid following the ball every render frame. A shared scheduler permits at most one CPU trajectory-decision batch per frame; simultaneous due decisions defer while movement and held-ball actions continue. Each batch considers all free balls.

Movement factors remain .50/.68/.85/1.00. The keyboard player's maximum is deliberately reduced from the source's extreme absolute-touch following speed to the cartridge's common movement budget; CPUs receive only documented lower difficulty factors. Aimed returns approximate target-to-offset inversion rather than exactly solving the blended contact model. Victim choice biases toward exposed/weak opponents without the original per-difficulty full target-selection table. No-threat positioning returns to center. GRAB holds use a bounded delay rather than the source's randomized .25–.70 seconds. Ability functions, cooldowns and collision rules are shared.

These are documented reductions in tactical depth. Difficulty ordering and fairness still require measured tournaments and human playtesting.

## Other deviations

- Single-player is mandatory. Remove all local-human, Wi-Fi, online, account and lobby flows, all network snapshots/late saves and Android-only input paths.
- Preserve point presets and finite match lengths; omit endless configuration.
- Safe serves use a simple arena-safe origin rather than the original randomized origin selection and near-ball spacing. Solar uses a safe diagonal origin. Pickup Multi-Ball uses a safe serve origin rather than the pickup location, reducing bumper-overlap risk.
- Pickups use uniform type choice rather than source weights 3/3/2/2 and bounded placement attempts. Maximum two orbs and five balls remain. A capped Multi-Ball may have no extra-ball effect; no invalid ball is created.
- Wide applies its length change immediately instead of interpolating. Shield remains single-impact or timeout; Slow-Mo remains personal to incoming balls.
- Round-three/five base multi-ball progression remains part of match pacing; the timed-addition setting controls the separate once-per-minute rule.
- Pilot selection is a cosmetic extension explicitly requested for the demake. The original engine assigns profiles by seat.
- Rebuild all visuals in native colors/primitives; do not embed WebP machinery textures. Compose glow, touch prompts, haptics and complex nameplates do not transfer directly.
- Compose original PICO-8 sequencer music/effects rather than converting the supplied MP3. Separate music/effect switches fit; runtime master volume remains the console's responsibility.

## Resource budget and measurement policy

These are engineering targets, not measured results. Actual counts belong in `docs/test-results.md` / `docs/progress.md` after commands run.

| Resource | Hard console constraint | Project target / approach |
|---|---|---|
| Display | 128×128, native 16 colors | 100-unit playfield plus compact margins |
| Lua tokens | 8192 PICO-8 tokens | Prefer at most 7500, measured by official or trustworthy PICO-specific tokenizer |
| Lua source | 65535 characters | Keep assembled source below limit; measure independently of tokens |
| Compressed code | 15360-byte conservative export threshold (shrinko8 reports 15616) | Measure with compatible compressor / official export; plain-text `.p8` size is not this measurement |
| Audio | Four channels; 64 SFX; 64 patterns | Music uses two channels; effects reserve a separate channel |
| Sprites/map | Native shared cartridge storage | Primitive rendering can leave most storage unused |
| Runtime CPU | PICO-8 update/draw budget | 30Hz baseline; measure `stat(1)` and peak crowded frames in official runtime |
| Runtime memory | Console fixed memory / Lua budget | At most four players, five balls, two pickups and short trails; inspect runtime memory stats |

Never substitute generic Lua token counts, bytes or character counts for PICO-8 token usage. Native desktop Lua has different arithmetic and no graphics/audio timing; headless checks can find state/logic defects but cannot certify official fixed-point behavior, frame rate or controls. The official PICO-8 runtime was not found during environment inspection; a user-installed licensed copy is needed for final load/play/profile verification.

## Risks and roadmap

1. **High:** official runtime unavailable. Continue headless/static validation; leave graphical, audio and CPU gates explicitly open.
2. **High:** expensive AI × up to five balls × three CPUs. Keep horizons/decisions bounded, stagger decisions, profile worst-case before release.
3. **High:** PICO-8 fixed-point overflow and long-running counters. Keep vector magnitudes small and long-lived counters bounded; test long rounds and saturation boundaries.
4. **High:** collision differences around paddle tips, dash sweeps and elimination mouths. Exercise high-speed approaches and every survivor combination.
5. **Medium:** crowded UI and human feel. Require actual keyboard/controller playtesting and inspect all four arenas.

Milestones: source audit → minimal complete round/build pipeline → all seating/arenas/abilities/match flow → spin/pickups/multi-ball/pilots → coherent rendering/audio → regression tournaments/resource measurements → official runtime playtest and distribution. A phase is not complete merely because its functions exist. Every milestone review should record evidence-based scores, five largest weaknesses, implemented fixes and rerun validations; stop improvement iterations after three or when no meaningful issues remain.
