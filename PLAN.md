# Sniper Extraction — Development Plan

Legend: `[ ]` not started · `[~]` in progress · `[x]` done

---

## Status Overview

**Completed:** Core gameplay loop, progression systems, UI/menus, palette system, hub,
save system, audio/VFX systems, 1 greybox level (Industrial Yard).

**Current phase:** Technical development & content production.

| Section | Progress | Summary |
|---------|----------|---------|
| Run Lifecycle | ██░░░ 30% | Enemy types, phase rewards, objectives, events, variation |
| Global Progression | ██░░░ 40% | Mods, contracts, palettes |
| Content | █░░░░ 20% | 1/4 levels done, placeholder art/models/audio, UI polish |
| Polish & Release | ░░░░░ 0% | Steam, controller, balancing, marketing |

---

## 1A · Run Lifecycle

Systems and mechanics active during a run.

### 1.1 Enemy Types [ ]

Only the Lookout is implemented. Four more types are designed in the GDD:

- [ ] **Marksman** — repositions between nests, medium awareness, decent accuracy
- [ ] **Countersniper** — scope glint visible, actively scans for player, accurate and fast
- [ ] **Heavy Sniper** — armored, requires AP ammo or headshot, high damage
- [ ] **Elite Sniper** — flanks to different nests, uses smoke/repositioning
- [ ] Scope glint shimmer VFX (deferred from Phase 3)

> Depends on: enemy_base.gd (ready), enemy_pool system (ready), spawn_point markers (ready)

### 1.2 Phase-Gated Rewards [ ]

Threat phases exist (EARLY/MID/LATE) but rewards don't scale with them yet.

- [ ] Phase-specific enemy type pools (tougher enemies only in MID/LATE)
- [ ] Higher-value targets gated behind later phases
- [ ] Spawn multiplier for credit/XP based on threat phase

> Depends on: run_manager.gd threat phases (ready), enemy_spawner.gd (ready)

### 1.3 In-Run Objectives [ ]

Dynamic challenges that appear during a run with bonus rewards:

- [ ] All headshots (no body shots)
- [ ] No alerts triggered (full stealth)
- [ ] Extract before mid phase (speed run)
- [ ] No missed shots (perfect accuracy)
- [ ] No civilian casualties
- [ ] HUD objective tracker
- [ ] Active contract tracker on HUD

> New system — needs objective_manager + HUD integration

### 1.4 Events System [ ]

Infrastructure exists but no events are defined:

- [ ] Event types TBD — designed in detail when needed
- [ ] LevelEventData, LevelEventRunner, level_events_pool already exist

### 1.5 Per-Run Variation [ ]

- [ ] Variable sniper positions (some nests blocked/revealed per run)
- [ ] Level layout variation (randomized props, cover, routes per run)

---

## 1B · Global Progression

Hub systems and between-run upgrades.

### 1.6 Rifle Modifications — Full Catalog [ ]

Two foundation mods exist (Long Barrel, Extended Mag). Need the rest:

- [ ] Barrel: Light Barrel, Heavy Barrel
- [ ] Stock: Padded, Breath, Competition
- [ ] Bolt: Quick, Smooth Action, Match
- [ ] Magazine: Drum Mag
- [ ] Scope: 4x, 8x, Variable (adjustable zoom + scope overlays)
- [ ] Visual model per mod on rifle viewmodel

> Depends on: RifleMod resource (ready), mod_registry (ready), mod_shop (ready), rifle_viewmodel (ready)

### 1.7 Contract Expansion [ ]

5 contract types work. Two more designed but returning false:

- [ ] KILL_TARGET — eliminate a named high-value target (target_id field exists)
- [ ] DESTROY_TARGET — destroy a specific object
- [ ] Contract templates per level
- [ ] Contract reward balancing
- [ ] Level-specific contracts (level_restriction field ready)
- [ ] Higher-risk/higher-reward contracts for harder levels

> Depends on: contract.gd (ready), contract_registry (ready), contract_panel (ready)

### 1.8 Palette Expansion [ ]

- [ ] Add more palettes with varied unlock conditions (headshot streaks, speed runs, etc.)

---

## 2 · Content

Levels, 3D models, animations, textures, audio, and UI — everything that fills the game world.

### 2.1 UI Polish [ ]

- [ ] Main menu visual polish (background pattern, version text, subtle animation)
- [ ] Hub layout — spatial navigation cues between stations
- [ ] Scope overlay — advanced reticle (mil-dots, rangefinder markings)
- [ ] Result/death screens — styled layout with animations
- [ ] Settings screen — section headers, better slider visuals

### 2.2 Levels

> Each level needs: theme, 200m+ map, 2-3 wind corridors, sniper nests, repositioning
> routes, 15-20 enemy spawns, 2-3 extraction zones, NPC activity points, destructibles.

#### Industrial Yard ✅ (greybox)
- [x] Greybox geometry (IndustrialYardBuilder)
- [x] 17 enemy spawns, 3 extraction zones, 3 ziplines
- [x] 24 NPC activity points, NPC pool (3-5 NPCs)
- [x] 8 destructible boxes
- [ ] Art pass (needs models, textures, props)

#### Level 2 — City [ ]
- [ ] Theme and layout design (rooftops, streets, alleys, long sight lines between buildings)
- [ ] Builder script with greybox geometry
- [ ] Spawn points, extraction zones, ziplines
- [ ] NPC activity points and pool (bench sitting, phone calls, sweeping)
- [ ] Destructible targets
- [ ] Level data (.tres) with unlock gates

#### Level 3 — Nature / Castle [ ]
- [ ] Theme and layout design (castle ruins, forest clearings, stone walls, watchtowers)
- [ ] Builder script with greybox geometry
- [ ] Spawn points, extraction zones, ziplines
- [ ] NPC activity points and pool (chopping wood, tending fire, patrolling)
- [ ] Destructible targets
- [ ] Level data (.tres) with unlock gates

#### Level 4+ [ ]
- [ ] As needed for progression gates

### 2.3 3D Models & Animations

> **Pipeline:** Low-poly asset packs (Kenney/Quaternius) → Mixamo auto-rig → Godot AnimationTree.
> Props: Blender box-modeling or asset packs. Strip textures, apply palette colors.

<details>
<summary>Characters (~10 models)</summary>

**Player:**
- [ ] Rifle viewmodel (replace CSG placeholder)
- [ ] First-person arms/hands (optional)

**Enemies (shared humanoid skeleton):**
- [ ] Lookout — standing, light build, no helmet
- [ ] Marksman — crouching, beret or cap
- [ ] Countersniper — prone, ghillie elements
- [ ] Heavy Sniper — bulky, heavy vest, helmet
- [ ] Elite Sniper — tactical, balaclava, tac gear

**NPCs (shared humanoid skeleton, recolored via palette):**
- [ ] Laborer — stocky, hard hat, tool belt
- [ ] Technician — medium build, clipboard, safety vest
- [ ] Civilian — varied casual, no gear

</details>

<details>
<summary>Character Animations (~25 via Mixamo)</summary>

**Enemy animations (shared):**
Idle (standing), Idle (rifle ready), Walk (patrol), Aim rifle, Shoot rifle,
Look around (suspicious), Crouch idle, Death (fall back), Death (headshot),
Stunned (shock), Prone idle, Run/reposition

**NPC animations (shared):**
Idle, Walk, Run (panic), Work (hammering), Carry box, Rest (lean/sit),
Operate (typing), Inspect (clipboard), Eat (standing), Death (collapse), Cower

**Level-specific NPC animations:**
Sitting on bench, Sweeping, Phone call, Chopping wood, Tending fire, Patrolling with torch

</details>

<details>
<summary>Props — shared (~8), hub (~7), per-level (~41)</summary>

**Shared:** Destructible crate variants, sandbag wall, concrete barrier, metal barrel,
wooden pallet, zipline pole + cable, extraction marker, rifle (world/dropped)

**Hub:** Room shell, deploy board, ammo crate, mod bench, save terminal, skill board, stats terminal

**Industrial Yard (~11):** Warehouse shell, shipping container, scaffolding, pipe runs,
forklift, chain-link fence, guard tower, loading dock, overhead crane, dumpster, crate stacks

**City (~14):** Building facades, street tiles, cars, bus/truck, traffic light, street lamp,
bench, dumpster, phone booth, rooftop AC units, water tower, fire escape, store awning, construction barrier

**Nature/Castle (~16):** Castle walls, gate, battlements, stone tower, trees, bushes,
rock formations, wooden fence, ruins, cart, hay bale, campfire, wooden bridge, well, watchtower, tent

</details>

### 2.4 Image Assets

> **Status:** 59 placeholder PNGs created, folders structured, all wired into code.
> **Sources:** game-icons.net (CC BY 3.0), Kenney Particle Pack (CC0), ambientCG (CC0)

| Category | Count | Status |
|----------|-------|--------|
| UI icons (ammo, mods, skills, contracts, killfeed, HUD, ratings) | 40 | Placeholder |
| VFX sprites (muzzle flash, impacts, smoke, shell) | 5 | Placeholder |
| UI art (logo, menu background) | 2 | Placeholder |
| Surface textures (6 materials × albedo + normal) | 12 | Placeholder |
| **Total** | **59** | |

### 2.5 Audio

> **Status:** 48 audio files loaded. Mix of sourced (Freesound/Pixabay) and generated (jsfxr).
> Many are placeholder quality — need final mixing and replacement.

| Category | Count |
|----------|-------|
| Weapon sounds | 5 |
| Impact sounds | 6 |
| Player sounds | 8 |
| UI sounds (generated) | 8 |
| World sounds | 4 |
| Ambient + music | 5 |
| Generated (jsfxr) | 14 |
| **Total** | ~48 |

---

## 3 · Polish & Release

### 3.1 Steam Integration [ ]
- [ ] GodotSteam plugin
- [ ] Steam Cloud save sync
- [ ] Achievements (first extraction, kill milestones, accuracy milestones)
- [ ] Steam store page
- [ ] Launch build & Steam upload

### 3.2 Input & Accessibility [ ]
- [ ] Controller support (full gamepad mapping)
- [ ] Input remapping UI
- [ ] Accessibility options (colorblind mode, subtitles)

### 3.3 Localization [ ]
- [ ] Multiple languages

### 3.4 Performance [ ]
- [ ] Performance profiling (target 60fps)
- [ ] LOD system for props at distance
- [ ] Occlusion culling tuning

### 3.5 Balance & Playtesting [ ]
- [ ] Danger curve tuning
- [ ] Ammo economy balance
- [ ] Weapon feel polish
- [ ] Contract reward balancing
- [ ] Skill value tuning

### 3.6 Marketing [ ]
- [ ] Trailer / marketing materials
- [ ] Steam store page assets (screenshots, capsule art)
