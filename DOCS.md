# Sniper Extraction — Technical Documentation

---

## Architecture Overview

The project follows a **scene + autoload** architecture typical of Godot 4 games:

- **Autoloads** (singletons) manage global state and cross-cutting concerns
- **Scenes** (.tscn) define visual hierarchies with attached scripts
- **Resources** (.tres) store data (ammo types, mods, palettes, level configs)
- **Signals** decouple systems — emitters don't know about listeners

```
┌─────────────────────────────────────────────────────┐
│                    AUTOLOADS                         │
│  SaveManager · RunManager · PaletteManager          │
│  AudioManager · VFXFactory · SettingsManager         │
│  PaletteTheme · PauseMenu · FilmGrainOverlay        │
│  ModRegistry · SkillRegistry · ContractRegistry     │
│  AmmoRegistry                                       │
└───────────┬─────────────────────────┬───────────────┘
            │                         │
    ┌───────▼────────┐       ┌───────▼────────┐
    │   HUB SCENE    │       │  LEVEL SCENE   │
    │  hub.gd        │       │  base_level.gd │
    │  ├─ Player     │       │  ├─ Player     │
    │  ├─ Stations   │       │  ├─ Enemies    │
    │  ├─ StationUI  │       │  ├─ NPCs       │
    │  └─ HUD        │       │  ├─ World      │
    └────────────────┘       │  └─ HUD        │
                             └────────────────┘
```

---

## Autoloads Reference

| Autoload | Script | Purpose |
|----------|--------|---------|
| **SaveManager** | `scripts/systems/save_manager.gd` | Persistent save/load, credits, XP, stats, ammo inventory, mods, skills, palette unlocks. JSON file I/O. Multiple slots (max 3). Migration system (currently v4). |
| **RunManager** | `scripts/systems/run_manager.gd` | Game state machine (HUB→DEPLOYING→IN_RUN→EXTRACTING→RESULT). Run timer, threat phases (1-10), lives, kill tracking, credit/XP accumulation, extraction flow. |
| **PaletteManager** | `scripts/systems/palette_manager.gd` | Color palette system. Auto-discovers palette .tres files, manages palette cycling (unlock-aware), pushes colors to global shader uniforms, tracks bound meshes for recoloring. |
| **AudioManager** | `scripts/systems/audio_manager.gd` | Sound playback. Bank registry (key→stream), bus routing, 2D/3D playback, fade/crossfade. 36 sound banks. |
| **VFXFactory** | `scripts/systems/vfx_factory.gd` | Visual effects creation. Muzzle flash, tracers, impacts (world/body/head), extraction zone particles, death effects. All palette-colored. |
| **SettingsManager** | `scripts/ui/settings_manager.gd` | User preferences persistence. Sensitivity, audio volumes, video settings. Saved to user:// config file. |
| **PaletteTheme** | `scripts/ui/palette_theme.gd` | Generates a Godot Theme from active palette colors. All UI panels inherit this theme for consistent palette-reactive styling. |
| **PauseMenu** | `scenes/ui/pause_menu.tscn` | Global pause overlay (scene autoload). Resume, settings, abandon run. |
| **FilmGrainOverlay** | `scenes/ui/film_grain_overlay.tscn` | Post-process film grain effect (scene autoload). Always-on visual layer. |
| **ModRegistry** | `scripts/data/mod_registry.gd` | Catalog of all RifleMod resources. Auto-loads from data/mods/. |
| **SkillRegistry** | `scripts/data/skill_registry.gd` | Catalog of all PlayerSkill resources. |
| **ContractRegistry** | `scripts/data/contract_registry.gd` | Catalog of all Contract resources. Offers random contracts per deploy. |
| **AmmoRegistry** | `scripts/data/ammo_registry.gd` | Catalog of all AmmoType resources (5 types). |

---

## Game State Machine

RunManager drives the game through these states:

```
HUB ──(deploy)──► DEPLOYING ──(level loaded)──► IN_RUN
                                                   │
                                          ┌────────┴────────┐
                                          ▼                  ▼
                                     EXTRACTING          DEATH
                                     (hold E)            (lives=0)
                                          │                  │
                                          ▼                  ▼
                                       RESULT ◄──────────RESULT
                                          │
                                          ▼
                                         HUB
```

**Key signals:**
- `run_started` — level loaded, player placed
- `run_ended(success: bool)` — extraction complete or death
- `lives_changed(current: int)` — life lost
- `kill_recorded(info: Dictionary)` — enemy killed with metadata
- `threat_phase_changed(phase: int)` — phase 1→10 transitions (evenly spaced across run duration)
- `event_announced(text: String)` — mid-run event or announcement for HUD feed

---

## Save System

### Data Structure (v4)

```gdscript
{
    "version": 4,
    "slot": 0,
    "credits": 0,
    "xp": 0,
    "ammo_inventory": { "standard": 25, ... },
    "modifications": {
        "owned": [],
        "equipped": { "barrel": "", "stock": "", "bolt": "", "magazine": "", "scope": "" }
    },
    "skills": [],
    "unlocked_palettes": ["tactical"],
    "stats": {
        "total_runs": 0, "total_kills": 0, "total_headshots": 0,
        "total_extractions": 0, "total_deaths": 0,
        "total_shots_fired": 0, "total_shots_hit": 0,
        "total_xp_earned": 0, "total_credits_earned": 0,
        "best_survival_time": 0.0, "best_run_credits": 0,
        "best_run_kills": 0, "best_kill_distance": 0.0,
        "total_civilian_kills": 0, "total_targets_destroyed": 0
    },
    "per_level_stats": {}
}
```

### Migration Pattern

When `SAVE_VERSION` is bumped, add a migration block in `_migrate()`:

```gdscript
if ver < NEW_VERSION:
    # Transform save data from old format to new
    save_data["new_field"] = default_value
    save_data.erase("removed_field")
```

Migrations run sequentially (v1→v2→v3→v4) so any save version can upgrade.

---

## Palette System

### How It Works

1. **PaletteResource** (.tres) defines **8 gameplay-signal colors** — 4 semantic roles × 2 saturations. Grayscale is permanent and lives as constants on `VoxelSourcePalette` (mirrored on `PaletteManager`).
   - Good: `good`, `good_muted`
   - Bad: `bad`, `bad_muted`
   - Accent: `accent`, `accent_muted`
   - Filler (material warmth): `filler`, `filler_muted`
   - Grayscale constants (NOT in PaletteResource — fixed): `gs_light`, `gs_mid_light`, `gs_mid_dark`, `gs_dark`

2. **PaletteManager** pushes the 8 palette slots to **global shader uniforms** on every palette change, plus the 4 gray constants (which never change):
   ```
   palette_good, palette_good_muted,
   palette_bad, palette_bad_muted,
   palette_accent, palette_accent_muted,
   palette_filler, palette_filler_muted,
   palette_gs_light, palette_gs_mid_light, palette_gs_mid_dark, palette_gs_dark
   ```

3. **Voxel pipeline.** Voxel meshes use `voxel_palette.gdshader` with a material-level `mesh_type` uniform (`GOOD` / `BAD` / `ACCENT` / `FILLER` — see `VoxelMeshType`). Each mesh paints with only 6 source colors (`VoxelSourcePalette.GS_LIGHT` etc. + `PRIMARY` + `SECONDARY`); the shader rewrites `PRIMARY`/`SECONDARY` per `mesh_type` at render time. Faction swap = point mesh at a different pre-built shared material via `PaletteManager.get_voxel_material(type)`.

### Voxel coloring rules (enforced — every asset must comply)

Any voxel mesh imported into the project must satisfy all of the following, or it will render incorrectly:

1. **Paint only with the 6 canonical source colors** defined in `VoxelSourcePalette`. Any other color renders magenta in-game (the shader's intentional error fallback). Load the source palette into MagicaVoxel before painting so the working colors stay locked.
2. **Tag with exactly one `VoxelMeshType.Type`.** The mesh's material is one of the 4 shared materials from `PaletteManager.get_voxel_material(type)`. No runtime mesh_type changes on a single mesh — swap the material reference instead.
3. **Split multi-role models into child meshes.** If a voxel object conceptually carries two roles (e.g. friendly archer body + wooden bow), model them as separate voxel parts and tag each independently. Jointed-puppet character structure already enforces this at the part level.
4. **Do not bake palette colors into exports.** The `.glb` should contain the 6 source colors as vertex colors; never pre-resolve them to final palette colors or the palette swap feature breaks.
5. **Magenta = bug.** Seeing magenta in-game means either (a) an unapproved source color in the `.vox`, (b) a mesh with no material / wrong shader, or (c) `mesh_type` uniform unset. Check in that order.

3. **Shaders** (`palette_surface.gdshader`) read these uniforms to color meshes.

4. **StandardMaterial3D meshes** are colored via:
   - `bind_meshes(root, slot)` — individually tracked, updated on palette swap
   - `color_unscripted_meshes(root)` — bulk-colored with shared material (efficient)

5. **UI** reads colors via `PaletteManager.get_color(slot)` and `PaletteTheme`.

### UI & HUD coloring rules (enforced — every UI/HUD element must comply)

1. **Palette + grayscale only.** Every color applied to a UI or HUD control must come from `PaletteManager` — one of the 8 palette `SLOT_*` constants or one of the 4 grayscale constants (`PaletteManager.GS_LIGHT`, `GS_MID_LIGHT`, `GS_MID_DARK`, `GS_DARK`). No hard-coded `Color(r, g, b)` literals for visible elements.
2. **Reactive to palette swaps.** Any element that stores a color must refresh it on `PaletteManager.palette_changed`. Two sanctioned patterns:
   - **Via `PaletteTheme`** — controls that inherit the viewport theme retune automatically. Preferred when possible.
   - **Manual subscription** — `PaletteManager.palette_changed.connect(_refresh_colors)` in `_ready`, then fetch fresh values via `PaletteManager.get_color(slot)` inside the handler. Required for any color set via `add_theme_color_override` or custom-drawn pixels.
   - **Forbidden:** caching a `Color` at `_ready` with no refresh path — palette swaps will leave it stale.

### Unlock System

- Palettes are gated by achievements checked in `SaveManager.check_and_unlock_palettes()`
- Current gates: Tactical (free), Midnight (5 extractions), Noir (50 kills)
- Hub palette station calls `check_and_unlock_palettes()` before opening panel

---

## Hub System

### Station Pattern

Each hub feature follows this pattern:

1. **Interactable** (extends `Interactable`) — 3D object player looks at and presses E
   - Emits a custom signal (e.g., `palette_requested`)
2. **Panel** (extends `Control`) — UI panel that opens in StationUI layer
   - Has `open()` method and emits `panel_closed` (or similar) signal
3. **hub.gd** — orchestrator that connects station signals to panel open/close

```
Station (3D) ──signal──► hub.gd ──opens──► Panel (UI)
Panel ──closed signal──► hub.gd ──closes──► _close_active_panel()
```

### Deploy Flow

```
DeployBoard → Level Select → Contract Select → Loadout (ammo) → Deploy
```

Each step is a separate panel. The flow can be cancelled at any point.

---

## Enemy System

### Class Hierarchy

```
CharacterBody3D
  └─ EnemyBase (scripts/enemy/enemy_base.gd)
       ├─ EnemyLookout  — stationary scanner, tutorial-tier ($50/25XP, phase 1+)
       ├─ EnemySpotter  — wide FOV, broadcasts alert ($60/30XP, phase 3+, max 3/run)
       ├─ EnemyMarksman — repositions on sound/hit ($75/35XP, phase 4+)
       ├─ EnemyDrone    — flies, circles/chases, no headshot ($40/20XP, phase 5+, max 4/run)
       ├─ EnemyGhost    — 8% opacity unscoped, fast reposition ($100/45XP, phase 7+, max 2/run)
       └─ EnemyHeavy    — armored 15% damage, high damage ($120/50XP, phase 8+, max 2/run)
```

### Spawn Weights (Industrial Yard)

| Type | Weight | Max/Run | Min Phase |
|------|--------|---------|-----------|
| Lookout | 2.0 | unlimited | 1 |
| Spotter | 1.0 | 3 | 3 |
| Marksman | 1.2 | unlimited | 4 |
| Drone | 0.8 | 4 | 5 |
| Ghost | 0.6 | 2 | 7 |
| Heavy | 0.5 | 2 | 8 |

### AI State Machine

```
UNAWARE ──(sees player)──► SUSPICIOUS ──(confirmed)──► ALERT
    ▲                          │                          │
    └──(suspicion < 30%)───────┘          (lost LOS)──► SEARCHING
    ▲                                                     │
    └─────────────────────(timer expired)─────────────────┘
```

### Alert States

| State | Behavior | Rotation |
|-------|----------|----------|
| **UNAWARE** | Scanning or patrolling per `initial_behavior` | Smooth scan oscillation |
| **SUSPICIOUS** | Faces sound origin (if heard) or player (if visible) | Smooth toward source |
| **ALERT** | Tracks player, fires after `reaction_time` | Smooth toward player |
| **SEARCHING** | Stares at last known player position | Smooth toward last pos |

### Detection

- **Visual:** FOV cone (configurable half-angle) + range + raycast occlusion check
- **Audio:** `hear_sound(origin, loudness)` — suspicion scales with loudness/distance
- **Suspicion:** Builds while player is in LOS, decays when not. Thresholds: 30% → SUSPICIOUS, 100% → ALERT
- **Sound reaction:** Enemy faces sound origin (not player), repositioners move first then go SUSPICIOUS

### Base Behaviors (Behavior enum)

| Behavior | Description |
|----------|-------------|
| `DEFAULT` | No idle behavior — stands still |
| `SCANNING` | Oscillates rotation within `scan_angle` at `scan_speed` |
| `PATROL` | Walks between `patrol_points` with wait times |

### Reposition System

Enabled per-type via `can_reposition = true` on EnemyBase:

- **Auto-reposition:** Timer ticks in UNAWARE only. On expiry, moves to farthest patrol point
- **Reactive (sound):** Repositions first, then defers SUSPICIOUS state until arrival
- **Reactive (hit):** Repositions while staying ALERT
- **During reposition:** Won't shoot, faces movement direction with smooth rotation
- **Timer resets** when returning to UNAWARE from any other state

### Spawning

- **EnemyPool** — weighted random selection from `EnemyPoolEntry` list
- **EnemyPoolEntry** — scene reference, weight, max_per_run, min_phase (1-10)
- **EnemySpawner** — dynamic spawning during run, lerps interval/max_enemies from start phase to phase 10
- **Phase gating** — entries filtered by `RunManager.threat_phase < entry.min_phase`

### Visuals (EnemyVisuals)

- **Sight cone:** ArrayMesh flat fan with custom shader, fades from tip to edge
- **Glint:** Billboard Sprite3D with procedural 4-point star shader. Flickers in SUSPICIOUS, full in ALERT, half in SEARCHING
- **State indicator:** Debug label showing current alert state
- **Body color:** Per-type color override on Body mesh (head stays palette-colored)

---

## Destructible System

### Class Hierarchy

```
StaticBody3D
  └─ DestructibleTarget (scripts/world/destructibles/destructible_target.gd)
       ├─ DestructibleCrate  — static, large ($15 / 5 XP), 3 skins
       └─ DestructibleBottle — static, tiny ($20 / 8 XP), 3 skins

CharacterBody3D
  └─ DestructibleMovingTarget (scripts/world/destructible_moving_target.gd)
       ├─ DestructibleRat     — scurries between random points ($50 / 20 XP), 3 skins
       ├─ DestructibleBird    — sit/eat/fly cycle ($80 / 30 XP), 3 skins
       └─ DestructibleBalloon — rising, 3 tiers, phase-gated ($50-200), pops at max height
```

### DestructibleMovingTarget Base

Shared base for CharacterBody3D destructibles (Rat, Bird, Balloon):
- `on_bullet_hit()` → `_destroy()` — one-shot kill
- `_destroy()` — emits `target_destroyed`, records credits/XP, plays SFX/VFX, disables collision
- `_on_destroy()` — virtual, defaults to `VFXFactory.spawn_death_effect()`
- Subclasses override `credit_reward` / `xp_reward` in `_ready()`

### Spawning

- **DestructiblePool** / **DestructiblePoolEntry** — weighted random selection (mirrors EnemyPool pattern)
  - `spawn_mode` enum: STATIC (placed at spawn points) or DYNAMIC (random walkable positions)
  - `max_per_run` cap per entry
- **DestructibleSpawner** — handles placement:
  - `spawn_static(count)` — places at DESTRUCTIBLE SpawnPoints in level blocks
  - `spawn_dynamic(count)` — raycasts random walkable positions near existing spawn points
- **BalloonSpawner** — mid-run phase-aware spawning:
  - Listens to `threat_phase_changed` signal
  - Spawns balloons near living enemies (filters dead enemies)
  - Configurable: `spawn_interval` (30s default), `max_concurrent` (2), `spawn_chance` (0.6)
  - Announces tier on HUD via `RunManager.announce_event()`

### Balloon Tiers

| Tier | Min Phase | Credits | XP | Rise Speed | Max Height |
|------|-----------|---------|-----|------------|------------|
| Bronze | 3 | 50 | 20 | 1.8 m/s | 35m |
| Silver | 5 | 100 | 40 | 2.2 m/s | 40m |
| Gold | 7 | 200 | 75 | 2.8 m/s | 50m |

Balloons rise with gentle horizontal sway. If not shot before reaching max height, they pop (despawn with no reward).

---

## NPC System

### Class Hierarchy

```
CharacterBody3D
  └─ NpcBase (scripts/npc/npc_base.gd)
       ├─ NpcLaborer  — Work → Carry → Rest
       ├─ NpcTechnician — Operate → Inspect → Rest
       └─ NpcCivilian — Walk → Eat → Idle
```

### Activity System

- NPCs cycle through typed **ActivityPoints** (Marker3D placed in levels)
- State machine: `PERFORMING ↔ TRAVELING` with panic overlay `CALM ↔ PANICKING`
- Gunfire within range triggers panic/flee — NPC runs away, then resumes

---

## Events System

Mid-run events that change level conditions. Pipeline: `LevelEventData` → `LevelEventRunner` → HUD feed.

- **LevelEventData** (.tres) — defines event: script path, trigger time range, probability
- **LevelEventRunner** — attached to BaseLevel, checks trigger conditions each phase tick, fires eligible events
- **Event scripts** extend base and implement `execute(level, params)`:
  - `ExtractionChangeEvent` — removes active extraction zone, spawns new one at farthest available position
- **HUD integration** — events call `RunManager.announce_event(text)`, kill feed shows announcements in reward color for 6s
- **Debug:** F8 triggers extraction change manually

---

## Level System

### BaseLevel (scripts/world/base_level.gd)

Orchestrates a playable level:
1. Finds player node, places at random PLAYER spawn point
2. Spawns enemies from EnemyPool at ENEMY spawn points
3. Spawns NPCs from NpcPool at activity points
4. Spawns destructibles (static at DESTRUCTIBLE spawn points, dynamic at random positions)
5. Sets up BalloonSpawner for mid-run phase-gated balloon spawning
6. Picks random extraction zone
7. Starts LevelEventRunner for mid-run events
8. Applies environment config (time of day, weather)
9. Colors all unscripted meshes via PaletteManager

### Level Data

Each level has a `LevelData` resource (.tres) with:
- Scene path, display name
- Enemy pool, NPC pool, destructible pool
- Phase config (spawn_start_phase, spawn_interval_initial/final, max_enemies_initial/final)
- Destructible config (static_destructible_count_range, dynamic_destructible_count)
- Balloon config (balloon_spawn_interval, balloon_max_concurrent, balloon_spawn_chance)
- Level events pool (LevelEventData list)
- Time/weather options (randomized per run)
- Unlock gates (extraction count, XP threshold)
- Entry fee

### Grid-Based Level Generation

Procedural level layout system — each run assembles the map from reusable blocks on a grid.

**Architecture:**

```
GridLevelData (extends LevelData)
  ├─ BlockCatalog — collection of BlockDefs per theme
  └─ GridLevelRules — all per-level constraints as data
       ├─ AnchorPlacement[] — sniper nests, extraction zones
       ├─ ZoneRule[] — region constraints (RING/RECT/ROW/COL)
       ├─ HeightNeighborRule[] — adjacency height constraints
       └─ BlockBudget[] — min/max counts per type/height/tag
```

**Resources:**

| Resource | Purpose |
|----------|---------|
| `BlockDef` | Block descriptor: scene, grid_size, height_type, block_type, tags, weight |
| `BlockCatalog` | Collection of BlockDefs per theme, weighted selection helpers |
| `GridLevelRules` | All per-level constraints: anchors, zones, height neighbors, budgets |
| `GridLevelData` | Extends LevelData — adds block_catalog + level_rules |

**Solver steps (GridLevelBuilder):**
1. Initialize empty grid (`width × depth` cells, each 15m × 15m)
2. Stamp zone constraints onto cells
3. Place anchors — each picks random cell within allowed zone, respecting min distances
4. Auto-generate sightline lanes from sniper nest anchors (row + column → height-capped)
5. Fill remaining cells most-constrained-first, weighted random selection
6. Budget check — swap blocks if minimums unmet
7. Retry with relaxed soft constraints if stuck
8. Instantiate block scenes at grid coordinates

**Block scene convention:**
```
BlockRoot (Node3D)
  ├── Geometry/       # StaticBody3D + meshes + colliders
  ├── SpawnPoints/    # Marker3D — PLAYER, ENEMY, EXTRACTION, DESTRUCTIBLE types
  ├── ActivityPoints/ # Marker3D — NPC activities
  ├── CoverPositions/ # Marker3D — AI cover
  └── Props/          # Optional randomizable sub-objects
```

**Integration:** BaseLevel discovers SpawnPoints/ActivityPoints recursively from blocks.
RunManager, entity spawning, and extraction zones work unchanged.

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

---

## Weapon System

### weapon.gd — State Machine

```
IDLE ──(zoom)──► SCOPED ──(shoot)──► CYCLING (bolt) ──► SCOPED
  │                 │                                       │
  └──(shoot)──► CYCLING ──► IDLE            (zoom out)──► IDLE
                                    RELOADING ◄──(empty mag)
```

### Ammo System

- `AmmoManager` (RefCounted) tracks magazine + reserve per type
- 5 types: Standard, Armor-Piercing, High-Damage, Shock, Golden
- Loaded from hub inventory before run; unused returned on extraction

### Rifle Viewmodel

- CSG-based geometry (placeholder for proper 3D model)
- Modular slots: barrel, stock, bolt, magazine, scope
- `refresh_loadout()` rebuilds geometry from equipped mods
- PBR material with `accent_hostile` palette color

---

## VFX System

`VFXFactory` autoload creates all visual effects:

| Effect | Method | Description |
|--------|--------|-------------|
| Muzzle flash | `create_muzzle_flash()` | Bright flash at barrel, palette-colored |
| Tracer | `create_tracer()` | Trail following bullet path |
| World impact | `create_impact()` | Dust particles on surface hit |
| Body impact | `create_body_impact()` | Blood particles on enemy hit |
| Headshot | `create_headshot_effect()` | Larger flash + particles |
| Extraction | `create_extraction_effect()` | Particle ring at zone |
| Death | `create_death_effect()` | Enemy collapse particles |
| Weather | via `WeatherParticles` | Rain/snow following camera |

---

## Audio System

### AudioManager

- Loads `AudioBank` resource containing `AudioBankEntry` items
- Each entry: key (StringName), stream, volume, bus, variations
- Playback: `play_sfx_2d(key)`, `play_sfx_3d(key, position)`, `play_music(key)`
- Bus routing: Master, SFX, Music, Ambient, UI
- Placeholder beeps generated for unwired banks via `AudioPlaceholder`

### Sound Banks (36 entries)

Weapon (6), Impact (6), Player (8), UI (8), World (4), Ambient/Music (4)

---

## Project Conventions

### Code Style
- **Variables/functions:** `snake_case`
- **Classes:** `PascalCase`
- **Constants:** `UPPER_CASE`
- **Signals:** `snake_case` (past tense for events: `kill_recorded`, `run_ended`)
- **Private members:** prefixed with `_` (e.g., `_index`, `_bound`)
- **Type hints:** required on all function parameters and return types
- **Section headers:** `## -- Section Name` comment blocks to organize long scripts

### Resource Pattern
- Data types extend `Resource` (AmmoType, RifleMod, PlayerSkill, Contract, PaletteResource)
- Registries are autoloads that discover/catalog resources at startup
- Resources stored in `data/` directory, organized by type

### Signal Pattern
- Define signals with typed parameters: `signal kill_recorded(info: Dictionary)`
- Connect in `_ready()`, prefer `.connect()` over editor connections
- Use `&"string_name"` for signal/key references (StringName interning)

### File Organization
```
scripts/
  systems/    — Autoloads and core managers
  player/     — Player controller, weapon, ammo
  enemy/      — Enemy AI and types
  npc/        — NPC behavior and types
  hub/        — Hub stations and panels
  ui/         — HUD, menus, UI controllers
  world/      — Levels, spawning, environment, destructibles
  projectile/ — Bullet physics
  data/       — Resource definitions and registries
  utils/      — Shared utilities (ArrayUtils, etc.)
```
