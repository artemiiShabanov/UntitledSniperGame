# Sniper Extraction — Development Plan

Legend: `[ ]` not started · `[~]` in progress · `[x]` done

---

## 1. Core FPS Mechanics

### 1.1 Movement
- [x] WASD + mouse look
- [x] Gravity + floor detection
- [x] Sprint
- [x] Jump
- [x] Crouch
- [x] Slide (sprint + crouch)
- [ ] Ziplines (approach + E to attach/detach)
> **Depends on:** nothing (foundation layer)
> **Priority:** high

### 1.2 Weapon — Sniper Rifle
- [ ] Sniper rifle (bolt-action, scope zoom)
- [ ] Weapon inspect animation (dedicated key, shows rifle + equipped skin)
> **Depends on:** 1.1
> **Priority:** high

### 1.3 Shooting
- [ ] Projectile-based bullets
- [ ] Bullet lifetime and collision
- [ ] Bullet drop & travel time
- [ ] Scope sway / hold breath to steady
- [ ] Reload mechanic
- [ ] Ammo types (standard, armor-piercing, high-damage — different damage and penetration)
> **Depends on:** 1.2
> **Priority:** high

### 1.4 Player Lives
- [ ] Lives system (limited lives per run, any enemy hit costs one life)
- [ ] Death state (all lives lost = run failure, credits + ammo lost, XP kept)
> **Depends on:** 1.1
> **Priority:** high

### 1.5 Interactions
- [ ] Interaction system (look at object, press E)
- [ ] Zipline attach/detach
> **Depends on:** 1.1
> **Priority:** medium

---

## 2. Extraction Run Structure

### 2.1 Run Lifecycle
- [ ] Run state machine (HUB → DEPLOYING → IN_RUN → EXTRACTING → RESULT)
- [ ] Hub → level transition with loading screen
- [ ] Run timer (countdown, forced death at zero)
- [ ] Death handling (lives ≤ 0, lose all credits + ammo)
> **Depends on:** 1.1, 1.3
> **Priority:** high

### 2.2 Escalating Danger
- [ ] Threat clock (elapsed time → phase signals: early/mid/late)
- [ ] Enemy spawner (listens to threat phase)
- [ ] Phase config (spawn rates, enemy types per phase)
> **Depends on:** 2.1, 4
> **Priority:** high

### 2.3 Risk / Reward Curve
- [ ] Credit accumulation system (enemy kills + destroyed targets + contract bonus)
- [ ] Higher-value targets gated behind later phases
- [ ] Credits lost on death, kept on extraction
> **Depends on:** 2.2
> **Priority:** medium

### 2.4 Extraction
- [ ] Single extraction point per level (fixed location)
- [ ] Extraction channel (hold E, progress bar, interrupted by damage or movement)
- [ ] Extraction success (transfer credits + unused ammo to global save, show result screen)
> **Depends on:** 2.1, 2.3
> **Priority:** high

---

## 3. Level System

### 3.1 Level Framework
- [ ] Base level scene (terrain, spawn points, extraction zone, lighting)
- [ ] Level data (name, difficulty, available phases)
- [ ] Level loader (pick level based on progression)
> **Depends on:** 2.1
> **Priority:** high
> **Note:** detailed map designs in a separate plan

### 3.2 Per-Run Variation
- [ ] Randomized spawn points (enemies, targets)
- [ ] Time of day selection (morning, day, evening, night)
- [ ] Weather selection (clear, fog, rain, overcast)
- [ ] Color palette variation per run
- [ ] Variable sniper positions (some nests blocked/revealed per run)
> **Depends on:** 3.1
> **Priority:** medium

---

## 4. Enemy AI

### 4.1 Detection System
- [ ] Line of sight + sound reaction (gunshots, impacts, ally eliminations)
- [ ] Alert states (Unaware → Suspicious → Alert → Searching)
- [ ] Scope glint / laser sight on enemies (visible warning to player)
> **Depends on:** 1.3, 3.1
> **Priority:** high

### 4.2 Enemy Types
- [ ] Lookout (basic sniper, stationary, low awareness, slow reaction)
- [ ] Marksman (repositions between nests, medium awareness, decent accuracy)
- [ ] Countersniper (scope glint visible, actively scans for player, accurate and fast)
- [ ] Heavy Sniper (armored, requires AP ammo or headshot, high damage)
- [ ] Elite Sniper (flanks to different nests, uses smoke/repositioning)
> **Depends on:** 4.1
> **Priority:** high

---

## 5. Neutral NPCs
- [ ] NPC spawning and patrol routes (workers, civilians)
- [ ] Panic/flee reaction to gunfire
- [ ] Currency penalty for killing neutral NPCs
> **Depends on:** 3.1
> **Priority:** medium

---

## 6. Non-NPC Targets
- [ ] Destructible objects (vehicles, equipment, supply caches)
- [ ] Static and moving targets
- [ ] Credit reward on destruction
> **Depends on:** 3.1
> **Priority:** medium

---

## 7. Events System
- [ ] TBD — to be designed in detail later
> **Depends on:** 2.2, 3.1
> **Priority:** medium

---

## 8. Global Progression

### 8.1 Currency & Resources
- [ ] Credits (accumulated per run from kills/targets/contracts, kept on extraction, lost on death)
- [ ] Experience (earned every run, never lost)
- [ ] Currency storage in global save
> **Depends on:** 2.4, 10.1
> **Priority:** medium

### 8.2 Weapon Upgrades (credits, visible rifle parts)
- [ ] Barrel (bullet velocity)
- [ ] Stock (sway reduction)
- [ ] Bolt (reload speed)
- [ ] Magazine (capacity)
- [ ] Scope (zoom levels, reticles, clarity)
- [ ] Visual model per upgrade tier on rifle
- [ ] Upgrade UI (spend credits, preview parts)
> **Depends on:** 8.1, 1.2
> **Priority:** medium

### 8.3 Player Skill Unlocks (XP)
- [ ] Skill tree (spend XP to unlock passive abilities)
- [ ] Longer hold breath
- [ ] Faster zipline traversal
- [ ] Faster reload
- [ ] Extra life
- [ ] Skill UI in hub
> **Depends on:** 8.1
> **Priority:** medium

### 8.4 Ammo Economy
- [ ] Ammo purchasing with credits at hub
- [ ] Hub ammo inventory (stored between runs)
- [ ] Pre-run ammo selection (choose type + amount to bring)
- [ ] Advanced ammo types unlocked through progression
- [ ] Ammo lost on death, unused ammo returned on extraction
> **Depends on:** 8.1, 1.3
> **Priority:** medium

### 8.5 Cosmetics
- [ ] Rifle skins (visual overlays on top of upgrade parts, unlock with currency or XP milestones)
- [ ] Cosmetics UI in hub (preview, equip)
> **Depends on:** 8.1, 1.2
> **Priority:** low

### 8.6 Level Unlocks
- [ ] Progression gates (extraction count or currency/XP thresholds)
- [ ] Hub level select (locked/unlocked, requirements shown)
> **Depends on:** 8.1, 3.1
> **Priority:** medium

---

## 9. Objectives & Contracts

### 9.1 Contracts
- [ ] Contract board in hub (pick one contract before deploying)
- [ ] Contract types: eliminate high-value target, destroy target, accuracy challenge
- [ ] Bonus currency/XP reward on completion

### 9.2 In-Run Objectives
- [ ] Optional objectives (all headshots, no alerts, extract before mid-phase, no missed shots, no civilian casualties)
- [ ] Bonus rewards for completing optional objectives

### 9.3 Run Result
- [ ] Run result screen (enemies eliminated, accuracy, time survived, contract status, credits earned/lost, XP earned)
> **Depends on:** 2.1, 2.3
> **Priority:** medium

---

## 10. Save System

### 10.1 Local Save
- [ ] Save data structure (credits, XP, ammo inventory, upgrades, skills, unlocks, stats)
- [ ] File I/O (read/write to user data directory)
- [ ] Auto-save (after each extraction and hub purchase)
- [ ] Multiple save slots

### 10.2 Stats Tracking
- [ ] Lifetime stats (total kills, total extractions, total deaths)
- [ ] Accuracy stats (overall accuracy, headshot percentage)
- [ ] Best records (longest survival, most credits in one run)
- [ ] Per-level stats (times completed, best stats)
- [ ] Stats screen accessible from hub

### 10.3 Steam Integration
- [ ] GodotSteam plugin
- [ ] Steam Cloud save sync
- [ ] Achievements (first extraction, kill milestones, accuracy milestones, etc.)
> **Depends on:** 8.1
> **Priority:** medium (local save early, Steam later)

---

## 11. Art Direction & Visual Style
- [ ] Low-poly stylized art pipeline (flat/minimal shading, clean geometry)
- [ ] Color palette per level (accent colors for enemies, objectives, extraction)
- [ ] Environment art (blocky architecture, contrasting floor levels, fog/haze)
- [ ] Weapon model (sniper rifle with visible upgrade parts)
- [ ] Enemy models (distinct silhouettes per type, scope glint effect)
- [ ] Neutral NPC models
- [ ] Non-NPC target models (vehicles, equipment, supply caches)
- [ ] VFX (muzzle flash, bullet trail, hit impact, extraction effect)
- [ ] Time of day lighting (morning, day, evening, night)
- [ ] Weather effects (fog, rain, overcast)
> **Depends on:** core mechanics working with placeholders first
> **Priority:** low initially, ramp up after core loop works

---

## 12. Audio
- [ ] Player footstep sounds (surface-dependent: metal, concrete, wood)
- [ ] Gun sounds (shoot, reload, bolt action, dry fire)
- [ ] Impact sounds (metal, ground, wood)
- [ ] Enemy sounds (alert, searching, death, scope adjustment)
- [ ] Neutral NPC sounds (ambient chatter, panic/flee)
- [ ] Ambient (per-level atmosphere, time-of-day variation)
- [ ] Music (synth/electronic tension, builds with threat phase)
- [ ] UI sounds (menu clicks, extraction countdown, objective complete)
> **Depends on:** corresponding features implemented
> **Priority:** low-medium

---

## 13. UI & Menus

### 13.1 HUD
- [ ] Crosshair
- [ ] Ammo counter (type + remaining)
- [ ] Lives indicator
- [ ] Run timer / threat meter
- [ ] Extraction progress bar
- [ ] Contract tracker
- [ ] Optional objective tracker

### 13.2 Menus
- [ ] Main menu (new game, continue, settings, quit)
- [ ] Save slot selection screen (create, load, delete slots)
- [ ] Pause menu (resume, settings, abandon run)
- [ ] Death screen (XP earned, credits + ammo lost, return to hub)
- [ ] Run result screen (stats, contract status, credits/XP earned)
- [ ] Settings (controls, audio, video, sensitivity)

### 13.3 Hub UI
- [ ] Hub navigation
- [ ] Contract board (browse, pick one)
- [ ] Weapon upgrades screen (visible rifle parts, spend credits)
- [ ] Skill tree screen (spend XP, unlock abilities)
- [ ] Cosmetics screen (rifle skins, preview, equip)
- [ ] Level select (locked/unlocked, requirements, best stats)
- [ ] Loadout screen (ammo type + amount selection)
- [ ] Stats screen (lifetime stats, records, per-level stats)
> **Depends on:** 2.1, 8.1
> **Priority:** medium (basic HUD early, full menus later)

---

## 14. Polish & Release
- [ ] Controller support
- [ ] Localization (multiple languages)
- [ ] Accessibility options (colorblind mode, subtitles, input remapping)
- [ ] Performance profiling (target 60fps)
- [ ] Playtesting (balance danger curve, ammo economy, weapon feel)
- [ ] Bug fixing pass
- [ ] Trailer / marketing materials
- [ ] Steam store page
- [ ] Steam achievements
- [ ] Launch build & Steam upload
> **Depends on:** everything above
> **Priority:** last phase

---

## Workflow

1. **Pick next feature** from current layer
2. **Explain approach** — implementation plan, how it fits with future layers
3. **Discuss and agree** — check against future layers for compatibility
4. **Implement** — use placeholder-friendly architecture (signals, clean interfaces for later systems to hook into)
5. **Test in-game** — verify it works before moving on
6. **Check off** — mark done in both plan sections and layers
7. **Layer complete?** — sync check against GDD, update both documents if needed
8. **Next feature**

**Principles:**
- One feature at a time within a layer
- Always think ahead — early systems should emit signals and use interfaces that later systems can connect to
- If something doesn't work in practice, update both GDD and PLAN together
- No broken foundations — test before building on top

---

## Development Layers (Build Order)

Each layer depends on the previous ones. Items within the same layer can be built in parallel.

### Layer 1 — Foundation
- 1.1 Movement
- 10.1 Local Save
- 13.1 Crosshair

### Layer 2 — Core Systems
- 1.2 Weapon — Sniper Rifle
- 1.4 Player Lives
- 1.5 Interactions

### Layer 3 — Shooting
- 1.3 Shooting

### Layer 4 — Run Structure
- 2.1 Run Lifecycle

### Layer 5 — Level & Enemies
- 3.1 Level Framework
- 4.1 Detection System
- 4.2 Enemy Types

### Layer 6 — Danger & Reward
- 2.2 Escalating Danger
- 2.3 Risk / Reward Curve

### Layer 7 — Extraction & Objectives
- 2.4 Extraction
- 9 Objectives & Contracts

### Layer 8 — Progression
- 8.1 Currency & Resources
- 8.2 Weapon Upgrades
- 8.3 Player Skill Unlocks
- 8.4 Ammo Economy
- 8.5 Cosmetics
- 8.6 Level Unlocks

### Layer 9 — World Population
- 5 Neutral NPCs
- 6 Non-NPC Targets
- 7 Events System

### Layer 10 — Variation & Menus
- 3.2 Per-Run Variation
- 10.2 Stats Tracking
- 13.1 Remaining HUD elements
- 13.2 Menus
- 13.3 Hub UI

### Layer 11 — Art & Audio (parallel, ramp up after core loop)
- 11 Art Direction & Visual Style
- 12 Audio

### Layer 12 — Release
- 10.3 Steam Integration
- 14 Polish & Release
