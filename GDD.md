# Sniper Extraction — Game Design Document

---

## 1. Game Overview

### 1.1 Elevator Pitch
A single-player extraction shooter where you play as a sniper deployed into hostile environments. Each run drops you into a large, vertical map with a ticking clock. Stay longer for better rewards, but the world grows deadlier by the minute. Extract with your earnings — or lose it all.

### 1.2 Genre
First-person shooter / Extraction roguelike

### 1.3 Platform
PC (Steam)

### 1.4 Engine
Godot 4.4

### 1.5 Core Fantasy
You are a patient, precise sniper perched in a tower, picking off targets through your scope. You choose when to reposition, when to push your luck, and when to get out. Every bullet counts. Every second raises the stakes.

### 1.6 Target Audience
Players who enjoy tactical shooters, extraction games, and roguelike progression. Fans of Escape from Tarkov's tension, Hades' meta-progression, and Sniper Elite's satisfying gunplay — but in a single-player, run-based format.

### 1.7 Key Pillars
- **Precision over speed** — rewarding careful aim and patience, not run-and-gun
- **Long-range mastery** — the game rewards shots at 100-200m+; levels, mechanics, and scoring are built around this
- **Risk vs. reward** — every second in a run is a choice between greed and survival
- **Satisfying progression** — always moving forward, whether through credits or experience
- **Replayability** — randomized elements ensure no two runs feel identical

---

## 2. Core Gameplay Loop

### 2.1 Session Flow
```
HUB (prepare) → DEPLOY (enter level) → OPERATE (eliminate targets, complete objectives) → EXTRACT or DIE → HUB
```

### 2.2 Moment-to-Moment
The player spawns into a level, typically near a sniper nest or elevated position. From there, they survey the environment through their scope, identify targets, and begin engaging. The gameplay is deliberate — lining up shots, managing ammo, and deciding when to reposition.

As time passes, the threat level rises. New enemies spawn, patrols intensify, and the environment becomes more dangerous. But higher threat also means more valuable targets and events. The player is constantly weighing: take one more shot, push for more kills — or head to extraction and secure what they've earned.

### 2.3 Run-to-Run
Between runs, the player returns to the hub. Successful extractions convert accumulated run earnings (enemy kills, destroyed targets, contracts) into credits for weapon upgrades. Every run (even failed ones) earns experience, which is spent on permanent player skill unlocks. Over time, the player unlocks new levels, better gear, and passive abilities that make them more effective in the field.

---

## 3. Player Mechanics

### 3.1 Movement
The game emphasizes **minimal, deliberate movement**. The player is a sniper, not an assault trooper. Most of the time is spent stationary, aiming from a position.

- **WASD + mouse look** — standard first-person controls
- **Sprint** — for repositioning between cover
- **Jump** — for navigating vertical environments
- **Crouch** — reduces profile, increases accuracy, slower movement
- **Slide** — triggered from sprint + crouch, useful for quick dashes between cover
- **Ziplines** — contextual traversal for moving between buildings or elevation levels quickly

### 3.2 Weapon — Sniper Rifle
The sniper rifle is the player's only weapon. There is no secondary — every encounter must be handled at range.

- Bolt-action — single shot, must cycle bolt between shots
- Scope with adjustable zoom
- Bullet drop and travel time (projectile-based, not hitscan)
- Scope sway when aiming — reduced by holding breath (limited duration)
- Magazine-based reload
- Multiple ammo types with different damage and penetration values
- Ammo is selected and loaded at the hub before deploying — no pickups in the field
- Upgradeable parts: barrel, stock, bolt, magazine, scope (all visually distinct)
- Cosmetic skins available as progression rewards
- Weapon inspect animation (dedicated key) — shows off current rifle and equipped skin

### 3.3 Shooting Model
Shooting is the core skill expression of the game. It should feel weighty and rewarding.

- **Projectile-based bullets** — bullets are physical objects with travel time, not instant hitscan
- **Bullet drop** — gravity affects bullets over distance, requiring compensation for long shots
- **Scope sway** — crosshair drifts naturally; holding breath temporarily steadies the aim
- **Reload** — manual reload with animation, player is vulnerable during reload
- **Ammo management** — all ammo is brought from the hub; no ammo pickups in the field. Every shot matters.
- **Ammo types** — different rounds with varying damage and penetration (e.g. standard, armor-piercing, high-damage). Chosen at loadout before deploying.

### 3.4 Lives System
- The player has a limited number of lives per run (no health bar)
- Any hit from an enemy costs one life
- When all lives are lost, the player dies and the run ends (all credits lost, XP kept)
- No healing — lives are a finite resource that cannot be restored mid-run
- This reinforces the sniper fantasy: you should avoid taking hits entirely, not tank through damage

### 3.5 Interactions
- **Look + press E** — universal interaction for ziplines and extraction point
- **Ziplines** — approach and press E to attach, press again or reach the end to detach

### 3.6 Earning Credits (per run)
Credits accumulate during a run but are only kept on successful extraction:
- **Enemy kills** — each enemy type has a bounty value (higher for tougher snipers)
- **Distance bonus** — kills at 100m+ earn a multiplier (e.g. 1.5x at 100m, 2x at 150m, 3x at 200m+), rewarding the intended long-range playstyle
- **Headshot bonus** — headshots earn additional credits on top of the base bounty
- **Destroying non-NPC targets** — vehicles, equipment, supply caches scattered across the map
- **Contract completion** — bonus reward for fulfilling the chosen contract

---

## 4. Extraction & Danger System

### 4.1 Run Structure
Each run takes place on a single level. The player deploys from the hub with their current loadout and must extract before the time limit expires or they are overwhelmed.

- **Time limit** — a hard cap on how long a run can last; at zero, the run forcibly ends (death)
- **Early extraction** — the player can leave at any time via the extraction point
- **Death** — all accumulated credits and ammo brought are lost; only XP is retained

### 4.2 Escalating Danger (Threat Phases)
The level becomes progressively more dangerous the longer the player stays. Danger escalation is tied to elapsed time and displayed as a visible **threat meter** on the HUD.

**Early Phase**
- Environment is calm
- Basic targets and non-NPC objects available
- Good time to survey the map and plan

**Mid Phase**
- Aggressive enemies begin spawning
- Patrols appear and move through the level
- Higher-value targets and events start appearing

**Late Phase**
- Heavy enemy presence throughout the level
- Elite enemies with special abilities spawn
- Rare high-value targets and bonus events appear
- Maximum risk, maximum reward

### 4.3 Risk / Reward Curve
The central tension of every run: **stay or go?**

- Higher-value targets and events only appear as danger rises
- Rare targets and bonus objectives are gated behind later phases
- The player who extracts early gets modest but guaranteed earnings
- The player who pushes deep gets the best payouts — if they survive

This creates a natural difficulty curve within each run and ensures every run has dramatic tension, even for experienced players.

### 4.4 Extraction
- **Single extraction point** per level — a fixed location the player must reach
- **Extraction channel** — the player must hold E for several seconds at an extraction point to extract, creating a moment of vulnerability
- **Interruption** — extraction is cancelled if the player moves away or takes damage
- **Success** — all accumulated credits and unused ammo are transferred to the player's global save

---

## 5. Progression Systems

### 5.1 Dual Currency Model
Two currencies serve different purposes and create different incentives:

**Extraction Currency (Credits)**
- Accumulated during a run from enemy kills, destroyed targets, and contract completion
- Only kept on successful extraction — lost entirely on death
- Spent on: weapon upgrades, ammo

**Experience (XP)**
- Earned every run, regardless of outcome (extraction or death)
- Never lost — represents overall player growth
- Spent on: player skill unlocks
- Ensures even failed runs feel meaningful and forward-moving

### 5.2 Weapon Upgrades
Purchased with extraction currency at the hub. Every upgrade is a visible, physical part attached to or swapped on the rifle — no invisible stat boosts.

Upgrade categories:
- **Barrel** — affects bullet velocity (longer barrel = faster bullet, less drop)
- **Stock** — affects sway reduction (better stock = steadier aim)
- **Bolt** — affects reload speed (smoother bolt = faster cycling)
- **Magazine** — affects capacity (larger mag = more rounds before reloading)
- **Scope** — swappable optics with different zoom levels, reticles, and clarity

Each upgrade tier has a distinct visual model on the rifle. The player's weapon visually evolves as they progress.

### 5.3 Player Skill Unlocks
Purchased with experience at the hub. Permanent passive abilities:

- **Longer hold breath** — extended scope steadying duration
- **Faster zipline traversal** — quicker movement on ziplines
- **Faster reload** — stacks with weapon upgrade
- **Extra life** — start runs with an additional life

### 5.4 Cosmetics
- Rifle skins (unlocked via currency or XP milestones)
- Skins are visual overlays on top of the current upgrade parts
- Preview and equip from a dedicated hub screen

### 5.5 Ammo Economy
- Ammo is purchased with credits at the hub and stored in the player's inventory
- Before each run, the player chooses how much and which types to bring (not forced to take everything)
- Standard ammo is cheap; specialized ammo (armor-piercing, high-damage) costs more
- All 5 ammo types are available from the start — cost is the gating mechanism
- **On death:** all ammo brought into the run is lost
- **On extraction:** unused ammo returns to the hub inventory
- Creates multiple tensions: upgrades vs. ammo spending, bring more ammo (risk losing it) vs. bring less (risk running out)

### 5.6 Level Unlocks
New levels unlock through progression gates:
- Successful extraction count thresholds
- Total XP earned thresholds (not spendable XP)
- Displayed in the hub level select with requirements visible

### 5.7 Level Entry Fees
- Each level may have a credits entry fee deducted on deploy (0 = free)
- Entry fees are not refunded on death — part of the run's risk
- Harder/later levels have higher entry fees, creating an additional credit sink
- Hub level select shows fee amount and whether the player can afford it

### 5.8 Per-Level Stats
- The game tracks detailed stats per level: runs, extractions, deaths, total kills, best time, best credits
- Viewable from the Stats terminal in the hub
- Provides insight into which levels the player is most effective on

---

## 6. Level Design

### 6.1 Design Philosophy
Levels are large, detailed, and vertical. The player should feel like a sniper operating in a complex environment — not running through corridors. **The game is designed around 100-200m+ engagements.** Level geometry, enemy placement, and scoring must consistently support and reward long-range shooting.

Every level should provide:
- **Sniper nests / towers** — elevated positions with good sightlines as the primary gameplay location
- **Long-range sightlines (100-200m+)** — the dominant engagement range; most enemies should be placed at distances where bullet drop and travel time matter
- **Open kill zones** — large courtyards, plazas, valleys, or industrial yards that force engagements at range
- **Repositioning routes** — ziplines, catwalks, rooftops for moving between positions
- **Limited close-range paths** — interior areas exist for sneaking and repositioning, but enemies should rarely be encountered at close range
- **Verticality** — multiple elevation levels creating interesting long-range shooting angles and bullet drop compensation
- **Distance-based reward scaling** — longer shots earn more credits/XP to incentivize the intended playstyle

### 6.1.1 Long-Range Design Rules
- **Minimum engagement distance:** Most enemy spawn points should be 80m+ from player vantage points. Close spawns (under 50m) should be rare exceptions.
- **Level scale:** Maps should be at least 200m x 200m to support proper sightlines.
- **Elevation matters:** Player nests should overlook large areas at 10-30m elevation advantage. This creates natural long-range angles.
- **Sight blockers, not walls:** Use terrain, foliage, scaffolding, and breakable cover to create partial occlusion at range — not solid walls that force CQB.
- **Wind corridors:** Open lanes 150m+ long where the player can see deep into the map. Every level needs at least 2-3 of these.
- **Scope-mandatory zones:** Some targets/enemies should be visible only through scope zoom, reinforcing the sniper identity.

### 6.2 Environment Types
- Industrial warehouses and compounds
- Castle/fortress structures
- Multi-story buildings with rooftop access
- Mixed environments combining open courtyards with dense interiors

### 6.3 Per-Run Variation
Each run on the same level should feel different:
- **Randomized spawn points** — enemies, targets, and events appear in different locations
- **Time of day** — morning, day, evening, night selected per run; affects visibility and atmosphere
- **Weather** — clear, fog, rain, overcast selected per run; affects sightlines and mood
- **Random events** — enemy ambushes can occur mid-run
- **Variable sniper positions** — some nests may be blocked or revealed depending on the run

> Detailed individual map designs will be documented in a separate plan.

---

## 7. Enemies, NPCs & Targets

### 7.1 Design Philosophy
All enemies are snipers. The battlefield is a network of sniper positions — the player must spot and eliminate threats before being spotted. Enemies exist to create pressure and force decisions. Neutral NPCs and destructible targets add life and additional objectives to the environment.

### 7.2 Detection System
- Line of sight + sound reaction (gunshots, bullet impacts, ally eliminations)
- Alert states: Unaware → Suspicious → Alert → Searching
- Gunshots attract nearby enemies toward the shooter's position

### 7.3 Enemy Sniper Types
All enemies are ranged threats — no melee rushers.
- **Lookout** — basic sniper, stationary, low awareness, slow reaction
- **Marksman** — repositions between nests, medium awareness, decent accuracy
- **Countersniper** — mid/late phase, scope glint visible, actively scans for player, accurate and fast
- **Heavy Sniper** — armored, late phase, requires AP ammo or headshot, high damage
- **Elite Sniper** — late phase, flanks to different nests, uses smoke/repositioning, hardest to deal with

### 7.4 Countersniper Behavior
- Visible scope glint / laser sight warns the player
- Scans sniper nests and high ground
- Returns fire accurately — forces repositioning
- Appears in mid phase, more frequent and dangerous in late phase

### 7.5 Neutral NPCs
Three NPC types, each with activity-based behavior cycles (not just patrol):

| Type | Activity Cycle | Visual Color | Kill Penalty |
|------|---------------|--------------|--------------|
| **Laborer** | Work (station) → Carry (between points) → Rest (sit/smoke) | Orange/brown | -$150 |
| **Technician** | Operate (panel/radio) → Inspect (walk stations) → Rest | Green | -$100 |
| **Civilian** | Walk (paths) → Eat (bench) → Idle (phone/chat) | Blue | -$200 |

- **Activity Points**: Marker3D nodes placed in levels define where NPCs perform each activity
- NPCs cycle through their activities, traveling between matching ActivityPoints
- **Panic/flee**: gunfire (gunshot or bullet impact) within range triggers flee behavior — NPC runs away from sound origin for several seconds, then resumes activities at nearest matching point
- NPCs do NOT alert enemies when panicking
- **Static spawning**: NPCs are placed at level start (configurable count range per level), no dynamic spawning
- **Kill penalty**: flat credit deduction from run earnings (floored at 0), shown in kill feed as red text
- Visually distinct from enemies (different mesh colors, different collision layer)
- Creates moral/tactical tension — shooting near NPCs risks losing credits, shooting through NPC areas risks hitting civilians

### 7.6 Non-NPC Targets
- **DestructibleTarget** (`StaticBody3D`): takes bullet damage, breaks when health reaches 0
- Currently one type: destructible box (50 HP, +$25 / +10 XP on destruction)
- High-value variants possible (e.g., far-distance boxes with +$50)
- Visual feedback: darkens on destruction, removed after 5 seconds
- Kill feed shows "TARGET DESTROYED | +$X" in warm yellow
- Future expansion: vehicles, equipment, supply caches, moving targets, contract objectives

### 7.7 Scaling with Threat Phase
- **Early:** neutral NPCs, static/moving non-NPC targets, no enemies
- **Mid:** lookouts, marksmen, countersnipers appear
- **Late:** heavy snipers, elite snipers, aggressive searching, maximum density

---

## 8. Objectives & Contracts

### 8.1 Contracts
Before deploying, the player picks one contract from the board in the hub:
- **Kill count** — eliminate at least N enemies
- **Headshot count** — get at least N headshots
- **Accuracy challenge** — finish with accuracy at or above N%
- **No hits** — extract without taking any damage
- **Speed extract** — extract within N seconds
- Contracts may have a credit cost to accept (higher cost = higher reward)
- Contracts can be restricted to specific levels (level_restriction field)

Future contract types (deferred):
- **Eliminate high-value target** — a specific marked enemy in the level
- **Destroy target** — locate and destroy a specific vehicle, equipment, or supply cache

Contracts provide bonus currency and XP on completion, incentivizing specific playstyles and adding structure to runs.

### 8.2 In-Run Optional Objectives
Dynamic challenges that appear during a run:
- All headshots (no body shots)
- No alerts triggered (full stealth)
- Extract before mid phase (speed run)
- No missed shots (perfect accuracy)
- No civilian casualties

Completing optional objectives grants bonus rewards at the end of the run.

### 8.3 Run Result
After each run (extraction or death), the player sees raw stats:
- Enemies eliminated
- Accuracy percentage
- Time survived
- Contract status
- Credits earned (or lost on death)
- XP earned

---

## 9. Hub

The hub is the player's base of operations between runs. It serves as the central menu and progression space.

### 9.1 Hub Areas / Screens
- **Loadout** — select ammo type and amount before deploying
- **Contract Board** — browse and accept bounties
- **Weapon Upgrades** — spend extraction currency on weapon improvements
- **Skill Tree** — spend XP on passive ability unlocks
- **Cosmetics** — preview and equip rifle skins
- **Level Select** — choose deployment level (locked/unlocked, difficulty, best stats)
- **Stats** — lifetime statistics, records, per-level performance
- **Deploy** — start a run

---

## 10. UI & HUD

### 10.1 In-Run HUD
Minimal and clean — should not obstruct the sniper's view:
- Crosshair (center)
- Scope overlay (when zoomed)
- Weapon state + ammo counter (type + magazine/reserve + credits)
- Lives indicator (hearts)
- Run timer (turns red under 30s)
- Threat phase indicator (EARLY/MID/LATE with color)
- Hold-breath meter
- Kill feed (enemy type, distance, multipliers, credits)
- Extraction progress bar (when extracting)
- Interaction prompt (contextual)

Future (deferred to Phase 4):
- Objective tracker (for in-run optional objectives)
- Active contract tracker

### 10.2 Menus
- **Main Menu** — start run, hub, settings, quit
- **Pause Menu** — resume, settings, abandon run
- **Death Screen** — XP earned, credits + ammo lost, return to hub
- **Run Result Screen** — stats, contract status, credits/XP earned
- **Settings** — controls, audio, video, sensitivity

---

## 11. Audio Direction

### 11.1 Philosophy
Audio should reinforce the tension and precision of the sniper fantasy. Silence is as important as sound — quiet moments broken by a gunshot should feel impactful.

### 11.2 Sound Categories
- **Weapons** — distinct, punchy rifle shot; bolt cycling; reload; dry fire
- **Impacts** — differentiated by surface (metal, ground, wood)
- **Enemies** — footsteps, alert calls, patrol chatter, death sounds
- **Ambient** — per-level atmosphere that shifts with threat phase; calm and quiet early, tense and layered late
- **UI** — menu interactions, extraction countdown, objective completion

---

## 12. Art Direction

### 12.1 Visual Style — Stylized Low-Poly
- Clean low-poly geometry, flat or minimal shading
- Bold readable silhouettes — player can identify enemy types at distance through scope
- Limited color palette per level (e.g. warm industrial oranges, cold fortress blues)
- Accent color for important elements (enemies, objectives, extraction point)

### 12.2 Environments
- Blocky architecture with sharp angles — fits warehouses, castles, towers
- Verticality reads clearly with contrasting floor levels
- Fog/haze for depth and atmosphere (also helps with draw distance)

### 12.3 Rifle & Upgrades
- Each upgrade part is a distinct geometric shape — easy to model, visually clear progression
- Rifle evolves visually as the player upgrades
- Scope glint on enemies as a bright accent dot

### 12.4 UI Style
- Clean, minimal, geometric — matches the world
- Monospace or angular font
- Minimal HUD that doesn't obstruct the sniper's view

### 12.5 Audio Pairing
- Minimal ambient soundscape — wind, distant sounds
- Sharp, punchy weapon sounds that contrast the quiet
- Synth or electronic tension music that builds with threat phase

---

## 13. References & Inspirations

| Game | Inspiration |
|------|-------------|
| Escape from Tarkov | Extraction loop, tension of loot-or-leave decisions, environment hostility |
| Hades | Meta-progression structure, always-progressing feel, hub between runs |
| Sniper Elite | Satisfying sniping mechanics, bullet physics, long-range gameplay |
| Slay the Spire | Run variation, risk/reward decisions, clean progression systems |
| Hitman | Level replayability, multiple approaches, contract-based objectives |
