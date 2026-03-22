# Sniper Extraction — Development Plan

Legend: `[ ]` not started · `[~]` in progress · `[x]` done

---

## Feature Status

| Area                | Progress | Next Action                              |
|---------------------|----------|------------------------------------------|
| FPS Mechanics       | █████ 100%| Complete                                 |
| Run Lifecycle       | █████ 95% | Higher-value targets in later phases     |
| Level Platform      | ███░░ 60% | Level loader, per-run variation          |
| Enemies             | ██░░░ 40% | Detection + Lookout done; types deferred |
| Danger & Reward     | ███░░ 70% | Higher-value targets in later phases     |
| Objectives          | ░░░░░  0% | Contracts, optional objectives           |
| Global Progression  | ░░░░░  5% | Currency flow, upgrades, skills          |
| World Population    | ░░░░░  0% | Neutral NPCs, destructible targets       |
| UI & Menus          | █░░░░ 30% | Main menu, pause, result screens         |
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

## Phase 1 — Complete the Core Loop

### F1. FPS Mechanics █████ 100%

#### F1.1 Movement [x]
- [x] WASD + mouse look
- [x] Gravity + floor detection
- [x] Sprint
- [x] Jump
- [x] Crouch
- [x] Slide (sprint + crouch)
- [x] Ziplines (approach + E to attach/detach)

#### F1.2 Weapon — Sniper Rifle [x]
- [x] Sniper rifle (bolt-action, scope zoom)
- [x] Weapon inspect animation (dedicated key, shows rifle + equipped skin)

#### F1.3 Shooting [x]
- [x] Projectile-based bullets
- [x] Bullet lifetime and collision
- [x] Bullet drop & travel time
- [x] Scope sway / hold breath to steady
- [x] Reload mechanic
- [x] Ammo types (Standard, AP, High-Damage, Shock, Golden — colored tracers, armor, stun)
- [x] Auto-reload when magazine empty
- [x] Stay scoped through bolt cycle

#### F1.4 Player Lives [x]
- [x] Lives system (limited lives per run, any enemy hit costs one life)
- [x] Death state (all lives lost = run failure, credits + ammo lost, XP kept)

#### F1.5 Interactions [x]
- [x] Interaction system (look at object, press E)
- [x] Zipline attach/detach

---

### F2. Run Lifecycle █████ 95%

#### F2.1 Run State Machine [x]
- [x] Run state machine (HUB → DEPLOYING → IN_RUN → EXTRACTING → RESULT)
- [x] Hub → level transition with loading screen
- [x] Run timer (countdown, forced death at zero)
- [x] Death handling (lives ≤ 0, lose all credits + ammo)

#### F2.2 Escalating Danger [x]
- [x] Threat clock (elapsed time → phase signals: early/mid/late)
- [x] Enemy spawner (listens to threat phase)
- [x] Phase config (spawn rates, enemy types per phase)

#### F2.3 Risk / Reward Curve [~]
- [x] Credit accumulation system (enemy kills + distance/headshot bonuses)
- [ ] Higher-value targets gated behind later phases
- [x] Credits lost on death, kept on extraction

#### F2.4 Extraction [x]
- [x] Single extraction point per level (fixed location)
- [x] Extraction channel (hold E, progress bar, interrupted by damage)
- [x] Player frozen during extraction (can look, can't move)
- [x] Extraction success (transfer credits + unused ammo to global save, show result screen)

#### F2.5 Run Result [x]
- [x] Run result screen (enemies eliminated, accuracy, time survived, longest kill, credits earned/lost, XP earned)
- [x] Death screen (same layout, red title, credits lost)
- [x] Press E to return to hub

---

### F3. Enemies (Core) ██░░░ 40%

#### F3.1 Detection System [x]
- [x] Line of sight + sound reaction (gunshots, impacts, ally eliminations)
- [x] Alert states (Unaware → Suspicious → Alert → Searching)
- [x] Scope glint / laser sight on enemies (visible warning to player)

#### F3.2 Enemy Types (Core) [x]
- [x] EnemyBase class (state machine, LOS, combat, sound, debug visuals)
- [x] Lookout (basic sniper, stationary, low awareness, slow reaction)
- [x] Armor system (is_armored flag, AP penetration)
- [x] Stun system (shock ammo, blue tint visual)
> Remaining enemy types moved to Phase 4 — Lookout is sufficient for core loop

---

### F4. Level Platform ███░░ 60%

#### F4.1 Level Framework [~]
- [x] Base level scene (terrain, spawn points, extraction zone, lighting)
- [x] Level data (name, difficulty, available phases)
- [x] Enemy spawner and pool system
- [x] Run variation infrastructure (slot system, extraction randomization, event runner)
- [ ] Level loader (pick level based on progression)

#### F4.2 Per-Run Variation [~]
- [x] Randomized enemy spawn subset
- [x] Randomized extraction zone selection
- [ ] Time of day selection (morning, day, evening, night)
- [ ] Weather selection (clear, fog, rain, overcast)
> Color palette variation and variable sniper positions moved to Phase 4

---

### F5. Danger & Reward ███░░ 70%

- [x] Threat clock with phase transitions (EARLY → MID → LATE)
- [x] Dynamic enemy spawning per phase
- [x] Distance-based credit multiplier (1.5x at 100m, 2x at 150m, 3x at 200m+)
- [x] Headshot bonus (2x, stacks with distance)
- [x] Kill feed HUD with distance, bonuses, credits
- [x] Threat phase indicator on HUD
- [ ] Higher-value targets gated behind later phases
- [ ] Phase-specific enemy type pools (tougher enemies in LATE)

---

## Phase 2 — Progression & Depth

### F6. Global Progression ░░░░░ 5%

#### F6.1 Currency & Resources [ ]
- [ ] Credits flow: run → extraction → save (already partially working)
- [ ] Experience flow: run → always saved
- [ ] Currency storage in global save
- [ ] Currency display in hub

#### F6.2 Weapon Upgrades [ ]
- [ ] Barrel (bullet velocity)
- [ ] Stock (sway reduction)
- [ ] Bolt (reload speed)
- [ ] Magazine (capacity)
- [ ] Scope (zoom levels, reticles, clarity)
- [ ] Visual model per upgrade tier on rifle
- [ ] Upgrade UI (spend credits, preview parts)

#### F6.3 Player Skill Unlocks [ ]
- [ ] Skill tree (spend XP to unlock passive abilities)
- [ ] Longer hold breath
- [ ] Faster zipline traversal
- [ ] Faster reload
- [ ] Extra life
- [ ] Skill UI in hub

#### F6.4 Ammo Economy [ ]
- [ ] Ammo purchasing with credits at hub
- [ ] Hub ammo inventory (stored between runs)
- [ ] Pre-run ammo selection (choose type + amount to bring)
- [ ] Advanced ammo types unlocked through progression
- [ ] Ammo lost on death, unused ammo returned on extraction

#### F6.5 Cosmetics [ ]
- [ ] Rifle skins (visual overlays on top of upgrade parts)
- [ ] Cosmetics UI in hub (preview, equip)

#### F6.6 Level Unlocks [ ]
- [ ] Progression gates (extraction count or currency/XP thresholds)
- [ ] Hub level select (locked/unlocked, requirements shown)

---

### F7. Objectives & Contracts ░░░░░ 0%

#### F7.1 Contracts [ ]
- [ ] Contract board in hub (pick one contract before deploying)
- [ ] Contract types: eliminate high-value target, destroy target, accuracy challenge
- [ ] Bonus currency/XP reward on completion

#### F7.2 In-Run Objectives [ ]
- [ ] Optional objectives (all headshots, no alerts, extract before mid-phase, no missed shots, no civilian casualties)
- [ ] Bonus rewards for completing optional objectives

---

### F8. UI & Menus █░░░░ 30%

#### F8.1 HUD [~]
- [x] Crosshair
- [x] Weapon state + credits display
- [x] Lives indicator (hearts)
- [x] Run timer
- [x] Threat phase indicator
- [x] Kill feed
- [x] Breath meter
- [ ] Ammo counter (type + remaining)
- [ ] Extraction progress bar
- [ ] Contract tracker
- [ ] Optional objective tracker

#### F8.2 Menus [ ]
- [ ] Main menu (new game, continue, settings, quit)
- [ ] Save slot selection screen (create, load, delete slots)
- [ ] Pause menu (resume, settings, abandon run)
- [ ] Settings (controls, audio, video, sensitivity)

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

### F9. Save System [~]

#### F9.1 Local Save [x]
- [x] Save data structure (credits, XP, ammo inventory, upgrades, skills, unlocks, stats)
- [x] File I/O (read/write to user data directory)
- [x] Auto-save (after each extraction and hub purchase)
- [x] Multiple save slots

#### F9.2 Stats Tracking [ ]
- [ ] Lifetime stats (total kills, total extractions, total deaths)
- [ ] Accuracy stats (overall accuracy, headshot percentage)
- [ ] Best records (longest survival, most credits in one run)
- [ ] Per-level stats (times completed, best stats)
- [ ] Stats screen accessible from hub

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
