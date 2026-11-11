# Progress — implementation candidate 0.1.0

Current milestone: all requested core systems implemented; desktop regression, cartridge-format and PICO-specific static budget checks complete. Official-console release qualification remains open. This is a playable implementation candidate, not a manually playtested final release.

## Completed

- Original repository cloned separately and audited at `67acff0600263f813122d6993b51897fe687d77e`; mandatory source files, documentation, renderer, entities/input and pilot art inspected. Original project untouched.
- Reproducible dependency-free modular build into a standalone `.p8`; generated original native audio.
- One human bottom paddle, selectable 1/2/3 CPUs and all four arenas. Inactive and eliminated goals close.
- Four predictive CPU difficulties, delayed/cached decisions, bounded error, target selection and shared abilities. One decision batch/frame; at most 60 world samples per batch.
- Ramping speed, wall/bumper reflection, corner chamfers, angled paddle shots, spin/curve, DASH, GRAB/THROW, ball pairs and stall guards.
- Points/elimination, round wins, finite matches, configurable rules, restart/rematch/spectating, pilot selection and setup.
- Shield, personal Slow-Mo, Multi-Ball, Wide; extra-ball progression and round-three/five base multiball.
- Native palette/primitives, four portraits/themes, trails, HUD, goal feedback, original SFX and looping music. Console pause settings and CPU/memory diagnostic overlay.

## Phase reviews and implemented improvements

Research: documented the exact source implementation and a feature preservation matrix; explicitly excluded all networking. Architecture uses native per-frame velocities to reduce fixed-point ranges; cartridge assembly embeds code/audio rather than shipping includes.

Core-loop review: headless tests verified complete matches, all survivor combinations and fast shots. Improvements corrected PICO sine direction for DASH, prevented scored balls participating in pair collisions, normalized signed shot angles, and stopped further goals once a round ends. Tests then passed again.

Complete-game review: tests exposed uneven difficulty; signed aiming correction improved ordering. Independent code review found human follow gain reduced actual speed below Insane; corrected movement to share the same maximum. AI movement remains difficulty-scaled downward. Corrected top/right moving-paddle spin orientation. Long-lived age/stall/round/clock counters are bounded.

Performance/polish review: diagnostic Lua instruction counts exposed expensive multi-ball predictions. Limited one CPU decision batch/frame and adapted per-ball prediction samples to a global ceiling of 60 per batch. Worst sampled five-ball diagnostic decreased to approximately 45k desktop Lua instructions (not PICO-8 cycles or a frame-time measurement). Final tests reran against the assembled cart after these changes. Added pause profiling and music/effect toggles, then revalidated budgets.

## Current evidence-based scores

Scores describe confidence in the current candidate, not completion percentages; none implies official runtime verification.

| Category | Score / 10 | Evidence / limitation |
|---|---:|---|
| Correctness | 7 | 389,418 desktop assertions; native arithmetic unverified |
| Original-game fidelity | 7 | Source-backed geometry/rules/abilities; explicit contact and AI approximations |
| Game feel | 3 | Responsive input design; no human graphical playtest |
| AI quality | 6 | 96 completed matches, aggregate ordered difficulty; coarse prediction and small sample |
| PICO-8 compatibility | 6 | Compatible parser/linter and budgets pass; official load pending |
| Performance | 4 | Bounded work and diagnostics; no official CPU/RAM measurements |
| Readability | 7 | Seven modular Lua files and reproducible builder |
| User experience | 5 | Complete menu/results paths execute; controller/pause feel untested |
| Visual clarity | 4 | High-contrast geometry-aligned design; native-resolution inspection pending |

## Actual validation and resources

- `lua tests/run.lua --cart`: 21 groups, 389,418 assertions passed; 96 deterministic full matches across 48 configurations. Actual assembled Lua executed in a desktop shim.
- Bottom-agent wins/24 by CPU difficulty: Easy 23, Normal 20, Hard 16, Insane 13. Agent follows a ball without abilities; this is not a human win-rate claim.
- `python3 tools/validate.py --shrinko8 /tmp/orbit-shrinko8/shrinko8.py --require-budget`: passed format, PICO-specific parse/lint and size gates.
- shrinko8 revision `d26c7d0abd6561b998ed6f530fed0ed3bc2216c9`: **6147 / 8192 tokens**, **21604 / 65535 characters**, **7568 compressed bytes** (below both tool15616 and conservative15360 thresholds). Builder counts21605 including trailing newline.
- 12/64 SFX slots, 1/64 music patterns, music channels0/1, SFX channel2; primitive graphics, no sprite/map assets.
- `lua tools/profile_prediction.lua`: sampled 1..5-ball peak desktop Lua instruction counts 17k/35k/44k/44k/45k; diagnostic excludes C API and rendering costs, not an official CPU guarantee.
- Runtime memory and CPU: unmeasured. Graphical/audio/controller playtests: **not performed**. No screenshots claimed.

## Five highest-priority outstanding issues

1. **High — official runtime verification:** load and play the cart, test fixed-point behavior and validate with INFO. No release certification until done.
2. **High — console CPU/RAM:** profile three CPUs with five balls in every arena using pause diagnostics and Ctrl-P. Native performance could still require tuning.
3. **High — human feel/audio/input:** play all difficulties, hear effects/music, verify controller mappings and pause/resume. Bot results cannot substitute.
4. **Medium — prediction approximation:** adaptive sampling can miss small bumpers or exact intercepts. Broaden deterministic seeds and adjust only if runtime budget allows.
5. **Medium — collision/presentation fidelity:** front-face paddle regions simplify capsule tips and moving dash sweeps. Inspect crowded HUD, grab attachment and goal mouths visually.

## Next actions and release gates

Run `pico8 -run carts/orbit_rush.p8` with a licensed official installation. Complete 1v1/1v2/1v3 matches, rematches and every arena, inspect native graphics/audio, record peak `stat(1)` and Lua memory, run fixed-point regressions, and document human balance feedback. Fix any observed critical defects before tagging a final release. All desktop build/test instructions are in README.md.
