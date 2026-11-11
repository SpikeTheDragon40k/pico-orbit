# Original Orbit Rush analysis

Audited upstream: [SpikeTheDragon40k/orbit-rush](https://github.com/SpikeTheDragon40k/orbit-rush), commit `67acff0600263f813122d6993b51897fe687d77e`, downloaded read-only for reference to `/tmp/orbit-rush-original`. The demake is a separate implementation; no upstream files are modified.

Evidence reviewed: `README.md`, `docs/PHYSICS.md`, `docs/AI.md`, `docs/INPUT.md`; engine `core/GameEngine.kt`, `Physics.kt`, `AiController.kt`, `Arena.kt`, `PowerUps.kt`, `Tuning.kt`, `Config.kt`, `Entities.kt`, `Side.kt`, and `Input.kt`; Android `ui/game/GameRenderer.kt` and `TouchInput.kt`; original pilot construction in `art/chars.py`. Paths are relative to the upstream repository. The original README contains historical status statements; engine code is the authority for mechanics here. This analysis is source inspection, not a claim that the Android app was run.

## Identity and rules

Orbit Rush is a neon elimination arena game with two to four defended sides, not score-to-win Pong. Each participant starts with 15 points by default, configurable in five-point increments from 5 to 25. A ball entering that participant's goal costs one point. Zero points eliminates the participant and closes their goal into a wall immediately; balls already in that mouth are pushed inward. Last survivor wins the round. Match length is first to 1, 2, 3 (default), or 5 round wins, or endless. Points reset each round; round wins persist until a new match.

Each player guards one side of a 1000 by 1000 world. Bottom, top, left, right is the local seating priority, with touch players before gamepads and CPUs. The original supports multiple humans and network seats. The demake deliberately permits exactly one human, always bottom, and one to three CPUs in top/left/right order. Missing and eliminated seats are walls.

Balls accelerate with rally age. Optional multi-ball rounds start with two balls at round 3 and three at round 5. A separate default-enabled rule adds a persistent ball each minute, up to three additions. Multi-Ball pickups can add temporary excess balls up to a five-ball hard cap. When a ball scores, replacement serves restore the desired count rather than preserving every pickup ball.

## Original controls

Touch uses absolute positioning: drag anywhere in the assigned side's zone, or the portrait control-bar slider. The paddle follows with gain 30/s and maximum 4200 world units/s. The game's two actions are independent edge-triggered DASH and GRAB buttons. GRAB becomes THROW while holding a ball. Android volume keys provide alternative ability presses; gamepads use stick/D-pad movement, A/R1/R2 for DASH, B/X/L1/L2 for GRAB, and Start for pause. Gamepad movement is relative with a squared stick response and dead zone. Inputs are latched per seat and consumed once per engine tick; networking and replays feed this same input interface.

This makes a two-button demake practical: movement remains directional, button 4 (O) is DASH, button 5 (X) is GRAB/THROW. Catch offset and movement at release retain aimed throwing without an extra aim button. Touch absolute positioning, phone rotation, volume-key remapping and multiple controllers are excluded.

## Original physics

The engine accumulates display time, clamps incoming frame duration to 0.1 seconds, and advances at 120Hz. World origin is upper left and positive y points down. Ball radius is 16; paddle length 150, capsule radius 11, inset 46 and allowed overreach 20. Base ball speed is 640 u/s. Target speed grows by 5% of base per second and caps at 1500 u/s; slower balls accelerate at 170 u/s², boosted excess decays exponentially at 0.8/s, and all collision speeds cap at 2000 u/s.

Magnus acceleration is `0.02 * spin * perp(velocity)`. Velocity is renormalized so bending does not add energy. Spin decays at 0.6/s and caps at ±40 rad/s. Static wall restitution is 1.0, bumper restitution 1.08. Tangential contact slip includes disc rotation and surface motion; a friction impulse removes a fraction of slip (walls .15, bumpers .2, paddles .35), transferring spin to lateral motion and moving-paddle motion into spin.

Collisions use circle versus closest point on a segment/circle/capsule, resolve overlap, and reflect only approaching velocity. Paddle face returns blend 35% natural reflection with 65% an angle from contact offset, up to ±60°. Normal hits gain 4% speed; dash hits gain another 1.45×. Capsule tips retain a natural rounded-tip response; rear contacts do not become front-face saves. Ball pairs exchange their equal-mass normal velocity and some spin.

Ball integration uses bounded substeps, travel at most approximately .4 ball radii per check, capped at 12 substeps. Goals score after the ball center crosses more than one radius behind the goal. Chamfered corners prevent traps. A goal-axis guard ensures 28% of speed points along the only axis with open goals. After ten seconds without paddle contact, a force pulls toward the nearest open goal. The original also includes finite-position/escaped-ball recovery. Online late-save rewind exists in the engine but is irrelevant to this offline demake and is excluded.

## Abilities and pickups

DASH is a .22-second sinusoidal inward lunge, depth 55, with 2.2-second cooldown. Paddle normal velocity contributes to contact response; a hit during dash also receives the 1.45× kick.

GRAB arms a .9-second catch window with four-second cooldown. The next contacting ball attaches at its caught offset, clamped to 80% of paddle half-length, for up to 1.2 seconds. A second press or timeout launches at 1.6× target/base speed. Human aiming combines `.7 * normalized catch offset` with paddle velocity /2500, capped at ±60°. AI may set an explicit launch angle.

Pickups spawn in the central 26–74% region, avoiding bumpers and other pickups. Spawn interval is 8–13 seconds; lifetime 14 seconds; maximum two orbs. The last living player to hit the collecting ball receives the effect.

| Symbol | Original effect | Duration / limit |
|---|---|---|
| S | Goal becomes solid until first impact | 12 seconds |
| T | Incoming balls in owner's 420-unit-deep zone use half ball timestep | 6 seconds |
| M | Additional ball at pickup location, credited to collector | Five total balls maximum |
| W | Paddle expands to 145% length with gradual interpolation | 10 seconds |

Pickup weights are S/T/M/W = 3/3/2/2. Multi-Ball is excluded from the weighted pool when near the cap. Effects are cosmetic-independent; pilots have no special abilities.

## Original AI

Every CPU controls a target position and uses the same ability interface as a human. It does not teleport. Its gain is 14/s and maximum movement speed is 1600 u/s times difficulty factor. Reaction decisions have ±25% jitter and attention lapses. Between decisions the last target remains active.

The predictor simulates each free ball at 60Hz for up to 2.5 seconds, accounting for solid sides, shielded sides, bumpers, corner chamfers and other open goals. It optionally reads spin. It returns the earliest predicted paddle-line intercept; the CPU prioritizes the most urgent ball. Tracking noise is Gaussian and scales with time-to-impact and ball speed. With no threat, CPUs idle near the middle with a bias toward the nearest ball.

Aimed shots choose an opponent, sometimes the weakest. Strong CPUs choose the exposed end of the victim's goal. The controller approximately inverts the 65/35 paddle-angle blend to choose contact offset. Difficulty adds aim error. DASH is scheduled to peak at contact; GRAB is armed near an incoming ball. Held balls are released after a randomized short delay toward an opponent.

| Parameter | Easy | Normal | Hard | Insane |
|---|---:|---:|---:|---:|
| Base reaction seconds | .34 | .22 | .13 | .075 |
| Tracking error, world units | 70 | 40 | 22 | 11 |
| Movement factor | .50 | .68 | .85 | 1.00 |
| Bounce allowance | 0 | 1 | 2 | 4 |
| Reads spin | No | No | Yes | Yes |
| Aim chance | .10 | .40 | .70 | .92 |
| Aim error radians | .35 | .22 | .12 | .07 |
| Weakest-target chance | .15 | .30 | .50 | .65 |
| DASH / GRAB chance | .04 / 0 | .12 / .05 | .25 / .12 | .40 / .25 |
| Lapse chance | .10 | .05 | .02 | .005 |

The balance measurements in upstream `docs/AI.md` apply to that engine, not this port. They must not be represented as demake test results.

## Arena geometry

All layouts use the same collision model and octagonal outline. Coordinates below are original world units. The four corners cut equal 45° triangles from the square; the remaining straight portion of each side is the goal or wall.

| Arena | Corner cut | Bumpers `(x,y,r)` | Serve locations / character |
|---|---:|---|---|
| Neon Grid | 140 | None | Center; cool cyan walls and magenta accents, grid |
| Solar Core | 150 | (500,500,72) | Four diagonal positions at 330/670; orange and yellow rings |
| Void Nebula | 120 | (320,320,34), (680,320,34), (320,680,34), (680,680,34) | Center; purple and mint stars |
| Ion Reactor | 175 | (500,330,40), (500,670,40) | Center; green and blue technical pattern |

Void's bumpers are static in the actual collision definition despite flavor text mentioning drifting satellites. Ion's bumpers are vertically aligned; moving them into a horizontal pair would be an unnecessary fidelity loss.

## Visual and audio identity

The source combines neon paddle/goal colors, trails, impact particles, shake and readable name/point plates with a space backdrop and arena machinery frame. Current source artwork is flat vector-derived WebP; fallback arena/gameplay drawing uses Canvas primitives. Pilots ride hover pods. The source's pilot generation describes:

- VOLT-9: white rounded robot head, dark face visor, cyan eyes/antenna and pod. Maintenance bot turned champion.
- NYX: dark ninja-bot, magenta eye band with trailing ribbon, white angled eyes. Silent rebound specialist.
- AXI: pink axolotl with coral external gills, goggles and orange pilot suit/pod. Cheerful ace pilot.
- PRISMA: green three-eyed alien, purple suit, transparent round helmet and green pod.

Pilot choice is cosmetic in this adaptation. The original assigns profiles by seat rather than exposing the requested demake's pilot-selection flow. Sound effects are procedural WAVs played through SoundPool; the one music file is the creator-supplied MP3 “Ball in space”. Neither Android audio APIs nor that recording is required by the cartridge.

## Preservation matrix

| Feature | Classification | Demake strategy / reason |
|---|---|---|
| Point loss, elimination, solid eliminated goals | Preserve faithfully | Same rules; all missing sides are walls |
| Single human at bottom | Preserve faithfully for single-player case | Fixed order removes controller routing ambiguity |
| Four arena silhouettes and obstacles | Preserve faithfully | Divide source geometry by ten |
| Defaults/presets, round and match wins | Preserve faithfully | 15 default, 5–25 presets, first to 1/2/3/5 |
| Speed ramp, boost decay, speed cap | Preserve with simplification | 30Hz frame units; first-order decay |
| Elastic walls, chamfers, bumper bounce | Preserve with simplification | Inward half-plane walls and circles |
| Paddle angle/reflection blend | Preserve with simplification | Preserve 65/35 blend and offset aiming; simpler front collision shape |
| Moving paddle spin / Magnus | Preserve with simplification | Direct bounded spin transfer; retain trajectory bending |
| DASH | Preserve with simplification | Same lunge/cooldown/kick concept; frame-quantized timing |
| GRAB/THROW | Preserve with simplification | Retain armed catch, offset attachment, motion aiming and timeout |
| Ball pairs | Preserve with simplification | Shared bounded substeps and equal-mass response |
| Goal-axis and stall guards | Preserve with simplification | Same purpose, scaled forces |
| Predictive AI and four difficulties | Preserve with simplification | Cached targets, bounded horizon/bounces, reaction error and abilities |
| Shield, Slow-Mo, Wide | Preserve with simplification | Same owner-local function and durations; instantaneous width change |
| Multi-Ball pickup | Preserve with simplification | Spawn at safe arena serve location rather than orb position |
| Pickup spawning | Preserve with simplification | Bounded retries; equal type probability instead of weighted pool |
| Round multi-ball and timed additions | Preserve with simplification | Round 3/5 progression; timed additions configurable |
| Pilot appearance and personalities | Redesign for PICO-8 | Small original pixel reinterpretations; cosmetic choice |
| Art, HUD, menus and effects | Redesign for PICO-8 | 128×128, 16 colors, primitive graphics and compact screens |
| Audio/music | Redesign for PICO-8 | Original sequenced PICO-8 audio, no MP3 conversion |
| Keyboard/gamepad controls | Redesign for PICO-8 | D-pad and two actions; native console pause |
| Multiplayer/network/accounts/lobbies | Exclude | Strict offline single-player mission |
| Android touch/rotation/haptics/platform APIs | Exclude | No target equivalent required |
| Network rewind, snapshots, replay protocol | Exclude | Unnecessary code/memory for standalone offline play |
| Endless mode / every source setting | Exclude | Bounded match flow and readable menus |

This matrix describes implementation intent and code-level mapping. Runtime correctness, balance, measured resource use and graphical verification are recorded separately in test results; source inspection alone does not establish them.
