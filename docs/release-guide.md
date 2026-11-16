# Splore release preparation

The creator reports that the current cartridge plays perfectly. This is user-reported runtime playtesting; exact PICO-8 version, tested configurations, audio/controller coverage and CPU readings have not been recorded. Preserve this working baseline while finishing release polish.

## Finish the game before packaging

1. Play every arena with 1, 2 and 3 CPUs. Check a full round, elimination, inactive walls, rematch and match finish. Include a five-ball, three-CPU session and a longer match.
2. Use Ctrl-P or the pause-menu CPU/memory overlay. Record peak readings and any frame drops; target a stable 30 FPS with headroom. Turn diagnostics off for public captures.
3. Check both keyboard and gamepad, pause/resume, music/effects toggles, DASH impact, GRAB aiming and automatic release. Listen for clipping, excessive repetition and effects masking music.
4. Ask a few fresh players to start without explanation. Watch whether they understand setup, defend the bottom goal, discover catch/throw and read cooldowns. Tune from observed problems.
5. Prioritize a short in-game controls/rules page, clearer cooldown meters, stronger hit/goal/elimination feedback, readable results and a distinctive cartridge cover. Keep effects subtle enough to preserve ball visibility. Do not add mechanics solely to fill remaining tokens.
6. Rebuild, rerun tests and inspect the final version after any changes. Do not mark 1.0 complete until the final exported cartridge itself has been played.

## Final automated checks

From the project root:

```sh
python3 tools/validate.py --shrinko8 /tmp/orbit-shrinko8/shrinko8.py --require-budget
lua tests/run.lua --cart
```

Update CHANGELOG.md and docs/test-results.md with the final version, exact commands and manual results. Choose source and asset licensing explicitly before adding a LICENSE; no license is selected automatically here.

## Create the upload cartridge

Splore browses cartridges published on the Lexaloffle BBS; there is no separate store submission in this workflow. See the official [sharing instructions](https://www.lexaloffle.com/dl/docs/pico-8_manual.html) and [cartridge submission page](https://www.lexaloffle.com/pico-8.php?page=submit).

1. Build and validate first. Open carts/orbit_rush.p8 in official PICO-8.
2. Run the game, choose a clean title or gameplay frame, and press **Ctrl-7** to capture the cartridge label. Use a real game frame or separately authored pixel cover; a label screenshot is not a separate game screenshot.
3. Stop to the console, then enter:

```text
save orbit_rush.p8.png
info
folder
```

This writes a runnable image cartridge in PICO-8's current cartridge directory; FOLDER reveals it. The first two code comments supply the printed title/credit. Confirm INFO shows the cart fits. Reload the saved `.p8.png` and complete a final smoke test.

**Label preservation:** the builder now embeds `assets/label.txt`, generated alongside `assets/label.png` by `tools/create_label.py`. Rebuilds preserve this cover. An editor-captured replacement must be copied back to the source asset before rebuilding. Always re-export after code changes; an older PNG does not acquire newer source automatically.

Use Ctrl-6 for actual screenshots and Ctrl-8 followed by Ctrl-9 for a short gameplay GIF. Capture a clear rally, a DASH or throw, and a different arena. Do not show a diagnostic overlay in promotional material.

## Publish

Sign in to the Lexaloffle BBS, use its cartridge submission form, attach the tested `.p8.png`, and prepare a release post. The BBS has a Releases category for finished cartridges. Use docs/bbs-post.md as draft copy. Add actual screenshots/GIF, version, controls, credits and the source link. Check the web player after publication, then search for the game in Splore. Discovery or featured placement is not guaranteed.

The creator has published the cartridge on the Lexaloffle BBS: https://www.lexaloffle.com/bbs/?pid=199244#p (the assistant did not perform the posting). The draft is reviewable before any external posting. For subsequent releases, update the existing BBS cartridge/post through its current edit controls rather than creating unnecessary duplicate listings.

After the final smoke test, commit the release changes, create a `v1.0.0` tag and attach the tested PNG cartridge to a GitHub release. Keep the editable source available separately.

## Manual test record

Fill these with actual observations:

- PICO-8 version/platform:
- Exact tested cart/version or SHA256:
- Arena/player-count combinations completed:
- Keyboard/controller models tested:
- Highest CPU / Lua memory readings:
- Five-ball and long-match results:
- Audio observations:
- Fresh-player feedback:
- Exported PNG reload/web-player results:
- Known remaining issues:
