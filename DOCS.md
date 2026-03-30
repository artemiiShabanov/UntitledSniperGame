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
| **RunManager** | `scripts/systems/run_manager.gd` | Game state machine (HUB→DEPLOYING→IN_RUN→EXTRACTING→RESULT). Run timer, threat phases (EARLY/MID/LATE), lives, kill tracking, credit/XP accumulation, extraction flow. |
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
- `threat_phase_changed(phase: int)` — EARLY→MID→LATE transitions

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

1. **PaletteResource** (.tres) defines 8 color slots:
   - `bg_light`, `bg_mid`, `fg_dark` — base grayscale tones
   - `accent_hostile`, `accent_loot`, `accent_friendly` — gameplay colors
   - `danger`, `reward` — feedback colors

2. **PaletteManager** pushes these to **global shader uniforms** on every palette change:
   ```
   palette_bg_light, palette_bg_mid, palette_fg_dark,
   palette_accent_hostile, palette_accent_loot, palette_accent_friendly,
   palette_danger, palette_reward
   ```

3. **Shaders** (`palette_surface.gdshader`) read these uniforms to color meshes.

4. **StandardMaterial3D meshes** are colored via:
   - `bind_meshes(root, slot)` — individually tracked, updated on palette swap
   - `color_unscripted_meshes(root)` — bulk-colored with shared material (efficient)

5. **UI** reads colors via `PaletteManager.get_color(slot)` and `PaletteTheme`.

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
       └─ EnemyLookout (scripts/enemy/enemy_lookout.gd)
       └─ [future: EnemyMarksman, EnemyCountersniper, etc.]
```

### AI State Machine

```
UNAWARE ──(sees player)──► SUSPICIOUS ──(confirmed)──► ALERT
    ▲                          │                          │
    └──────(timer expired)─────┘          (lost LOS)──► SEARCHING
                                                          │
                                                    (timer)──► UNAWARE
```

### Detection

- **Visual:** FOV cone + range + raycast occlusion check
- **Audio:** Gunshot/impact sound propagation alerts nearby enemies
- **States:** Each state has different behavior (idle, scanning, shooting, searching)

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

## Level System

### BaseLevel (scripts/world/base_level.gd)

Orchestrates a playable level:
1. Finds player node, places at random PLAYER spawn point
2. Spawns enemies from EnemyPool at ENEMY spawn points
3. Spawns NPCs from NpcPool at activity points
4. Picks random extraction zone
5. Applies environment config (time of day, weather)
6. Colors all unscripted meshes via PaletteManager

### Level Data

Each level has a `LevelData` resource (.tres) with:
- Scene path, display name
- Enemy pool, NPC pool
- Phase config (durations, spawn intervals)
- Time/weather options (randomized per run)
- Unlock gates (extraction count, XP threshold)
- Entry fee

### Procedural Builders

Levels use builder scripts (e.g., `IndustrialYardBuilder`) to generate greybox geometry
from code. This allows rapid iteration before committing to 3D models.

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
  world/      — Levels, spawning, environment
  projectile/ — Bullet physics
  data/       — Resource definitions and registries
  util/       — Shared utilities
```
