# Sniper Extraction — Development Plan

Legend: `[ ]` not started · `[~]` in progress · `[x]` done

---

## Status Overview

**Completed:** Core gameplay loop, progression systems, UI/menus, palette system, hub,
save system, audio/VFX systems, 1 greybox level (Industrial Yard).

**Current phase:** Technical development & content production.

| Section | Progress | Summary |
|---------|----------|---------|
| Run Lifecycle | ███░░ 50% | Enemy types done, phase rewards, objectives, events, variation |
| Global Progression | ██░░░ 40% | Mods, contracts, palettes |
| Content | █░░░░ 20% | 1/4 levels done, placeholder art/models/audio, UI polish |
| Polish & Release | ░░░░░ 0% | Steam, controller, balancing, marketing |

---

## 1A · Run Lifecycle

Systems and mechanics active during a run.

### 1.1 Enemy Types [x]

6 enemy types implemented, each with distinct mechanics and phase-gated spawning:

- [x] **Lookout** (phase 1+) — stationary, scanning, slow reactions. Tutorial-tier fodder
- [x] **Spotter** (phase 3+) — binocular glint, alerts all nearby enemies on detection. Priority target
- [x] **Marksman** (phase 4+) — shoots back, repositions to cover after being shot at. Reactive threat
- [x] **Drone** (phase 5+) — flies toward player, low HP, deals damage on proximity. Anti-camping pressure
- [x] **Ghost** (phase 7+) — only visible through scope zoom, fast repositioning. Scope discipline check
- [x] **Heavy** (phase 8+) — armored (needs AP or headshot), slow, high damage. Loadout gate
- [x] Phase-gated spawning via `min_phase` on EnemyPoolEntry

> Enemy pools updated for Industrial Yard and Dev Test levels

### 1.2 Phase-Gated Rewards [ ]

Threat phases (1-10) exist but rewards don't scale with them yet.

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

### 1.5 Grid-Based Level Generation [x]

Procedural level layout system — each run assembles the map from reusable blocks on a grid.

**Architecture:**
- Grid: `width × depth` cells (e.g. 15×15), each cell 15m×15m
- Blocks: PackedScene `.tscn` files with geometry, spawn markers, cover positions
- Rules: per-level Resource defining all constraints as data, not code
- Solver: anchor-first placement → sightline lanes → constraint-based fill

**Resources:**

| Resource | Purpose |
|----------|---------|
| `BlockDef` | Block descriptor: scene, grid_size, height_type, block_type, tags, weight |
| `BlockCatalog` | Collection of BlockDefs per theme, weighted selection helpers |
| `GridLevelRules` | All per-level constraints: anchors, zones, height neighbors, budgets |
| `GridLevelData` | Extends LevelData — adds block_catalog + level_rules |
| `AnchorPlacement` | Randomized anchor zone + min_distance + facing mode |
| `ZoneRule` | Region constraint: shape (RING/RECT/ROW/COL), allowed heights/types |
| `HeightNeighborRule` | Adjacency constraint: source height → forbidden neighbor heights |
| `BlockBudget` | Min/max count per height_type, block_type, or tag |

**Solver steps:**
1. Initialize empty grid, stamp zone constraints onto cells
2. Place anchors — each picks random cell within its allowed_zone, respecting min_distance_to_anchors
3. Auto-generate sightline lanes from sniper nest anchors (row + column → height-capped)
4. Fill remaining cells most-constrained-first, weighted random selection
5. Budget check — swap blocks if minimums unmet
6. Retry with relaxed soft constraints if stuck
7. Instantiate block scenes, position at grid coordinates

**Block scene convention:**
```
BlockRoot (Node3D)
  ├── Geometry/       # StaticBody3D + meshes + colliders
  ├── SpawnPoints/    # Marker3D — enemy/NPC positions
  ├── ActivityPoints/ # Marker3D — NPC activities
  ├── CoverPositions/ # Marker3D — AI cover
  └── Props/          # Optional randomizable sub-objects
```

**Integration:** BaseLevel discovers SpawnPoints/ActivityPoints recursively — blocks just
need markers inside them. RunManager, entity spawning, extraction zones all unchanged.

**File structure:**
```
scripts/world/grid/
	block_def.gd, block_catalog.gd, block_instance.gd
	grid_level_data.gd, grid_level_rules.gd
	grid_level_builder.gd, grid_build_result.gd
	rules/ — anchor_placement.gd, zone_rule.gd,
			 height_neighbor_rule.gd, block_budget.gd
scenes/blocks/ — industrial/, city/, shared/
data/levels/   — <level>_rules.tres, <level>_catalog.tres
```

**Tasks:**
- [x] Core resources (BlockDef, BlockCatalog, GridLevelRules, sub-rules)
- [x] GridLevelBuilder solver
- [x] GridLevelData integration with BaseLevel
- [x] Block scenes — industrial theme (17 block builders)
- [x] Convert Industrial Yard to grid system as test
- [ ] Second level (City) using grid system

### 1.6 Destructible Types [ ]

Expand destructible targets beyond the basic crate to add variety and tactical options.

- [ ] Design destructible types list (explosive barrel, vehicle, supply cache, etc.)
- [ ] Per-type properties: HP, reward, visual size, special effects (explosion radius, chain reactions)
- [ ] DestructibleTarget base class refactor to support type variants
- [ ] Visual/audio feedback per type (explosion VFX, debris, sound)
- [ ] Phase-gated or level-specific destructible placement
- [ ] Contract integration (DESTROY_TARGET contract type)

> Depends on: destructible_box.gd (ready), VFXFactory (ready), kill feed (ready)

---

## 1B · Global Progression

Hub systems and between-run upgrades.

### 1.6 Rifle Modifications — Full Catalog [x]

Full mod catalog implemented across all slots:

- [x] Barrel: Extended, Improvised Suppressor, Tactical (+ 2 more)
- [x] Stock: Standard, Light, Padded, Heavy, Competition (sway/speed trade-offs)
- [x] Bolt: Standard, Quick, Smooth Action, Light, Match (cycle time + specials)
- [x] Magazine: Standard, Extended, Speed Loader, Drum Mag, Match
- [x] Scope: Standard, Red Dot, Grandma, Cheap, Tactical (unique overlays + variable zoom)
- [x] Visual model per mod on rifle viewmodel
- [x] 5 unique scope overlay styles with distinct reticles
- [x] Mod shop stat comparison (before/after display)
- [x] Scope overlay hidden during bolt cycling (non-continuous bolt)

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
- [x] Scope overlay — 5 distinct reticle styles (standard, red dot, grandma, cheap, tactical)
- [ ] Result/death screens — styled layout with animations
- [ ] Settings screen — section headers, better slider visuals

### 2.2 Levels

> All levels use the grid-based generation system (§1.5). Each level needs: theme,
> GridLevelRules + BlockCatalog (.tres), 10-15 block scenes, enemy/NPC pools,
> extraction zones, sightline lanes via sniper nest anchors.

#### Industrial Yard ✅ (greybox) → grid migration [ ]
- [x] Greybox geometry (IndustrialYardBuilder — legacy)
- [x] 17 enemy spawns, 3 extraction zones, 3 ziplines
- [x] 24 NPC activity points, NPC pool (3-5 NPCs)
- [x] 8 destructible boxes
- [ ] Convert to grid blocks (10-15 block scenes)
- [ ] GridLevelRules + BlockCatalog .tres files
- [ ] Art pass (needs models, textures, props)

#### Level 2 — City [ ]
- [ ] Block scenes (building facades, rooftops, streets, alleys)
- [ ] GridLevelRules (sightline lanes between buildings, height zoning)
- [ ] BlockCatalog + GridLevelData .tres files
- [ ] NPC activity points in blocks (bench sitting, phone calls, sweeping)
- [ ] Level data with unlock gates

#### Level 3 — Nature / Castle [ ]
- [ ] Block scenes (castle ruins, forest clearings, watchtowers)
- [ ] GridLevelRules (open clearings, scattered tall blocks)
- [ ] BlockCatalog + GridLevelData .tres files
- [ ] NPC activity points in blocks (chopping wood, tending fire, patrolling)
- [ ] Level data with unlock gates

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
