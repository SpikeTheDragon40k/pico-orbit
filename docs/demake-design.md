# Orbit Rush — PICO-8 design

## Goal and core loop

Guard the bottom edge of an octagonal sci-fi arena against one, two or three CPU pilots. Return balls into rival goals while defending your own. Each goal conceded loses one point. Elimination closes that goal into a wall, changing the remaining geometry. Last survivor earns a round win; the configured round-win target ends the match.

The game's identity comes from moving-paddle spin, curved shots, paddle-offset aiming, inward DASH strikes, timed GRAB/THROW catches, prediction-based opponents and survival across four differently obstructed arenas. The demake must retain these relationships before embellishing presentation.

## Controls

| Input | Action |
|---|---|
| Left / Right (`btn(0)` / `btn(1)`) | Move bottom paddle |
| O (`btnp(4)`) | DASH |
| X (`btnp(5)`) | Arm GRAB; press again while holding to THROW |
| Up / Down (`btnp(2)` / `btnp(3)`) | Move through setup options |
| Left / Right in setup | Change current setting |
| PICO-8 pause menu | Pause/resume through the console |

Keyboard bindings and controller mapping follow the official PICO-8 runtime. No mouse, touch screen, second human controller or button combinations are required. GRAB retains depth through catch offset plus left/right movement at release; the player can also wait for automatic release. DASH and GRAB have independent cooldowns.

## Configuration and progression

Defaults: one CPU, Normal, 15 starting points, Neon Grid, first to three round wins, power-ups and extra-ball timing enabled. Offer 1–3 CPUs; Easy/Normal/Hard/Insane; points 5/10/15/20/25; all four arenas; first to 1/2/3/5 round wins; power-ups and timed additions on/off; cosmetic pilot choice; music and effects switches.

Seat order is bottom human, top CPU, left CPU, right CPU. Unoccupied and eliminated seats are walls. Later rounds begin with extra balls at round 3 and round 5, bounded at three base balls; timed additions and pickups can bring the total to five. All round participants reset points when advancing to the next round. The human may remain a spectator after elimination while remaining CPUs finish determining the round winner.

## Arenas and presentation

Use a 100×100 simulation arena on the 128×128 display with margins for the HUD. Preserve scaled chamfers and bumper positions from the source. Neon Grid is cyan/magenta and unobstructed. Solar Core is orange/yellow around one central bumper. Void Nebula is purple/mint with four satellites. Ion Reactor is green/blue with two vertically aligned coils.

Use high contrast white balls, short trails, colored paddles/goals and clear pickup letters. Bumper drawing must exactly reflect collision radii. Show remaining points for every active pilot, round progression, and human ability readiness. Avoid intricate decoration beneath balls. Reinterpret the four pilots with small original graphics: robot visor/antenna; ninja band; axolotl gills/goggles; three alien eyes. Pilot selection never changes physics.

Screen flow: title → setup/pilot choice → arena → round results → next round → match results → rematch or setup. Credits identify original creator SpikeTheDragon40k. Use compact but readable native text; setup can scroll rather than compress labels into illegibility.

## Simulation and AI

Baseline `_update()` runs at 30Hz. Velocities are units per frame, limiting magnitudes for PICO-8 fixed-point arithmetic. Ten shared collision substeps bound travel at the hard speed cap. Forces run once per frame; collision geometry is shared with the predictor. Retain bounded speed ramp, boost decay, reflection/angle blend, spin curve, bumper restitution, pair collisions and stall safeguards.

AI predicts free balls rather than tracking their current coordinates. It retains the last decision between randomized reaction intervals and prioritizes the earliest threat. Difficulty increases prediction horizon, bounce allowance, tracking accuracy, movement factor and tactical ability likelihood. Hard and Insane read spin. All CPUs respect shared cooldown and collision functions; no CPU can teleport or create impossible actions. Insane must remain fallible; balance is a test requirement, not an assumed consequence of parameters.

## Minimal vertical slice and completion gates

The smallest complete slice is Neon Grid, bottom human/top CPU, side walls, one ball, responsive movement, predictive defense, point loss, elimination, round result and restart. It must build into a self-contained `.p8` and survive a complete simulated round before extra features are relied upon.

Next integrate four-sided seating and all survival combinations, then abilities, four arenas and match progression. Add bounded multi-ball, pickups and pilots after regression coverage. Art/audio follow the working loop. Release requires official runtime load, input/audio inspection, four-player/multi-ball profiling, cartridge budget confirmation, documented human playtesting and no critical known defects. Headless Lua checks do not replace these gates.
