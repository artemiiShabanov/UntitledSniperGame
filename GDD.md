# Sniper Extraction: The Last Rifle — Game Design Document

---

## 1. Game Overview

### 1.1 Elevator Pitch
A modern sniper is teleported onto a medieval battlefield. Perched on castle walls, you defend against an ever-growing siege — picking off warriors, destroying siege equipment, and managing your limited ammunition. Lose your weapon mods if you fall. Unlock army upgrades across runs to eventually win the war.

### 1.2 Genre
First-person shooter / Roguelike defense

### 1.3 Platform
PC (Steam)

### 1.4 Engine
Godot 4.4

### 1.5 Core Fantasy
You are a modern sniper dropped into a medieval world. From atop castle walls, you look down on a raging battlefield — hundreds of warriors clashing below. Your rifle is impossibly powerful here. Every bullet can change the tide. But bullets are finite, the enemy grows stronger, and the castle won't hold forever.

### 1.6 Target Audience
Players who enjoy tactical shooters, roguelike progression, and tower-defense-adjacent gameplay. Fans of Sniper Elite's satisfying gunplay, Slay the Spire's risk/reward meta-progression, Kingdom's "protect the walls" tension, and Hades' hub-between-runs loop.

### 1.7 Key Pillars
- **Precision over speed** — every bullet counts; rewarding careful aim and target prioritization
- **Living battlefield** — the level is alive with warriors fighting each other; the player influences but doesn't control the battle
- **Escalating siege** — threat grows infinitely; the question is never "will you win" but "how long can you hold"
- **Meaningful loss** — weapon mods are lost on failure, creating real stakes per run
- **Meta-progression toward victory** — across many runs, unlock army upgrades that eventually let you win the war

---

## 2. Core Gameplay Loop

### 2.1 Session Flow
```
HUB (equip mods, select level) → DEPLOY (castle walls) → DEFEND (snipe targets, survive threat, handle opportunities) → EXTRACT or FALL → HUB
```

### 2.2 Moment-to-Moment
The player spawns atop castle walls or towers overlooking a battlefield. Below, friendly and enemy warriors clash in melee combat. The player surveys through their scope, identifies priority targets — enemy warriors pushing the walls, ranged threats targeting the player, siege equipment, opportunity events — and fires.

Every shot is a decision: bullets are limited, and each one spent on a low-value target is one fewer for the elite enemies coming later. As phases progress, the enemy army grows stronger — tougher warriors, more ranged threats, siege equipment. The castle takes damage from enemy melee warriors reaching the walls. The player must balance killing threats to themselves (ranged enemies) vs. threats to the castle (melee warriors at the gates).

Extraction windows appear periodically — a brief chance to leave with your rewards. Miss it, and you wait for the next one while the siege intensifies.

### 2.3 Run-to-Run
Between runs, the player returns to the hub. Successful extractions award a choice of weapon mods (rarity based on performance). Failed runs lose all equipped mods. XP is always earned. Over many runs, the player unlocks permanent army upgrades that strengthen the friendly forces, eventually enabling a winnable final stand at phase 20.

---

## 3. Player Mechanics

### 3.1 Movement
The player operates on castle walls and towers but retains full movement for repositioning.

- **WASD + mouse look** — standard first-person controls
- **Sprint** — for quick repositioning between firing positions
- **Jump** — for navigating vertical elements on the walls/towers
- **Crouch** — reduces profile, increases accuracy, slower movement
- **Slide** — triggered from sprint + crouch, useful for quick dashes between cover
- **Ziplines** — traverse between wall sections and towers quickly (deferred — design levels without, add if playtesting reveals need for faster traversal)

### 3.2 Weapon — Sniper Rifle
The sniper rifle is the player's only weapon. It is anachronistically powerful on this battlefield.

- Bolt-action — single shot, must cycle bolt between shots
- Scope with adjustable zoom
- Bullet drop and travel time (projectile-based, not hitscan)
- Scope sway when aiming — reduced by holding breath (limited duration)
- Magazine-based reload
- Fixed bullet count per run (no ammo types, no shop — bullet count upgraded via progression)
- Upgradeable parts: barrel, stock, bolt, magazine, scope (all visually distinct)
- Palette-colored via accent colors with PBR shading
- Weapon inspect animation (dedicated key)

### 3.3 Shooting Model
Shooting is the core skill expression. It should feel weighty and rewarding.

- **Projectile-based bullets** — physical objects with travel time
- **Bullet drop** — gravity affects bullets over distance
- **Scope sway** — crosshair drifts naturally; holding breath temporarily steadies aim
- **Reload** — manual reload with animation, player is vulnerable
- **Ammo management** — fixed bullet count per run, no pickups, no resupply. Every shot matters.

### 3.4 Lives System
- The player has a limited number of lives per run (no health bar)
- Any hit from a ranged enemy costs one life
- When all lives are lost, the run fails (mods lost, XP kept)
- No healing — lives are finite and unrestorable mid-run
- Reinforces the sniper fantasy: avoid taking hits entirely

### 3.5 Interactions
- **Look + press E** — universal interaction for ziplines and extraction points
- **Ziplines** — approach and press E to attach, press again or reach end to detach (deferred)

### 3.6 Scoring
Score accumulates during a run and determines mod rarity on extraction:

- **Enemy kills** — each enemy type has a base score value
- **Headshot bonus** — 2x score multiplier
- **Destructible targets** — bonus score for powder kegs, siege equipment
- **Opportunity completion** — bonus score for handling special events
- **Castle HP remaining** — bonus multiplier based on how much castle HP is left at extraction

---

## 4. Battlefield & Threat System

### 4.1 Run Structure
Each run is a defense mission on a single level. The player deploys from the hub with their equipped mods and a fixed bullet count. There is no timer — the run ends when:
- The player extracts during an extraction window (success)
- The player loses all lives (failure)
- The castle HP reaches 0 (failure)

Phase 20 is simply the hardest phase. Surviving it and extracting is the "win" — there is no separate end condition when phase 20 completes. The siege continues until the player extracts, dies, or the castle falls.

### 4.2 Castle HP
The castle has a visible HP bar. Enemy melee warriors that reach the castle walls deal damage to it.

- **Castle HP** starts at a fixed value (tunable per level)
- **Damage scaling** — stronger enemy warrior types in later phases deal more castle damage
- **Player agency** — killing melee warriors before they reach the walls prevents castle damage
- **Phase 20 cap** — the final phase sends an overwhelming wave designed to test whether the player has enough army upgrades to survive
- **Visual feedback** — castle HP bar on HUD (future: cracks, fires, defenders overwhelmed)

### 4.3 Threat Escalation (20 Phases)
Threat increases continuously. No timer — phases advance at fixed intervals. Extraction windows grow further apart as phases increase.

**Phase Progression:**
- **Phases 1-3 (Early)** — Swordsmen only on both sides. Few spawns, calm battlefield. Player learns the flow.
- **Phases 4-5 (Building)** — First archers appear (phase 4). Swordsman spawning accelerates. Battlefield starts to feel real.
- **Phases 6-7 (Rising)** — Big guys start appearing (phase 6). Heavy archers join (phase 7). Castle pressure begins as big guys deal serious wall damage.
- **Phases 8-9 (Dangerous)** — Crossbowmen appear (phase 9). Big guys are now common. Significant ranged threat to player and melee threat to castle.
- **Phase 10 (Major Wave)** — First boss-tier wave. Knights debut. Surge of all types, multiple ranged threats. Tests mid-game readiness.
- **Phases 11-14 (Escalation)** — Bird trainers appear (phase 11). Knights become regular. Castle damage rate spikes.
- **Phase 15 (Elite Wave)** — Second boss-tier wave. Heavy siege pressure. Knight-heavy assault. Demands strong loadout and army upgrades.
- **Phases 16-19 (Endgame)** — Maximum enemy density. All types active. Knights in every wave. Castle under relentless pressure.
- **Phase 20 (Final Stand)** — Overwhelming knight-heavy assault with full ranged support. Designed to be unwinnable without sufficient army upgrades. The ultimate test.

**Extraction Window Pacing:**
- Early phases: extraction windows every ~2 minutes, lasting ~15 seconds
- Mid phases: every ~3 minutes, lasting ~10 seconds
- Late phases: every ~4-5 minutes, lasting ~8 seconds
- This creates increasing tension: "can I survive until the next window?"

### 4.4 Extraction
- **Multiple extraction points** exist in each level, but only one activates at a time
- **Timed windows** — an extraction point activates for a short duration, then deactivates
- **HUD announcement** — "EXTRACTION AVAILABLE" with location indicator and countdown
- **Hold E** to extract (several seconds), cancelled by movement or damage
- **Success** — score tallied, mod choice offered, XP awarded, run stats recorded
- **Missing the window** — must survive until the next one activates

### 4.5 Failure
On death (lives lost) or castle destruction:
- **All equipped weapon mods are lost** — this is the core risk/stake
- **XP is kept** — ensures even failed runs contribute to meta-progression
- **Run stats are recorded** — for tracking improvement

---

## 5. The Battlefield

### 5.1 Level Structure
Every level follows a three-zone layout designed for the sniper fantasy:

**Zone 1 — The Castle (Player Base)**
- Elevated walls, towers, and ramparts where the player operates
- Multiple firing positions with different sightlines
- Ziplines connecting wall sections and towers (deferred)
- Extraction points located along the walls
- Castle gate/entrance — where enemy melee warriors attack

**Zone 2 — The Battlefield (Kill Zone)**
- Open ground between the castle and enemy positions
- Where friendly and enemy warriors clash in melee
- Long sightlines (100-200m+) for sniper engagement
- Scattered cover (rocks, barricades, trenches) creating partial occlusion
- Terrain variation (hills, ditches) affecting sightlines

**Zone 3 — Enemy Positions (Far Side)**
- Where enemy warriors spawn and advance from
- Enemy structures (camps, towers, siege positions)
- Ranged enemies positioned here targeting the player
- Siege equipment assembled here
- Destructible targets (powder kegs, siege equipment) located in this zone

### 5.2 Battlefield Feel
The level must feel like a living battlefield:
- **Constant spawning** — warriors spawn from both sides continuously
- **Melee combat** — friendly and enemy warriors engage each other on the battlefield
- **Flow of battle** — warriors advance, clash, and fall. The battlefield shifts as one side pushes
- **Player influence** — the player's shots can tip local engagements by removing key enemies
- **Chaos increases** — more warriors, faster spawning, tougher types as phases progress

### 5.3 Per-Run Variation
Each run on the same level feels different:
- **Randomized spawn timing** — warrior waves vary in composition and timing
- **Time of day** — morning, day, evening, night; affects visibility
- **Weather** — clear, fog, rain; affects sightlines and atmosphere
- **Opportunity events** — different events trigger each run
- **Extraction point rotation** — different points activate each cycle

---

## 6. Warriors

### 6.1 Design Philosophy
Warriors are the lifeblood of the battlefield. They spawn from both sides (friendly and enemy), advance toward each other, and fight in melee. The player doesn't control friendly warriors — they fight autonomously. Enemy warriors are the player's targets and the source of castle damage.

Friendly and enemy warriors share the same types but are visually distinguished by palette colors (accent_friendly vs. accent_hostile).

### 6.2 Melee Warrior Types

| Type | Phase | HP | Damage | Armor | Speed | Score | XP | Notes |
|------|-------|----|--------|-------|-------|-------|----|-------|
| **Swordsman** | 1+ | Low | Medium | None | Medium | 20 | 10 | Standard infantry. The backbone of the army from phase 1 onward. |
| **Big Guy** | 6+ | High | High | Light | Slow | 40 | 20 | Large, tough brute. Slow but hits hard. Easy to spot, takes multiple body shots. |
| **Knight** | 10+ | Very high | Very high | Heavy | Medium | 70 | 35 | Fully armored elite. Headshot or multiple body shots required. Devastating castle damage. |

- **Swordsman** — the standard warrior. Carries a sword, deals respectable damage. Present from phase 1 in small numbers, scaling up through mid-game. One body shot or headshot to kill.
- **Big Guy** — a large, imposing brute with a two-handed weapon (axe or hammer). High HP means he survives a body shot — requires a headshot or 2 body shots. Slow movement makes him an easier target at range, but if he reaches the castle walls he deals heavy damage. Visually distinct due to size.
- **Knight** — the elite. Full plate armor, sword and shield. Very high HP and heavy armor — body shots do reduced damage. Headshot is the efficient answer. Deals devastating castle damage. Becomes the primary castle threat in late phases. Visually distinct (armored silhouette, shield).

**Armor:** Knights have heavy armor (body shot damage significantly reduced). Big Guys have light armor (moderate reduction). Swordsmen have no armor. Headshots bypass armor on all types.

**Castle damage:** When an enemy melee warrior reaches the castle gate/walls, they deal damage to castle HP proportional to their type. Swordsmen deal low damage, big guys heavy, knights devastating. This naturally scales castle pressure with threat phase as tougher types spawn later.

### 6.3 Ranged Enemy Types (Threats to Player)
Ranged enemies target the player specifically. They spawn in enemy positions (Zone 3) and don't advance into melee.

| Type | Phase | HP | Accuracy | Fire Rate | Damage | Score | XP | Behavior |
|------|-------|----|----------|-----------|--------|-------|----|----------|
| **Archer** | 4+ | Low | Low | Slow | 1 life | 40 | 20 | Basic ranged threat. Visible arrow travel time. Stationary. |
| **Heavy Archer** | 7+ | Medium | Medium | Slow | 1 life | 60 | 30 | Better accuracy, repositions between shots. |
| **Crossbowman** | 9+ | Medium | High | Very slow | 1 life | 80 | 40 | High accuracy, long reload. Dangerous but predictable timing. |
| **Bird Trainer** | 11+ | Low | N/A | Medium | 1 life | 100 | 50 | Spawns kamikaze birds that fly toward the player. Birds must be shot down or they deal damage. Max 3 active birds. |

- **Archer** — the introductory ranged threat. Low accuracy, visible arrow flight gives the player time to react. Teaches the player to prioritize ranged enemies.
- **Heavy Archer** — more dangerous version. Better accuracy, repositions to new cover after each shot. Requires re-acquisition after engaging.
- **Crossbowman** — the precision threat. High accuracy but very slow reload. Player can learn the timing and use the reload window to engage safely.
- **Bird Trainer** — doesn't attack directly. Instead, releases trained birds that kamikaze toward the player. Birds are small, fast-moving aerial targets that must be shot down. Creates ammo pressure (spending bullets on birds vs. saving for warriors). Replaces the drone concept from the original design.

### 6.4 Friendly Warriors
Friendly warriors share the same types as enemy warriors (swordsman, big guy, knight). They:
- Spawn from the castle side and advance toward the enemy
- Fight enemy warriors autonomously in melee
- Are colored with `accent_friendly` palette slot
- **Killing a friendly warrior incurs a score penalty** (shown in kill feed as red text)
- Cannot be healed or commanded by the player
- Their strength can be upgraded via army upgrades (see §8.3)

### 6.5 Warrior AI
Warriors use a simple state machine with readable, predictable behavior:

**States:**
- **Advancing** — marching toward the enemy side in a straight line. Default state after spawning.
- **Focusing** — an opposing warrior is within engagement range. Warrior turns toward them and closes distance.
- **Attacking** — in melee range with an opponent. Warriors take turns rolling attacks (see combat below).
- **Idle** — brief pause after winning a fight before resuming advance.
- **Dead** — plays death animation, removed from battlefield.

**State transitions:**
```
Spawn → Advancing → (enemy in range?) → Focusing → (in melee range?) → Attacking
Attacking → (opponent dies?) → Idle → Advancing
Attacking → (self dies?) → Dead
Advancing → (reached castle walls?) → Attacking (deals damage to castle HP)
```

**Roll-based combat:**
When two opposing warriors enter Attacking state, they exchange blows in turns:
1. Attacker rolls: **hit** (deals damage to opponent HP) or **miss** (nothing happens)
2. Short delay (tunable, ~0.5-1s)
3. Defender rolls their attack
4. Repeat until one warrior's HP reaches 0

Hit chance and damage are based on warrior type stats. This creates visible, readable fights where warriors clash for a few seconds before one falls — without requiring complex animation sync or real combat AI.

**Pathing:** Warriors do NOT path intelligently or flank. They march forward and fight what's in front of them. This creates a predictable, readable battlefield that the player can learn to influence with precision shots.

---

## 7. Destructible Targets

### 7.1 Design Philosophy
Destructibles are static, high-value targets placed in the enemy zone. They are thematic — destroying them weakens the enemy war effort. All are one-shot kills.

### 7.2 Destructible Types

| Type | Location | Size | Score | XP | Effect |
|------|----------|------|-------|----|--------|
| **Powder Keg** | Near enemy groups, siege positions | Medium | 80 | 30 | Explodes on hit — deals AoE damage to nearby enemy warriors, potentially killing several |
| **Siege Equipment** | Enemy zone | Large | 150 | 60 | Phase-gated (phase 6+). While alive, deals passive castle HP damage per second. Priority target. |

- **Powder Keg** — placed near groups of warriors. The AoE explosion can kill multiple enemies with a single bullet — extremely ammo-efficient. Rewards patience (wait for enemies to cluster near it).
- **Siege Equipment** — appears in later phases. Catapults or battering rams that passively drain castle HP while they exist (flat DPS, no projectile simulation needed). Visually: the equipment animates a repeating attack cycle (catapult arm swings, ram rocks back and forth) so the player can see it's actively damaging the castle. Must be destroyed or the castle bleeds out. Creates clear priority targets.

---

## 8. Progression Systems

### 8.1 Experience (XP)
- Earned every run, regardless of outcome
- Never lost
- Spent on: player skills, army upgrades
- Ensures even failed runs are meaningful

### 8.2 Player Skills
Purchased with XP at the hub. Permanent passive abilities:

| Skill | XP Cost | Effect |
|-------|---------|--------|
| **Iron Lungs** | 100 | +2 seconds breath hold duration |
| **Quick Hands** | 150 | 20% faster reload speed |
| **Last Stand** | 200 | +1 extra life per run |
| **Deep Pockets** | 150 | +5 bullets per run |

### 8.3 Army Upgrades (Global Goal)
The meta-progression system. Purchased with XP and/or global progression points (earned from opportunities). Army upgrades strengthen the friendly forces permanently across all future runs.

**Design goal:** ~15-20 runs to fully upgrade and beat a level's phase 20.

Army upgrades are **visible on the battlefield** — the player sees their investment in action.

| Upgrade | Cost | Effect | Visual |
|---------|------|--------|--------|
| **Hardened Warriors** | — | Friendly warriors gain +30% HP | Warriors wear helmets/padding |
| **Battle Training** | — | Friendly warriors deal +25% damage and have higher hit chance | Warriors have larger weapons |
| **Reinforced Gates** | — | +40% castle max HP | Visible gate reinforcement (iron bands, thicker walls) |
| **Faster Muster** | — | Friendly warriors spawn 25% more frequently | More warriors visible on the field |
| **Archer Tower** | — | Adds a friendly archer tower on the castle walls that periodically shoots enemy warriors | Tower physically appears on castle |
| **Elite Guard** | — | A squad of elite friendly knights spawns every 5 phases | Visually distinct armored knights march out |

> Exact costs, unlock order, and balance TBD. The key principle: each upgrade is visible and felt in gameplay. The first 4 are stat modifiers (cheap to implement). Archer Tower and Elite Guard are the only upgrades that spawn new entities.

### 8.4 Bullet Count Progression
- Player starts with a base bullet count (e.g., 15 bullets per run)
- Upgradeable via the **Deep Pockets** skill and potentially army upgrades
- No ammo types — all bullets are standard sniper rounds
- No ammo shop — simplifies the loop, makes each shot count

### 8.5 Color Palettes
- Achievement-gated palette unlocks
- Palette selection panel in hub
- Entire game world recolors instantly via global shader uniforms
- Palette colors: `bg_light`, `bg_mid`, `fg_dark`, `accent_hostile`, `accent_friendly`, `accent_loot`, `danger`, `reward`

---

## 9. Weapon Modification System

### 9.1 Mods as Roguelike Items
Weapon mods are procedurally generated and function like roguelike relics:

- **Earned on extraction** — after a successful run, the player chooses 1 mod from 3 randomly generated options
- **Lost on failure** — all equipped mods are lost when the player dies or the castle falls
- **Stored in hub inventory** — unequipped mods are safe in the hub stash
- **Inventory cap** — 5 mods per slot (25 total across 5 slots)
- **Rarity system** — Common, Uncommon, Rare, Epic (determines stat ranges)

### 9.2 Procedural Mod Generation
Mods are **not** hand-crafted items from a fixed catalog. Each mod is generated with:

1. **Slot** — which slot it belongs to (barrel, stock, bolt, magazine, scope)
2. **Rarity** — determines the stat budget (higher rarity = better stat rolls)
3. **Stats** — randomly rolled within the rarity's range for that slot
4. **Visual type** — randomly selected from 3 visual variants per slot

This means every mod is unique. Two "Rare Barrels" will have different stat values. Players compare mods by their actual numbers, not by name.

**Rarity determines stat ranges, not fixed values:**

| Rarity | Color | Stat Range | Drop Weight (early) | Drop Weight (late) |
|--------|-------|-----------|--------------------|--------------------|
| Common | White | 50-70% of max | 60% | 20% |
| Uncommon | Green | 60-80% of max | 30% | 35% |
| Rare | Blue | 75-90% of max | 9% | 30% |
| Epic | Purple | 85-100% of max | 1% | 15% |

Rarity of offered mods depends on **phase reached** and **run score**.

### 9.3 Mod Slots & Stats
Each slot has defined stats that are rolled on generation:

**Barrel** — 3 visual types
| Stat | Min | Max | Effect |
|------|-----|-----|--------|
| Velocity | 280 | 450 | Bullet travel speed (less drop at range) |

**Stock** — 3 visual types
| Stat | Min | Max | Effect |
|------|-----|-----|--------|
| Sway reduction | 0% | 40% | Reduces scope sway amplitude |
| Move speed | -20% | +15% | Walk/sprint speed modifier (trade-off) |

**Bolt** — 3 visual types
| Stat | Min | Max | Effect |
|------|-----|-----|--------|
| Cycle time | 0.6s | 1.2s | Time between shots (lower = faster) |
| Stay scoped | No / Yes | — | Whether player stays zoomed during cycling |

**Magazine** — 3 visual types
| Stat | Min | Max | Effect |
|------|-----|-----|--------|
| Capacity | 4 | 10 | Rounds per magazine |
| Reload speed | -30% | +20% | Reload time modifier |

**Scope** — 3 visual types
| Stat | Min | Max | Effect |
|------|-----|-----|--------|
| FOV (zoomed) | 8° | 40° | Zoom level (lower = more zoom) |
| Variable zoom | No / Yes | — | Scroll wheel zoom adjustment |

> Boolean stats (stay scoped, variable zoom) have a % chance to roll "Yes" that increases with rarity.

### 9.4 Mod Visuals
- Each slot has **3 visual types** — distinct 3D models on the rifle viewmodel
- Visual type is randomly assigned on generation (purely cosmetic, independent of stats)
- Rarity indicated by trim/glow color (white/green/blue/purple)
- Player's weapon visually evolves as they equip better mods

---

## 10. Opportunities (Events + Contracts)

### 10.1 Design Philosophy
Opportunities replace the old contract and event systems. They are dynamic events that occur during a run — each with a timing window, a chance to trigger, and a reward if handled. They create moment-to-moment decision points beyond basic target prioritization.

### 10.2 Opportunity Structure
Each opportunity has:
- **Phase range** — earliest and latest phase it can trigger
- **Chance** — probability of triggering when its phase range is active
- **Duration** — how long the player has to complete it
- **Reward** — score, XP, and/or global progression points
- **Announcement** — HUD notification when triggered

### 10.3 Opportunity Types
All 4 types follow the same pattern: a target appears, the player must kill it within a time limit.

| Opportunity | Phase Range | Duration | Reward | Description |
|-------------|-----------|----------|--------|-------------|
| **Enemy Champion** | 4-15 | 60s | High score + XP | A named, tougher enemy warrior appears on the battlefield. Visually distinct (larger, glowing). Must be killed before they reach the castle. Deals massive castle damage if they arrive. |
| **Siege Assault** | 8-18 | 90s | Global progression point | Multiple siege weapons activate simultaneously. Destroy all within the time limit to earn a progression point. |
| **Archer Ambush** | 6-16 | 45s | High score + XP | A group of enemy archers appears at unexpected positions. Kill all within the time limit. |
| **War Horn** | 5-15 | Instant | Global progression point | An enemy war horn carrier appears briefly. One-shot opportunity — if hit, disrupts the next enemy wave (delays it by one phase interval). Awards a progression point. |

> All opportunities use the same system: "kill target(s) within time." More types can be added as content using this pattern.

---

## 11. Level Design

### 11.1 Design Philosophy
All levels follow the three-zone structure (§5.1): Castle → Battlefield → Enemy Positions. Levels are procedurally generated within set rules using the grid-based generation system.

**Long-range design rules:**
- Minimum engagement distance: most enemies at 80m+ from player positions
- Level scale: at least 200m deep (castle to far enemy positions)
- Elevation: player on walls at 10-30m height advantage
- Sightline lanes: 2-3 clear lanes of 150m+ per level
- Partial occlusion via terrain, cover, structures — not solid walls

### 11.2 Level Generation
Each level is built from a grid of blocks with constraint-based placement:

- **Castle blocks** — wall sections, towers, gate, ramparts (Zone 1)
- **Battlefield blocks** — open ground, trenches, scattered cover, terrain features (Zone 2)
- **Enemy blocks** — camps, siege positions, archer towers, rally points (Zone 3)
- **Constraint rules** — ensure proper sightlines, spawn point placement, extraction point distribution
- **Sniper nest anchors** — define player firing positions with guaranteed sightline lanes

### 11.3 Level Themes
Each level is a different medieval setting with unique block catalogs:

#### Level 1 — Castle Keep
- Classic stone castle with thick walls and square towers
- Battlefield: open meadow with scattered rocks and wooden barriers
- Enemy: wooden palisade camp with tents and siege equipment
- Difficulty: introductory, fewer ranged threats

#### Level 2 — Hilltop Fortress
- Fortress on a hill with sloped approaches
- Battlefield: terraced hillside with stone walls and ditches
- Enemy: forest edge with hidden positions and winding paths
- Difficulty: elevation advantage but enemies have more cover

#### Level 3 — River Crossing
- Castle walls along a river with a bridge as the main chokepoint
- Battlefield: river banks and bridge — warriors funnel across
- Enemy: far bank with elevated positions for ranged enemies
- Difficulty: concentrated action at bridge creates target-rich but chaotic environment

#### Level 4+ — Additional themes as needed
- Mountain pass, coastal cliff fortress, walled city, etc.

### 11.4 Per-Run Variation
- **Time of day** — morning, day, evening, night
- **Weather** — clear, fog, rain
- **Spawn timing variation** — wave composition varies per run
- **Opportunity selection** — different opportunities trigger each run
- **Extraction point rotation** — different points activate each cycle

---

## 12. Hub

### 12.1 Hub Areas / Screens
The hub is the player's base between runs:

- **Armory** — equip weapon mods from inventory, view current loadout
- **Mod Stash** — browse owned mods, manage inventory (6 per slot cap)
- **Skill Board** — spend XP on permanent player skills
- **War Room** — view army upgrades, spend XP/progression points on unlocks
- **Level Select** — choose deployment level, view level stats and requirements
- **Palettes** — browse, preview, and equip color palettes
- **Stats Terminal** — lifetime statistics, per-level records, achievement progress
- **Deploy** — start a run with current loadout

### 12.2 Removed Hub Elements
The following are removed from the old design:
- ~~Ammo shop~~ — bullets are fixed per run, no purchasing
- ~~Contract board~~ — replaced by in-run opportunities
- ~~Mod shop~~ — mods are earned through extraction, not purchased
- ~~Credits/money system~~ — replaced by score + mod drops

---

## 13. UI & HUD

### 13.1 In-Run HUD
Minimal and clean:
- **Crosshair** (center, hidden when scoped)
- **Scope overlay** (when zoomed, style matches equipped scope)
- **Ammo counter** — bullets remaining / magazine (no reserve — total bullets shown)
- **Lives indicator** — hearts
- **Castle HP bar** — prominent, shows castle health
- **Threat phase indicator** — "PHASE N" with color coding
- **Hold-breath meter** — cyan when holding, red when exhausted
- **Kill feed** — target type, distance, multipliers, score
- **Extraction notification** — "EXTRACTION AVAILABLE" with timer and location
- **Extraction progress bar** — when extracting
- **Opportunity notification** — event announcements with timer
- **Interaction prompt** — contextual (E key)

### 13.2 Menus
- **Main Menu** — new game, continue, settings, quit
- **Pause Menu** — resume, settings, abandon run
- **Run Result Screen** — score breakdown, phase reached, castle HP remaining, opportunity completions, mod choice (if extracted), XP earned
- **Failure Screen** — stats, mods lost, XP kept, return to hub
- **Settings** — controls, audio, video, sensitivity

---

## 14. Audio Direction

### 14.1 Philosophy
The medieval battlefield should sound chaotic and alive. The player's rifle is the anachronistic intrusion — it should sound distinct and powerful against the medieval soundscape.

### 14.2 Sound Categories
- **Weapons** — modern rifle: punchy shot, bolt cycling, reload, dry fire. Sounds alien in this world.
- **Battlefield** — sword clashing, shields hitting, war cries, death sounds, marching. The ambient noise of war.
- **Ranged enemies** — arrow whistles (warning sound when arrows fly near player), crossbow thunks, bird screeches
- **Castle** — stone impacts when castle takes damage, crumbling sounds at low HP
- **Ambient** — wind on the walls, distant battle sounds that intensify with phase
- **UI** — extraction alerts, opportunity announcements, phase transitions

### 14.3 Removed Audio Needs
- ~~Enemy detection/alert sounds~~ — no longer relevant (warriors don't detect the player, ranged enemies simply shoot)
- ~~Stealth audio~~ — no stealth system in the new design

---

## 15. Art Direction

### 15.1 Visual Style — Palette-Driven Minimal
Same as original — clean low-poly geometry with swappable color palettes.

- **B&W base** — world geometry in grayscale
- **Palette accent colors:**
  - `accent_hostile` — enemy warriors, ranged threats, siege equipment
  - `accent_friendly` — friendly warriors, castle elements
  - `accent_loot` — destructibles, opportunity targets, extraction points
- `danger` — damage, castle HP loss, failure states
- `reward` — score gains, XP, successful extraction
- Light **film grain** post-process overlay

### 15.2 Medieval Environments
- Blocky stone architecture for castle walls and towers
- Open terrain with low-poly grass, rocks, trenches
- Enemy camps with tents, palisades, siege equipment
- Verticality through castle elevation over battlefield

### 15.3 Warriors
- Simple humanoid meshes, distinguished by silhouette (swordsman = medium, big guy = large/bulky, knight = armored with shield)
- Friendly vs enemy distinguished by palette color (`accent_friendly` vs `accent_hostile`)
- Ranged enemies visually distinct (bow shape, crossbow shape, bird perch)

### 15.4 Rifle & Mods
- Same as original: each mod is a distinct geometric shape
- Rarity indicated by subtle trim/glow (white/green/blue/purple)
- Rifle is visually anachronistic — modern weapon in medieval world

### 15.5 UI Style
- Clean, minimal, geometric
- Monospace or angular font
- Medieval-inspired borders/frames for menus (subtle, not overdone)
- Palette-aware theming

---

## 16. Save System

### 16.1 Save Data
- Multiple save slots
- Per-slot data:
  - XP total and spent
  - Mod inventory (per slot, with rarity)
  - Equipped mod loadout
  - Purchased skills
  - Army upgrades unlocked
  - Unlocked palettes
  - Global progression points
  - Lifetime stats (kills, headshots, shots, extractions, deaths, phases reached, etc.)
  - Per-level stats (runs, extractions, deaths, best phase, best score, etc.)

### 16.2 Migration
- Save system version with automatic migration from previous versions

---

## 17. References & Inspirations

| Game | Inspiration |
|------|-------------|
| Sniper Elite | Satisfying sniping mechanics, bullet physics, long-range gameplay |
| Slay the Spire | Roguelike item loss/gain, risk/reward per run, relic system (→ mods) |
| Hades | Meta-progression, hub between runs, always-progressing feel |
| Kingdom (Two Crowns) | Castle defense from an elevated position, watching your army fight |
| They Are Billions | Escalating siege defense, base HP as fail condition |
| Neon White | Clean minimal aesthetic, bold accent colors, snappy UI |
| Return of the Obra Dinn | Monochrome + grain atmosphere |
| Totally Accurate Battle Simulator | Chaotic battlefield as spectacle (inspiration for battlefield feel) |
| Rogue Legacy | Permanent upgrades across roguelike runs, progressive power growth |

---

## Appendix A: Removed Systems
The following systems from the original "Sniper Extraction" design are removed in this pivot:

| System | Reason |
|--------|--------|
| Credits/money currency | Replaced by score-based mod drops |
| Ammo types (AP, shock, etc.) | Simplified to fixed bullet count |
| Ammo shop | No longer needed |
| Mod shop (purchase with credits) | Mods earned through extraction |
| Hand-crafted mod catalog | Replaced by procedural mod generation |
| Level entry fees | Levels are free (risk is mod loss) |
| Run timer (5-min hard cap) | Replaced by escalation capped at phase 20 |
| Enemy detection/alert AI | Warriors don't detect player; ranged enemies simply target player |
| NPC civilians/laborers/technicians | Replaced by friendly warriors |
| Contracts (pre-run selection) | Replaced by in-run opportunities |
| Industrial/modern setting | Replaced by medieval battlefield |
| Extensive repositioning across large maps | Player operates on castle walls, movement is local |
| Sound-based enemy alerting | Removed (no stealth system) |
| Suppressor barrel mods | Removed (no sound detection) |
| Always-available extraction points | Replaced by timed extraction windows |
| Distance bonus scoring | Removed (range is constant from castle walls) |
| Rookie warrior type | Cut — swordsmen start from phase 1 instead |
| Directional shield armor | Cut — shield-bearers replaced by high-HP types |
| War Banner destructible | Cut — simplified destructible roster |
| Eagle Eye skill | Cut — threat scanning is core player skill |
| Overcast weather | Cut — clear, fog, rain only |
| Treasure Cart / Supply Drop / Duel opportunities | Deferred — 4 core opportunity types ship first |
| Zipline Runner skill | Deferred with ziplines |
