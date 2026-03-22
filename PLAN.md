# Sniper Extraction — Development Plan

Legend: `[ ]` not started · `[~]` in progress · `[x]` done

---

## Feature Status

| Area                | Progress | Next Action                              |
|---------------------|----------|------------------------------------------|
| FPS Mechanics       | █████ 100%| Complete                                 |
| Run Lifecycle       | █████ 100%| Complete                                 |
| Level Platform      | █████ 100%| Complete (loader moved to Phase 2)       |
| Enemies             | █████ 100%| Complete (extra types deferred)           |
| Danger & Reward     | █████ 100%| Complete (phase-gating deferred)         |
| HUD                 | █████ 100%| Complete (trackers added with F7)        |
| Save System (core)  | █████ 100%| Complete (stats tracking in Step 6)      |
| Objectives          | ░░░░░  0% | Contracts, optional objectives           |
| Global Progression  | ░░░░░  5% | Currency flow, upgrades, skills          |
| World Population    | ░░░░░  0% | Neutral NPCs, destructible targets       |
| UI & Menus          | ░░░░░ 10% | Main menu, pause, hub screens            |
| Content             | ░░░░░ 10% | Levels, models, props                    |
| Art & Audio         | ░░░░░  5% | Art pipeline, sounds, music              |
| Polish & Release    | ░░░░░  0% | Steam, controller, balancing             |

---

## Build Order

Features are completed top-to-bottom. Each feature is worked to 100% before
moving to the next. Items within a feature can be done in any order.

### Phase 1 — Complete the Core Loop
Finish everything needed for a single satisfying run from hub to extraction.

### Phase 2 — Progression & Depth
Give runs meaning beyond a single session.

### Phase 3 — Content & Population
Fill the world with variety.

### Phase 4 — Leftovers
Parking lot for deferred items — not blocking, not forgotten.

### Phase 5 — Polish & Ship
Make it look, sound, and feel great. Ship it.

---

## Phase 1 — Complete the Core Loop ✅

All features complete. Bug-audited and refactored.

<details>
<summary>F1. FPS Mechanics — Movement, weapon, shooting, lives, interactions</summary>

- Movement: WASD, sprint, jump, crouch, slide, ziplines
- Weapon: bolt-action sniper, scope zoom, inspect animation
- Shooting: projectile bullets, drop, sway, hold breath, reload, auto-reload
- 5 ammo types: Standard, AP, High-Damage, Shock (stun), Golden — colored tracers
- Lives system: limited per run, any hit costs one life, death = lose credits
- Interactions: look + E, zipline attach/detach

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/player/player.gd` | Player controller: movement, crouch/slide, zipline, interaction, HUD updates |
| `scripts/player/weapon.gd` | Weapon state machine: scope, bolt cycle, reload, ammo types, sway, breath |
| `scripts/projectile/bullet.gd` | Projectile physics: velocity, gravity, collision, tracer visuals, sound propagation |
| `scripts/data/ammo_type.gd` | AmmoType resource: damage, velocity, penetration, shock, color, cost |
| `scripts/systems/interactable.gd` | Base class for interactive objects |
| `data/ammo/*.tres` | 5 ammo type definitions |
| `scenes/player/player.tscn` | Player scene (CharacterBody3D, head, camera, weapon, HUD) |
| `scenes/projectile/bullet.tscn` | Bullet scene (CharacterBody3D, mesh) |

</details>

<details>
<summary>F2. Run Lifecycle — State machine, timer, extraction, result screen</summary>

- State machine: HUB → DEPLOYING → IN_RUN → EXTRACTING → RESULT
- Run timer with countdown, forced death at zero
- Threat clock: EARLY → MID → LATE phases with configurable durations
- Enemy spawner: dynamic spawns per threat phase
- Extraction: hold E + progress bar, frozen movement, damage cancels
- Result screen: stats (kills, accuracy, time, longest kill), credits/XP, press E to continue
- Death screen: same layout, red title, credits lost

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/systems/run_manager.gd` | Autoload singleton: game state, lives, timer, threat phases, credits/XP, extraction, kill bonuses |
| `scripts/world/extraction_zone.gd` | Area3D trigger: hold E to extract, cancel on leave/damage |
| `scripts/world/enemy_spawner.gd` | Dynamic enemy spawning per threat phase, hidden spawn selection |
| `scripts/ui/extraction_bar.gd` | HUD extraction progress bar |
| `scripts/ui/run_result_screen.gd` | Full-screen result overlay with stats |
| `scripts/ui/kill_feed.gd` | Kill notification with distance/headshot bonuses |
| `scenes/world/extraction_zone.tscn` | Extraction zone scene (Area3D, mesh, label) |

</details>

<details>
<summary>F3. Enemies (Core) — Detection, AI, Lookout type</summary>

- LOS detection: FOV cone + range + raycast occlusion
- Alert states: UNAWARE → SUSPICIOUS → ALERT → SEARCHING with scan behavior
- Sound reaction: gunshots and bullet impacts alert nearby enemies
- Combat: projectile shooting with accuracy spread, reaction delay
- Scope glint: bright billboard sprite visible at range when ALERT
- Laser sight: short fading beam showing aim direction
- Armor: reduces non-AP damage by 75%, AP penetrates
- Stun: shock ammo freezes enemy with blue tint, recovers after duration
- Debug: FOV cone + state indicator (toggled via show_debug export)

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/enemy/enemy_base.gd` | EnemyBase class: AI state machine, LOS, combat, glint, laser, stun, armor, death |
| `scripts/enemy/enemy_lookout.gd` | Lookout type: stationary, weak stats, overrides EnemyBase exports |
| `scenes/enemy/enemy_lookout.tscn` | Lookout scene (CharacterBody3D, mesh, head marker, sight ray) |

</details>

<details>
<summary>F4. Level Platform — Framework, spawning, variation, environment</summary>

- BaseLevel: auto-finds player, spawns enemies, picks extraction zone, applies environment
- LevelData resource: name, scene path, enemy pool, phase config, time/weather options
- SpawnPoint markers with type (PLAYER, ENEMY, EXTRACTION) and facing direction
- Run variation: random enemy subset, random extraction zone, level slots, events
- Time of day: morning, day, evening, night (sun color/angle/energy, sky colors)
- Weather: clear, snow, rain, overcast (fog density, visibility multiplier)
- Visibility affects enemy sight range (fog halves it, night reduces by 40%)

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/world/base_level.gd` | Level orchestrator: player placement, spawn variation, environment setup |
| `scripts/world/level_data.gd` | LevelData resource: metadata, enemy pool, phase config, environment options |
| `scripts/world/spawn_point.gd` | Marker3D with type enum and facing direction |
| `scripts/world/environment_config.gd` | Static presets for time of day and weather |
| `scripts/world/enemy_pool.gd` | Weighted random enemy selection with max-per-run caps |
| `scripts/world/enemy_pool_entry.gd` | Pool entry: scene, weight, max_per_run |
| `scripts/world/level_event_data.gd` | Event data: probability, timing, script |
| `scripts/world/level_event_runner.gd` | Runs timed events during a run |
| `scripts/world/level_slot.gd` | Slot for swappable level chunks |
| `scripts/world/level_slot_data.gd` | Slot data: variant scenes array |
| `scripts/world/industrial_yard_builder.gd` | Procedural greybox builder for Industrial Yard |
| `scripts/world/industrial_yard_level.gd` | Industrial Yard level script |
| `data/levels/*.tres` | Level data and enemy pool resources |
| `scenes/levels/industrial_yard.tscn` | Industrial Yard level scene |
| `scenes/dev/dev_test.tscn` | Dev test level scene |

</details>

<details>
<summary>F5. Danger & Reward — Threat phases, distance/headshot bonuses</summary>

- Threat clock: EARLY → MID → LATE based on elapsed time
- Dynamic spawning ramps up with phase (configurable intervals and max counts)
- Distance bonus: 1.5x at 100m, 2.0x at 150m, 3.0x at 200m+
- Headshot bonus: 2x, stacks with distance (headshot at 200m = 6x)
- Kill feed: shows enemy type, distance, multipliers, total credits
- Threat phase indicator on HUD

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/systems/run_manager.gd` | Threat phase updates, distance/headshot multiplier calculation |
| `scripts/world/enemy_spawner.gd` | Phase-aware spawn intervals and limits |
| `scripts/ui/kill_feed.gd` | Kill notification display |

</details>

**HUD files (shared across features):**
| File | Purpose |
|------|---------|
| `scenes/ui/hud.tscn` | HUD scene: crosshair, scope overlay, weapon state, lives, timer, threat, kill feed, extraction bar, result screen |
| `scripts/ui/crosshair.gd` | Dynamic crosshair |
| `scripts/ui/scope_overlay.gd` | Scope zoom black mask |
| `scripts/ui/breath_meter.gd` | Hold-breath meter |

**Hub files:**
| File | Purpose |
|------|---------|
| `scripts/hub/hub.gd` | Hub controller: deploy board, ammo crate, save terminal |
| `scripts/hub/deploy_board.gd` | Level selection UI |
| `scenes/hub/hub.tscn` | Hub scene |

**Save system:**
| File | Purpose |
|------|---------|
| `scripts/systems/save_manager.gd` | Autoload: save/load, credits, XP, stats, multiple slots |

---

## Phase 2 — Progression & Depth

Build order: foundation systems first (currency, ammo, menus), then spend
systems (upgrades, skills), then goals (contracts, objectives), then UI
screens that display it all. Each sub-feature is self-contained and testable.

### Step 1 — Currency & Ammo Economy (foundation for all spending)

#### F6.1 Currency & Resources [ ]
- [ ] Credits flow: run → extraction → save (already partially working)
- [ ] Experience flow: run → always saved
- [ ] Currency storage in global save
- [ ] Currency display in hub

#### F6.4 Ammo Economy [ ]
- [ ] Ammo purchasing with credits at hub
- [ ] Hub ammo inventory (stored between runs)
- [ ] Pre-run ammo selection (choose type + amount to bring)
- [ ] Advanced ammo types unlocked through progression
- [ ] Ammo lost on death, unused ammo returned on extraction

### Step 2 — Core Menus (independent, unblocks testing)

#### F8.2 Menus [ ]
- [ ] Main menu (new game, continue, settings, quit)
- [ ] Save slot selection screen (create, load, delete slots)
- [ ] Pause menu (resume, settings, abandon run)
- [ ] Settings (controls, audio, video, sensitivity)

### Step 3 — Weapon Upgrades (primary credit sink)

#### F6.2 Weapon Upgrades [ ]
- [ ] Barrel (bullet velocity)
- [ ] Stock (sway reduction)
- [ ] Bolt (reload speed)
- [ ] Magazine (capacity)
- [ ] Scope (zoom levels, reticles, clarity)
- [ ] Visual model per upgrade tier on rifle
- [ ] Upgrade UI (spend credits, preview parts)

### Step 4 — Player Skills (secondary XP sink)

#### F6.3 Player Skill Unlocks [ ]
- [ ] Skill tree (spend XP to unlock passive abilities)
- [ ] Longer hold breath
- [ ] Faster zipline traversal
- [ ] Faster reload
- [ ] Extra life
- [ ] Skill UI in hub

### Step 5 — Contracts & Objectives (give runs purpose)

#### F7.1 Contracts [ ]
- [ ] Contract board in hub (pick one contract before deploying)
- [ ] Contract types: eliminate high-value target, destroy target, accuracy challenge
- [ ] Bonus currency/XP reward on completion

#### F7.2 In-Run Objectives [ ]
- [ ] Optional objectives (all headshots, no alerts, extract before mid-phase, no missed shots, no civilian casualties)
- [ ] Bonus rewards for completing optional objectives

### Step 6 — Stats & Level Unlocks (progression gates)

#### F9.2 Stats Tracking [x]
- [x] Lifetime stats (total runs, kills, headshots, extractions, deaths, shots fired/hit)
- [x] Accuracy stats (overall accuracy %, headshot %)
- [x] Best records (survival time, credits in one run, kills in one run, longest kill distance)
- [x] Per-level stats (runs, extractions, deaths, kills, best time, best credits)

#### F6.6 Level Unlocks [ ]
- [ ] Progression gates (extraction count or currency/XP thresholds)
- [ ] Hub level select (locked/unlocked, requirements shown)

### Step 7 — Cosmetics (optional spend path, low priority)

#### F6.5 Cosmetics [ ]
- [ ] Rifle skins (visual overlays on top of upgrade parts)
- [ ] Cosmetics UI in hub (preview, equip)

### Step 8 — Hub UI (screens for all the above systems)

#### F8.3 Hub UI [ ]
- [ ] Hub navigation
- [ ] Contract board (browse, pick one)
- [ ] Weapon upgrades screen (visible rifle parts, spend credits)
- [ ] Skill tree screen (spend XP, unlock abilities)
- [ ] Cosmetics screen (rifle skins, preview, equip)
- [ ] Level select (locked/unlocked, requirements, best stats)
- [ ] Loadout screen (ammo type + amount selection)
- [ ] Stats screen (lifetime stats, records, per-level stats)

---

### Already Complete

#### F8.1 HUD [x]
- [x] Crosshair
- [x] Weapon state + credits display
- [x] Lives indicator (hearts)
- [x] Run timer
- [x] Threat phase indicator
- [x] Kill feed
- [x] Breath meter
- [x] Extraction progress bar
> Contract tracker and objective tracker will be added when F7 is built.

#### F9.1 Local Save [x]
- [x] Save data structure (credits, XP, ammo inventory, upgrades, skills, unlocks, stats)
- [x] File I/O (read/write to user data directory)
- [x] Auto-save (after each extraction and hub purchase)
- [x] Multiple save slots

---

## Phase 3 — Content & Population

### F10. World Population ░░░░░ 0%

#### F10.1 Neutral NPCs [ ]
- [ ] NPC spawning and patrol routes (workers, civilians)
- [ ] Panic/flee reaction to gunfire
- [ ] Currency penalty for killing neutral NPCs

#### F10.2 Non-NPC Targets [ ]
- [ ] Destructible objects (vehicles, equipment, supply caches)
- [ ] Static and moving targets
- [ ] Credit reward on destruction

#### F10.3 Events System [ ]
- [ ] Event types TBD — designed in detail when reached

---

### F11. Content Production ░░░░░ 10%

#### F11.1 Levels [~]
- [~] Industrial Yard (greybox done, needs art pass)
- [ ] Level 2 — TBD theme (castle/fortress?)
- [ ] Level 3 — TBD theme (urban rooftops?)
- [ ] Level 4+ — as needed for progression gates
> Each level needs: theme, 200m+ map, 2-3 wind corridors, sniper nests, repositioning routes, 15-20 enemy spawns, 2-3 extraction zones

#### F11.2 Contracts [ ]
- [ ] Contract templates per level (eliminate HVT, destroy target, accuracy challenge)
- [ ] Contract reward balancing
- [ ] Contract board variety (enough to feel fresh across runs)

#### F11.3 Enemy Visuals [ ]
- [ ] Lookout model (replace capsule placeholder)
- [ ] Marksman model (distinct silhouette — backpack, mid-weight)
- [ ] Countersniper model (scope glint visible at range, lean profile)
- [ ] Heavy Sniper model (bulky, armored, reads as tough)
- [ ] Elite Sniper model (tactical gear, smoke grenades visible)

#### F11.4 Props & Environment Art [ ]
- [ ] Reusable building kit (walls, roofs, floors, stairs, railings)
- [ ] Industrial props (crates, barrels, containers, pallets, pipes)
- [ ] Vehicles (trucks, cars — destructible targets)
- [ ] Equipment (generators, radios, supply caches — destructible targets)
- [ ] Cover objects (sandbags, concrete barriers, scaffolding)
- [ ] Vegetation (trees, bushes — sight blockers at range)

#### F11.5 VFX [ ]
- [ ] Muzzle flash (player + enemy)
- [ ] Bullet tracer trail
- [ ] Hit impact — surface-dependent (metal spark, dirt puff, wood splinter)
- [ ] Headshot effect
- [ ] Scope glint shimmer
- [ ] Extraction zone effect (glow / particle ring)
- [ ] Death/down effect (enemy ragdoll or collapse)
- [ ] Smoke grenade (for Elite Sniper)
- [ ] Weather particles (rain, fog volume)

#### F11.6 Audio Assets [ ]
- [ ] Player — rifle shot, bolt cycle, reload, dry fire, scope zoom
- [ ] Player — footsteps per surface (metal, concrete, wood, dirt)
- [ ] Bullet — impact per surface (metal, ground, wood, flesh)
- [ ] Enemy — alert callout, search callout, death sound
- [ ] Environment — ambient per level theme, time-of-day variation
- [ ] Music — tension tracks that build with threat phase
- [ ] UI — menu clicks, extraction countdown, objective complete, deploy whoosh

#### F11.7 UI Screens [ ]
- [ ] Main menu (new game, continue, settings, quit)
- [ ] Save slot selection
- [ ] Hub layout (navigate between boards/screens)
- [ ] Contract board
- [ ] Weapon upgrades screen (rifle preview + parts)
- [ ] Skill tree screen
- [ ] Cosmetics screen
- [ ] Loadout / ammo selection
- [ ] Level select
- [ ] Stats screen
- [ ] Pause menu
- [ ] Death screen
- [ ] Run result screen
- [ ] Settings (controls, audio, video)

---

## Phase 4 — Leftovers

Items moved here from other phases — not blocking progress, but tracked for
later. Pull items back into active phases when/if they become relevant.

### Additional Enemy Types (from F3.2)
- [ ] Marksman (repositions between nests, medium awareness, decent accuracy)
- [ ] Countersniper (scope glint visible, actively scans for player, accurate and fast)
- [ ] Heavy Sniper (armored, requires AP ammo or headshot, high damage)
- [ ] Elite Sniper (flanks to different nests, uses smoke/repositioning)

### Per-Run Variation Extras (from F4.2)
- [ ] Color palette variation per run
- [ ] Variable sniper positions (some nests blocked/revealed per run)

### Phase-Gated Rewards (from F2.3, F5)
- [ ] Higher-value targets gated behind later phases
- [ ] Phase-specific enemy type pools (tougher enemies in LATE)
- [ ] Spawn multiplier for credit/XP based on threat phase

---

## Phase 5 — Polish & Ship

### F12. Art & Audio ░░░░░ 5%
- [ ] Low-poly stylized art pipeline (flat/minimal shading, clean geometry)
- [ ] Color palette per level (accent colors for enemies, objectives, extraction)
- [ ] Environment art (blocky architecture, contrasting floor levels, fog/haze)
- [ ] Weapon model (sniper rifle with visible upgrade parts)
- [ ] Enemy models (distinct silhouettes per type, scope glint effect)
- [ ] Neutral NPC models
- [ ] Non-NPC target models (vehicles, equipment, supply caches)
- [ ] Time of day lighting (morning, day, evening, night)
- [ ] Weather effects (fog, rain, overcast)
- [ ] All audio assets integrated and balanced

### F13. Steam & Release ░░░░░ 0%
- [ ] GodotSteam plugin
- [ ] Steam Cloud save sync
- [ ] Achievements (first extraction, kill milestones, accuracy milestones, etc.)
- [ ] Controller support
- [ ] Localization (multiple languages)
- [ ] Accessibility options (colorblind mode, subtitles, input remapping)
- [ ] Performance profiling (target 60fps)
- [ ] Playtesting (balance danger curve, ammo economy, weapon feel)
- [ ] Bug fixing pass
- [ ] Trailer / marketing materials
- [ ] Steam store page
- [ ] Launch build & Steam upload

---

## Workflow

1. **Pick next feature** from current phase
2. **Explain approach** — implementation plan, dependencies
3. **Discuss and agree** — check against other features for compatibility
4. **Implement** — clean code, signals and interfaces for future systems
5. **Test in-game** — verify it works before moving on
6. **Check off** — update feature status and progress bar
7. **Feature complete?** — sync check against GDD, update both documents if needed
8. **Next feature**

**Principles:**
- Finish features to 100% before moving on
- Always think ahead — early systems should emit signals and use interfaces that later systems can connect to
- If something doesn't work in practice, update both GDD and PLAN together
- No broken foundations — test before building on top
- Content and art can be worked in parallel once systems are done
