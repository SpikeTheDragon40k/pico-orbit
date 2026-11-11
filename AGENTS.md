# Orbit Rush PICO-8 development

Read docs/original-game-analysis.md and docs/porting-decisions.md before altering mechanics. The Kotlin source is reference-only; do not modify it. Keep exactly one human bottom paddle. Empty and eliminated sides are solid.

Use PICO-8 APIs and standard-compatible Lua syntax in src/. Keep per-frame velocities and bounded counters safe under signed16.16 arithmetic. Frame rate baseline30Hz. Never replace PICO-specific budget checks with a generic token count.

Build with python3 tools/build.py. Validate with python3 tools/validate.py --shrinko8 PATH --require-budget and lua tests/run.lua --cart. Update test-results/progress with commands that actually ran. No claim of official runtime, graphical, audio or CPU verification without executing that check. Keep commits small and meaningful.
