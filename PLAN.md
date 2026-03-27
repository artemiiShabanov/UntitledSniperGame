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
| Objectives          | ████░ 80% | Contracts done, in-run objectives deferred |
| Global Progression  | ████░ 95% | Complete (cosmetics deferred to P4)       |
| World Population    | █████ 100%| Complete (events deferred to P4)          |
| UI & Menus          | ████░ 90% | All screens done except cosmetics         |
| Content & Population| █████ 100%| Complete (models/props/UI art → P4)       |
| Art & Audio         | █████ 100%| Systems complete (asset replacement later) |
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

### Phase 5 — Level Design
Build all playable levels as greybox. Get the game feeling right across multiple maps.

### Phase 6 — Polish & Ship
Make it look, sound, and feel great. Ship it.

---

## Phase 1 — Complete the Core Loop ✅

All features complete. Bug-audited and refactored.

<details>
<summary>FPS Mechanics — Movement, weapon, shooting, lives, interactions</summary>

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
<summary>Run Lifecycle — State machine, timer, extraction, result screen</summary>

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
<summary>Enemies (Core) — Detection, AI, Lookout type</summary>

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
<summary>Level Platform — Framework, spawning, variation, environment</summary>

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
<summary>Danger & Reward — Threat phases, distance/headshot bonuses</summary>

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

<details>
<summary>Shared files (HUD, Hub, Save)</summary>

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

</details>

---

## Phase 2 — Progression & Depth ✅

Core features complete. Bug-audited and refactored.

**Incomplete items moved to Phase 4:**
- Cosmetics system: save data placeholder exists, no backend/shop/UI
- KILL_TARGET / DESTROY_TARGET contracts: enum + fields exist, `check_completed()` returns false
- Hub cosmetics screen: listed but not implemented (no cosmetics backend)

<details>
<summary>Currency & Resources — Credits flow, XP flow, hub display</summary>

- Credits: earned in runs, saved on extraction, lost on death
- XP: earned in runs, always kept (total_xp_earned tracked separately for unlock gates)
- Currency storage in global save, hub display refreshes after runs/purchases

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/systems/save_manager.gd` | Credits/XP storage, add/get, total_xp_earned tracking |

</details>

<details>
<summary>Rifle Modifications — Mod data model, registry, shop, weapon integration</summary>

- RifleMod resource with slot, cost, stat_overrides, special behavior key
- ModRegistry autoload: central catalog of all mods
- SaveManager: owned/equipped modifications, purchase/equip methods
- Weapon.apply_modifications() at run start
- ModShop hub panel + ModBench station
- Foundation mods: Long Barrel (velocity), Extended Mag (capacity)

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/data/rifle_mod.gd` | RifleMod resource definition |
| `scripts/data/mod_registry.gd` | Autoload mod catalog |
| `scripts/hub/mod_shop.gd` | Browse, buy, equip mods UI |
| `scripts/hub/mod_bench.gd` | Hub station interactable |

</details>

<details>
<summary>Player Skill Unlocks — Skill data model, registry, 4 skills, shop</summary>

- PlayerSkill resource + SkillRegistry autoload (4 skills)
- Iron Lungs (+2s breath), Quick Hands (20% reload), Zipline Runner (40% zipline), Last Stand (+1 life)
- SaveManager: skill purchase with XP
- SkillShop hub panel + SkillBoard station

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/data/player_skill.gd` | PlayerSkill resource definition |
| `scripts/data/skill_registry.gd` | Autoload skill catalog |
| `scripts/hub/skill_shop.gd` | Skill purchase UI |
| `scripts/hub/skill_board.gd` | Hub station interactable |

</details>

<details>
<summary>Ammo Economy — Shop, inventory, loadout selection, carry/return</summary>

- Ammo shop (buy any type, +1/+5/+10 buttons)
- Hub inventory stored between runs
- Pre-run loadout selection (sliders per type)
- Weapon loads from carried ammo, unused returned on extraction, lost on death
- Starter ammo (25 standard) on first run
- AmmoRegistry autoload centralizes all ammo type definitions

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/data/ammo_registry.gd` | Autoload ammo type catalog (5 types) |
| `scripts/hub/ammo_shop.gd` | Buy ammo with credits |
| `scripts/hub/loadout_panel.gd` | Pre-run ammo selection sliders |
| `scripts/player/ammo_manager.gd` | In-run ammo state, type switching, magazine ops |
| `scripts/hub/ammo_crate.gd` | Hub station interactable |

</details>

<details>
<summary>Level Unlocks — Extraction count and XP thresholds</summary>

- LevelData: unlock_extractions + unlock_xp exports, is_unlocked() check
- Uses total_xp_earned (not spendable XP) for unlock gates
- Deploy panel shows locked levels with requirements
- Industrial Yard gated behind 2 extractions
- Entry fees: LevelData.entry_fee deducted on deploy (0 = free), not refunded on death
- Deploy panel shows fee amount and can't-afford state

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/world/level_data.gd` | Unlock logic: is_unlocked(), requirements text |

</details>

<details>
<summary>Contracts — Pre-run challenges with bonus rewards</summary>

- Contract data model + ContractRegistry (7 contracts)
- Types: kill count, headshot count, accuracy, no hits, speed extract
- Contract cost: credits deducted on accept (higher cost = higher reward)
- Contract level restriction: limit contracts to specific levels (level_restriction field)
- Contract selection in deploy flow (Mission → Contract → Loadout → Deploy)
- Evaluation at extraction with bonus credits/XP
- Random 3 offered per deploy, skip option

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/data/contract.gd` | Contract resource definition |
| `scripts/data/contract_registry.gd` | Autoload contract catalog |
| `scripts/hub/contract_panel.gd` | Contract selection UI |

</details>

<details>
<summary>HUD — In-run display (crosshair, scope, weapon, timer, kills)</summary>

- Crosshair, scope overlay, weapon state + credits display
- Lives indicator (hearts), run timer, threat phase indicator
- Kill feed, breath meter, extraction progress bar

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/ui/player_hud.gd` | In-run HUD: weapon, lives, timer, threat, interaction |
| `scripts/ui/crosshair.gd` | Dynamic crosshair |
| `scripts/ui/scope_overlay.gd` | Scope zoom black mask |
| `scripts/ui/breath_meter.gd` | Hold-breath meter |
| `scripts/ui/kill_feed.gd` | Kill notification with distance/headshot bonuses |
| `scripts/ui/extraction_bar.gd` | Extraction progress bar |
| `scripts/ui/run_result_screen.gd` | End-of-run stats overlay |
| `scenes/ui/hud.tscn` | HUD scene |

</details>

<details>
<summary>Menus — Main menu, save slots, pause, settings</summary>

- Main menu (new game, continue, settings, quit)
- Save slot selection (create, load, delete)
- Pause menu (resume, settings, abandon run)
- Settings (controls, audio, video, sensitivity)
- SettingsManager autoload

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/ui/main_menu.gd` | Main menu + slot management |
| `scripts/ui/pause_menu.gd` | Global pause overlay (autoload) |
| `scripts/ui/settings_screen.gd` | Settings widget |
| `scripts/ui/settings_manager.gd` | Settings persistence (autoload) |

</details>

<details>
<summary>Hub UI — All progression screens</summary>

- Contract selection (in deploy flow)
- Weapon modifications screen (ModShop)
- Skill unlock screen (SkillShop)
- Level select (locked/unlocked, requirements, entry fees)
- Loadout screen (ammo selection)
- Stats screen (lifetime stats, records, per-level breakdown)

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/hub/hub.gd` | Hub orchestrator: stations, panels, deploy flow |
| `scripts/hub/stats_panel.gd` | Stats display (lifetime, records, per-level) |
| `scripts/hub/stats_terminal.gd` | Hub station interactable |
| `scripts/hub/deploy_board.gd` | Hub station interactable |
| `scripts/hub/save_terminal.gd` | Hub station interactable |
| `scenes/hub/hub.tscn` | Hub scene |

</details>

<details>
<summary>Local Save — Save structure, file I/O, auto-save, multiple slots</summary>

- Save data: credits, XP, ammo inventory, modifications, skills, stats, per-level stats
- JSON file I/O to user data directory
- Auto-save after extraction and hub purchases
- Multiple save slots (3 max), migration system (v3)

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/systems/save_manager.gd` | Save/load, data structure, migrations |

</details>

<details>
<summary>Stats Tracking — Lifetime stats, best records, per-level breakdown</summary>

- Lifetime: runs, kills, headshots, extractions, deaths, shots fired/hit, accuracy, total XP earned
- Best records: survival time, credits, kills, longest kill distance
- Per-level: runs, extractions, deaths, kills, best time, best credits (stored in per_level_stats)
- commit_run_stats() aggregates per-run data into lifetime totals
- Stats terminal in hub displays lifetime, records, and per-level breakdown

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/systems/save_manager.gd` | Stats storage, aggregation, percentage calculations |
| `scripts/systems/run_manager.gd` | Per-run stats collection, end-of-run commit |
| `scripts/ui/run_result_screen.gd` | End-of-run stats display |

</details>

<details>
<summary>Shared utilities</summary>

| File | Purpose |
|------|---------|
| `scripts/util/format_utils.gd` | FormatUtils class: time formatting shared across UI |

</details>

---

## Phase 3 — Content & Population ✅

All systems complete. Remaining asset work (models, props, UI art pass, scope glint VFX) moved to Phase 4 Leftovers.

**Incomplete items moved to Phase 4:**
- Character models: Lookout model, NPC models, Destructible target models
- Props & Environment Art (entire section — building kit, industrial props, cover, vegetation)
- VFX: Scope glint shimmer
- UI Art Pass (entire section — menu polish, HUD styling, panel theming)

<details>
<summary>Neutral NPCs — NPC types, activity system, panic, kill penalty</summary>

- NpcBase class with activity state machine (PERFORMING ↔ TRAVELING) and panic layer (CALM ↔ PANICKING)
- 3 NPC types: Laborer (work→carry→rest), Technician (operate→inspect→rest), Civilian (walk→eat→idle)
- ActivityPoint markers in levels define where NPCs perform each activity
- NpcPool + NpcPoolEntry for weighted random NPC selection per level
- Panic/flee reaction to gunfire (sound propagation from weapon + bullet impacts)
- Flat credit penalty for killing NPCs (shown in kill feed, tracked in run stats)
- Result screen shows civilian kills count
- NPC scenes with distinct mesh colors (orange laborer, green technician, blue civilian)
- NpcVisuals with debug state indicator (blue=calm, yellow=panicking)

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/data/npc_type.gd` | NpcType resource: kind, activity durations, speeds, penalty, color |
| `scripts/world/activity_point.gd` | Marker3D for NPC activity locations |
| `scripts/world/npc_pool.gd` | Weighted NPC selection pool |
| `scripts/world/npc_pool_entry.gd` | Pool entry (scene, weight, max) |
| `scripts/npc/npc_base.gd` | NPC state machine: activity cycling, panic/flee, death |
| `scripts/npc/npc_visuals.gd` | Debug visualization for NPCs |
| `scripts/npc/npc_laborer.gd` | Laborer type subclass |
| `scripts/npc/npc_technician.gd` | Technician type subclass |
| `scripts/npc/npc_civilian.gd` | Civilian type subclass |
| `data/npcs/*.tres` | 3 NPC type definitions |
| `scenes/npc/*.tscn` | 3 NPC scene files |

</details>

<details>
<summary>Destructible Targets — shoot-to-destroy objects with rewards</summary>

- DestructibleTarget class (StaticBody3D): health, bullet hit, credit/XP reward on destruction
- Destructible box scene with distinct visual (warm yellow)
- RunManager.record_target_destroyed() + target_destroyed_with_info signal
- Kill feed shows "TARGET DESTROYED | +$X" in warm yellow
- Result screen shows targets destroyed count
- 8 destructible boxes placed in Industrial Yard (1 far-north high-value)
- 3 destructible boxes placed in dev test level

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/world/destructible_target.gd` | DestructibleTarget: health, hit, reward, visual death |
| `scenes/world/destructible_box.tscn` | Box scene (StaticBody3D, collision, mesh) |

</details>

<details>
<summary>Palette System — swappable color palettes, B&W world + accent colors</summary>

- Palette-driven art direction (B&W base + 3 accent colors: hostile, loot, friendly)
- PaletteResource data type with 8 color slots + extension space
- PaletteManager autoload — auto-discovers palettes, cycles with F8/F7
- 3 starter palettes (Tactical, Midnight, Noir)
- palette_surface.gdshader — assigns any palette slot to any mesh
- Film grain post-process shader
- Global shader uniforms — palette swap recolors entire scene instantly

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/systems/palette_manager.gd` | Autoload: palette discovery, cycling, global shader uniform updates |
| `data/palettes/palette_resource.gd` | PaletteResource: 8 color slots + extension space |
| `data/palettes/*.tres` | 3 palette definitions (Tactical, Midnight, Noir) |
| `shaders/palette_surface.gdshader` | Per-mesh palette slot assignment shader |
| `shaders/film_grain.gdshader` | Film grain post-process effect |
| `scripts/world/palette_mesh.gd` | Helper for palette-colored meshes |

</details>

<details>
<summary>UI Theme — PaletteTheme auto-generated theme, monospace font, palette-reactive</summary>

- PaletteTheme generates Godot Theme from active palette colors
- Monospace font for consistent UI styling
- All UI panels react to palette swaps in real time

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/ui/palette_theme.gd` | Auto-generated Theme from palette colors |
| `scripts/ui/player_hud.gd` | In-run HUD: weapon, lives, timer, threat, interaction |

</details>

<details>
<summary>Rifle Viewmodel — modular first-person weapon with mod slots</summary>

- Low-poly first-person rifle (CSG primitives, colored fg_dark)
- Base rifle geometry (receiver, trigger guard, grip, top rail)
- Mod attachments as swappable mesh parts:
  - Barrel mods (standard, long — visible length + muzzle brake)
  - Stock mods (body, buttpad, cheek rest)
  - Magazine mods (standard, extended — visible size change)
  - Scope mods (iron sights vs full scope tube with objective/eyepiece/rings)
  - Bolt mods (handle + knob)
- Viewmodel positioning (hip/aim lerp, auto-hide when deeply scoped)
- Palette coloring (fg_dark, updates on palette swap)
- refresh_loadout() for hot-swapping mods in hub

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/player/rifle_viewmodel.gd` | Viewmodel: CSG geometry, mod slot meshes, palette coloring, hip/aim positioning |

</details>

<details>
<summary>VFX System — muzzle flash, tracers, impacts, headshot, extraction, death, weather</summary>

- Muzzle flash (player + enemy)
- Bullet tracer trail
- Hit impact (palette-colored particles)
- Headshot effect (flash + larger particles)
- Extraction zone effect (particle ring)
- Death effect (enemy collapse)
- Weather particles (rain, snow — follows camera, palette-colored)

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/systems/vfx_factory.gd` | VFX creation: muzzle flash, tracers, impacts, headshot, extraction, death effects |
| `scripts/world/weather_particles.gd` | Rain/snow particle systems, camera-following, palette-colored |

</details>

<details>
<summary>Audio System — AudioManager, bank registry, 36 sound banks, per-level audio</summary>

AudioManager autoload + bank registry. Placeholder beeps wired to all 36 banks.

**Sources:** Freesound.org (CC0), Sonniss GDC Bundle (royalty-free), jsfxr (generated)

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/systems/audio_manager.gd` | Autoload: bank registry, play by key, bus routing, fade/crossfade |
| `scripts/systems/audio_bank.gd` | AudioBank resource: named collection of entries |
| `scripts/systems/audio_bank_entry.gd` | AudioBankEntry: key, stream, volume, bus, variations |
| `scripts/systems/audio_placeholder.gd` | Placeholder beep generator for unwired banks |
| `data/audio/default_bank.tres` | Default bank with all 36 sound entries |
| `tools/generate_ui_sounds.gd` | Editor tool script for generating UI sound WAVs |

<details>
<summary>Full sound bank listing (36 entries)</summary>

**Weapon Sounds:**
`rifle_fire` (Weapon/fire.mp3), `rifle_bolt` (Pixabay bolt-action), `rifle_dry` (Pixabay gun click), `scope_in` (Pixabay mechanical click), `scope_out` (Pixabay mechanical click), `rifle_reload` (Pixabay bolt action rifle)

**Impact Sounds:**
`impact_body` (Pixabay bullet-hit), `impact_world` (Pixabay ricochet), `impact_head` (Pixabay body-hit punchy), `impact_destructible` (Pixabay wood break), `bullet_whizz` (Pixabay bullet whizz), `bullet_penetrate` (Pixabay bullet-hit-metal)

**Player Sounds:**
`footstep` (Pixabay concrete footsteps), `slide` (Pixabay scrape), `heartbeat` (Pixabay heartbeat), `breath_hold` (Player/breath_in.mp3), `breath_exhale` (Player/breath_out.mp3), `hit_taken` (Player/hitHurt-2.wav), `death` (Player/death.wav), `scope_zoom` (Pixabay mechanical click)

**UI Sounds:**
`menu_click`, `menu_hover`, `menu_confirm`, `menu_cancel`, `ammo_switch`, `palette_switch`, `credits_gain`, `xp_gain` (all generated)

**World Sounds:**
`extraction_start` (Pixabay radio beep), `extraction_complete` (Pixabay helicopter), `alert_spotted` (Pixabay alarm beep), `npc_panic` (Pixabay scream)

**Ambient & Music:**
`level_ambient` (per-level ambient), `level_theme` (per-level music bed), `hub_theme` (Music/hub_theme.mp3), `combat_tension` (Pixabay tension music)

</details>

</details>

<details>
<summary>Weather System — rain/snow particles, fog presets, environment config</summary>

- Rain and snow particle systems following camera
- Fog density presets (clear, snow, rain, overcast)
- Visibility multiplier affects enemy sight range (fog halves it, night reduces by 40%)
- Per-level weather and time-of-day configuration

**Core files:**
| File | Purpose |
|------|---------|
| `scripts/world/weather_particles.gd` | Rain/snow GPUParticles3D, camera-following, palette-colored |
| `scripts/world/environment_config.gd` | Static presets: time of day (sun, sky), weather (fog, visibility) |

</details>

---

## Phase 4 — Leftovers

Items moved here from other phases — not blocking progress, but tracked for
later. Pull items back into active phases when/if they become relevant.

### Character Models (Remaining)
- [ ] Lookout model (replace capsule placeholder)
- [ ] Neutral NPC models (Laborer, Technician, Civilian — distinct from enemies)
- [ ] Destructible target models (crates, supply caches)

### Props & Environment Art
- [ ] Reusable building kit (walls, roofs, floors, stairs, railings)
- [ ] Industrial props (crates, barrels, containers, pallets, pipes)
- [ ] Cover objects (sandbags, concrete barriers, scaffolding)
- [ ] Vegetation (trees, bushes — sight blockers at range)

### UI Art Pass
- [ ] Main menu, save slots, settings — visual polish
- [ ] Hub layout — spatial navigation between stations
- [ ] In-run HUD — styled crosshair, scope overlay, threat indicator
- [ ] Result/death screens — styled layout
- [ ] All panels (contracts, mods, skills, ammo, stats) — consistent visual theme

### Additional Enemy Types
- [ ] Marksman (repositions between nests, medium awareness, decent accuracy)
- [ ] Countersniper (scope glint visible, actively scans for player, accurate and fast)
- [ ] Heavy Sniper (armored, requires AP ammo or headshot, high damage)
- [ ] Elite Sniper (flanks to different nests, uses smoke/repositioning)
- [ ] Scope glint shimmer VFX (deferred from Phase 3)

### Per-Run Variation Extras
- [ ] Color palette variation per run
- [ ] Variable sniper positions (some nests blocked/revealed per run)

### Phase-Gated Rewards
- [ ] Higher-value targets gated behind later phases
- [ ] Phase-specific enemy type pools (tougher enemies in LATE)
- [ ] Spawn multiplier for credit/XP based on threat phase

### Rifle Modifications — Full Catalog
- [ ] Barrel: Light Barrel, Heavy Barrel
- [ ] Stock: Padded, Breath, Competition
- [ ] Bolt: Quick, Smooth Action, Match
- [ ] Magazine: Drum Mag
- [ ] Scope: 4x, 8x, Variable (adjustable zoom + scope overlays)
- [ ] Visual model per mod on rifle

### Cosmetics System
- [ ] Rifle skins (visual overlays on top of upgrade parts)
- [ ] Cosmetics UI in hub (preview, equip)
- [ ] Cosmetics screen (needs cosmetics backend)

### Contracts — Content & Expansion
- [ ] Contract templates per level (eliminate HVT, destroy target, accuracy challenge)
- [ ] Contract reward balancing
- [ ] Contract board variety (enough to feel fresh across runs)
- [ ] Level-specific contracts (level_restriction field ready)
- [ ] KILL_TARGET contracts — eliminate a named high-value target (target_id field ready)
- [ ] DESTROY_TARGET contracts — destroy a specific object
- [ ] Higher-risk/higher-reward contracts for harder levels
- [ ] Contract difficulty scaling based on player progression

### Events System
- [ ] Event types TBD — designed in detail when needed
- [ ] Infrastructure exists (LevelEventData, LevelEventRunner, level_events_pool)

### In-Run Objectives
- [ ] Optional objectives (all headshots, no alerts, extract before mid-phase, no missed shots, no civilian casualties)
- [ ] Bonus rewards for completing optional objectives

---

## Phase 5 — Level Design

Build all playable levels as greybox (CSG geometry, placeholder meshes). Each level
gets its own builder script, spawn points, activity points, destructibles, extraction
zones, ziplines, and level data. Art pass comes later in Content Production.

> Each level needs: theme, 200m+ map, 2-3 wind corridors, sniper nests, repositioning
> routes, 15-20 enemy spawns, 2-3 extraction zones, NPC activity points, destructibles

### Levels ░░░░░ 25%

#### Industrial Yard [x]
- [x] Greybox geometry (IndustrialYardBuilder)
- [x] 17 enemy spawns, 3 extraction zones, 3 ziplines
- [x] 24 NPC activity points, NPC pool (3-5 NPCs)
- [x] 8 destructible boxes
- [ ] Art pass (needs models, textures, props)

#### Level 2 — TBD [ ]
- [ ] Theme and layout design
- [ ] Builder script with greybox geometry
- [ ] Spawn points, extraction zones, ziplines
- [ ] NPC activity points and pool
- [ ] Destructible targets
- [ ] Level data (.tres) with unlock gates

#### Level 3 — TBD [ ]
- [ ] Theme and layout design
- [ ] Builder script with greybox geometry
- [ ] Spawn points, extraction zones, ziplines
- [ ] NPC activity points and pool
- [ ] Destructible targets
- [ ] Level data (.tres) with unlock gates

#### Level 4+ [ ]
- [ ] As needed for progression gates

---

## Phase 6 — Polish & Ship

### Steam & Release ░░░░░ 0%
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
