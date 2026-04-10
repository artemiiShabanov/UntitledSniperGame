# Sniper Extraction: The Last Rifle — Development Plan

Legend: `[ ]` not started · `[~]` in progress · `[x]` done

---

## Status Overview

**Completed (pre-pivot):** Core autoloads (RunManager, SaveManager, PaletteManager, AudioManager, VFXFactory),
player movement/shooting, projectile ballistics, scope/sway/breath mechanics, bolt-action weapon,
grid-based level generation (constraint solver), palette system, HUD framework, hub shell,
save system with migration, loading screen, settings, film grain overlay.

**Current phase:** Medieval pivot — rework existing systems and build new ones per GDD.

| Section | Progress | Summary |
|---------|----------|---------|
| 1 · Core Rework | █████ 100% | RunManager, weapon, data resources — adapted to GDD |
| 2 · Warriors | █████ 100% | Complete rewrite — medieval warrior AI replaces modern enemy snipers |
| 3 · Battlefield | █████ 100% | Castle HP, extraction windows, destructibles, opportunities |
| 4 · Progression | █████ 100% | Procedural mods, tiered skills, army upgrades, scoring |
| 5 · Hub | █████ 100% | Rework stations for new economy (no credits, no contracts, no ammo shop) |
| 6 · Level | █████ 100% | Castle Keep — three-zone blocks, medieval theme |
| 7 · Content | ░░░░░ 0% | Models, animations, audio, textures for medieval setting |
| 8 · Polish & Release | ░░░░░ 0% | Steam, controller, balance, marketing |

---

## 1 · Core Rework

Adapt existing systems to the GDD. No new gameplay yet — just data structures and flow.

### 1.1 RunManager Rework [x]

Current: 10 phases, 5min countdown timer, credits economy, ammo loadout dictionary, contract system.
GDD: 20 phases × 60s each, count-up timer (no time limit — run ends by extraction/death/castle), score replaces credits, fixed 30 bullets, no contracts, castle HP as fail condition.

- [ ] Change `THREAT_PHASE_MAX` from 10 → 20
- [ ] Replace countdown `run_timer` with count-up elapsed timer (no expiry = no `run_timer_expired`)
- [ ] `_update_threat_phase()` — phase = floor(elapsed / 60) + 1, capped at 20
- [ ] Remove `run_credits`, `add_run_credits()`, `get_run_credits()` — replace with `run_score` / `add_run_score()`
- [ ] Remove `carried_ammo`, `consume_ammo()`, `get_carried_ammo()` — weapon handles its own fixed pool
- [ ] Remove `active_contract`, `contract_completed` and all contract logic
- [ ] Add `castle_hp: int`, `castle_max_hp: int`, `castle_take_damage(amount)`, signal `castle_hp_changed`
- [ ] Add `castle_destroyed` signal → triggers `_end_run_failure()`
- [ ] Three fail conditions: lives=0, castle HP=0, (no timer expiry)
- [ ] `_end_run_failure()` — lose all equipped mods (call into SaveManager)
- [ ] `_end_run_success()` — generate mod choices based on score + phase reached, tick mod durability
- [ ] Add extraction window state: `extraction_window_open: bool`, `extraction_window_timer: float`
- [ ] Extraction window schedule per GDD §4 (phases 2,4,6,7,10,13,15,19 with decreasing duration)
- [ ] `deploy()` — remove ammo_loadout param, reset castle HP, reset phase to 1
- [ ] Remove distance multiplier (no credits), headshot bonus goes to score (2x per GDD §3)
- [ ] `record_kill_with_bonus()` → `record_kill_with_score()` using per-type score values

> **Reuse:** State machine (HUB→DEPLOYING→IN_RUN→EXTRACTING→RESULT), extraction hold-E flow, lives system, hit cooldown, RunStats tracking. All signals stay, some renamed.

### 1.2 Weapon Simplification [x]

Current: AmmoManager with multiple ammo types, magazine+reserve, type switching, inspect action.
GDD: Single ammo pool of 30 bullets (no types, no reserve, no reload). Fixed bolt-action, 5 mod slots.

- [ ] Remove `AmmoManager` dependency — weapon tracks `bullets_remaining: int` directly
- [ ] Remove `ammo_type_changed` signal, `cycle_ammo_type()`, `select_ammo_type()`
- [ ] Remove `magazine_size`, `ammo_in_magazine`, `ammo_reserve` — replace with `bullets_remaining`
- [ ] Remove reload mechanic entirely (no `try_reload()`, `_finish_reload()`, `RELOADING` state)
- [ ] Remove inspect mechanic (`INSPECTING` state, `_start_inspect()`)
- [ ] Weapon states: IDLE, AIMING, BOLT_CYCLING (3 states, down from 5)
- [ ] `try_shoot()` → decrement `bullets_remaining`, no reload trigger on empty
- [ ] `apply_modifications()` → read procedural mod stats instead of fixed mod catalog
- [ ] Initial bullets = 30 + Deep Pockets skill bonus
- [ ] Keep: scope, sway, breath, bolt cycling, hipfire spread, bullet spawning, sound propagation

### 1.3 Data Resources Rework [x]

Current: `RifleMod` (fixed id/name/cost/stats), `PlayerSkill` (flat cost), `AmmoType`, `Contract`.
GDD: Procedural mods (rarity/budget/durability), tiered skills (4 skills × 3-4 tiers), opportunities, army upgrades.

- [ ] **Delete** `ammo_type.gd`, `ammo_registry.gd`, `ammo_manager.gd` — no ammo types
- [ ] **Delete** `contract.gd`, `contract_registry.gd` — no contracts
- [ ] **Rewrite** `rifle_mod.gd` → procedural: `slot`, `rarity` (enum), `stat_budget`, `stats: Dictionary`, `durability: int`, `max_durability: int`, `visual_type: int` (1-3 per slot). No `id`, `mod_name`, `cost`. Add `generate()` static that rolls stats from budget.
- [ ] **Rewrite** `player_skill.gd` → tiered: `id`, `skill_name`, `tiers: Array[Dictionary]` (each tier has cost, description, stat_bonus). 4 skills: Iron Lungs, Quick Hands, Last Stand, Deep Pockets.
- [ ] **New** `opportunity_data.gd` — Resource: `id`, `name`, `paired_army_upgrade_id`, `phase_range: Vector2i`, `duration: float`, `description`
- [ ] **New** `army_upgrade.gd` — Resource: `id`, `name`, `effect_key`, `effect_value`, `description`, `visual_description`
- [ ] **Rewrite** `mod_registry.gd` → `ModGenerator` — static class that generates procedural mods: takes rarity + slot → rolls stats from budget, assigns visual type
- [ ] **Rewrite** `skill_registry.gd` → hardcoded 4 skills with tier data
- [ ] **New** `opportunity_registry.gd` — 6 opportunities loaded from .tres
- [ ] **New** `army_upgrade_registry.gd` — 6 upgrades loaded from .tres

### 1.4 SaveManager Rework [x]

Current: Credits, ammo inventory, flat skill purchases, fixed mod IDs, contract tracking.
GDD: Score (not saved between runs), XP + tiered skills, procedural mod inventory with durability, army upgrade unlocks, opportunity completion counts.

- [ ] Remove `credits` from save data, `add_credits()`, `get_credits()`
- [ ] Remove `ammo_inventory` from save data
- [ ] Remove contract tracking fields
- [ ] Add `mod_inventory: Array[Dictionary]` — each entry is serialized procedural mod (slot, rarity, stats, durability, visual_type, equipped: bool)
- [ ] Add `equipped_mods: Dictionary` — { slot_name: inventory_index }
- [ ] Add `skill_tiers: Dictionary` — { skill_id: current_tier (0=not purchased) }
- [ ] Add `army_upgrades_unlocked: Array[String]` — list of army upgrade IDs
- [ ] Add `opportunity_completions: Dictionary` — { opportunity_id: count }
- [ ] `strip_equipped_mods()` — called on run failure, removes all equipped mods from inventory
- [ ] `tick_mod_durability()` — called on successful extraction, decrements durability of equipped mods, removes depleted ones
- [ ] `get_skill_tier(skill_id) → int`, `purchase_skill_tier(skill_id) → bool`
- [ ] `is_army_upgrade_unlocked(id) → bool`, `unlock_army_upgrade(id)`
- [ ] Save version bump + migration from v4

### 1.5 Scoring System [x]

GDD §3: Score determines mod rarity on extraction. Sources: kills (per-type base), headshot 2x, destructibles, opportunity completion. No distance multiplier.

- [ ] Score accumulates in `RunManager.run_score` during run
- [ ] Per-type base scores: Swordsman 20, Big Guy 40, Knight 70, Bombardier 50, Archer 40, Heavy Archer 60, Crossbowman 80, Bird Trainer 100
- [ ] Headshot = 2x score on any kill
- [ ] Destructible scores: Powder Keg 80, Siege Equipment 150
- [ ] Opportunity completion bonus (XP + extra mod choice)
- [ ] `calc_mod_rarity_pool(score, phase_reached) → Dictionary` — weighted rarity chances

---

## 2 · Warriors

Complete rewrite. Replace 6 modern sniper enemy types + 3 NPC types with medieval warrior system.

### 2.1 Warrior Base [x]

Current `enemy_base.gd` (441 lines): alert state machine, LOS detection, shooting AI, patrol, reposition.
GDD §6: Warriors advance, pair off 1v1, melee combat. Both sides use same base. No stealth/detection.

- [ ] **New** `warrior_base.gd` extends CharacterBody3D
- [ ] Two factions via `faction: int` (FRIENDLY / HOSTILE) — palette-colored
- [ ] State machine: ADVANCING → FOCUSING → ATTACKING → IDLE → DEAD
- [ ] **ADVANCING:** NavigationAgent3D moves toward enemy side. Speed per type.
- [ ] **FOCUSING:** Paired with an opponent (1v1). Turn to face.
- [ ] **ATTACKING:** Exchange roll-based attacks. Hit/miss with ~0.5-1s delay. Damage per type.
- [ ] **IDLE:** No opponent available, wait briefly then resume ADVANCING.
- [ ] **DEAD:** Death animation, award score/XP if hostile, score penalty if friendly.
- [ ] HP, armor, speed, castle_damage — configured per type via exports
- [ ] Headshot detection (bypass armor on all types)
- [ ] `on_bullet_hit()` — player can shoot any warrior. Headshot check, armor reduction, kill tracking.
- [ ] Pairing system: warriors seek nearest unpaired enemy-faction warrior within range
- [ ] Bombardier special: skip FOCUSING/ATTACKING, advance straight to castle, deal damage on arrival
- [ ] PaletteManager integration: `accent_friendly` vs `accent_hostile`
- [ ] NavigationAgent3D pathfinding around battlefield obstacles

> **Delete:** All 6 enemy scripts (enemy_lookout/spotter/marksman/drone/ghost/heavy.gd), enemy_visuals.gd. All 3 NPC scripts (npc_civilian/laborer/technician.gd), npc_visuals.gd, npc_base.gd.

### 2.2 Melee Warrior Types [x]

GDD §6.1: Swordsman, Big Guy, Knight, Bombardier (enemy-only).

- [ ] `warrior_swordsman.gd` — phase 1+, low HP, no armor, medium speed, 20 score, low castle damage
- [ ] `warrior_big_guy.gd` — phase 6+, high HP, light armor, slow, 40 score, heavy castle damage
- [ ] `warrior_knight.gd` — phase 10+, very high HP, heavy armor, medium speed, 70 score, medium castle damage
- [ ] `warrior_bombardier.gd` — phase 6+, low HP, no armor, medium speed, 50 score, heavy castle damage. Enemy-only. Ignores warriors, runs to castle.
- [ ] Scenes for each (shared humanoid skeleton, distinguished by silhouette)
- [ ] Body shot / headshot damage tables per type (swordsman=1 body, big guy=2 body or 1 head, knight=headshot efficient)

### 2.3 Ranged Warrior Types [x]

GDD §6.2: Archer, Heavy Archer, Crossbowman, Bird Trainer. Spawn in Zone 3, advance to ~80-100m, shoot at player.

- [ ] `warrior_ranged_base.gd` extends `warrior_base.gd` — override ADVANCING to stop at firing range, add shooting behavior
- [ ] `warrior_archer.gd` — phase 4+, low accuracy, visible arrow travel, slow advance. 40 score.
- [ ] `warrior_heavy_archer.gd` — phase 7+, medium accuracy, repositions between shots. 60 score.
- [ ] `warrior_crossbowman.gd` — phase 9+, high accuracy, very slow reload. 80 score.
- [ ] `warrior_bird_trainer.gd` — phase 11+, releases kamikaze birds (max 3 active), birds must be shot. 100 score.
- [ ] `kamikaze_bird.gd` — flies toward player, 1 life damage on arrival, can be shot down
- [ ] Arrow/bolt projectile (visible travel, hits player for 1 life)
- [ ] Ranged warriors don't melee — they stop and shoot

### 2.4 Warrior Spawning [x]

Current `enemy_spawner.gd`: phase-gated, interval-based, hidden spawn selection.
GDD: Both sides spawn continuously. Enemy count escalates per phase. Friendly count based on army upgrades.

- [ ] **Rewrite** `enemy_spawner.gd` → `warrior_spawner.gd`
- [ ] Spawns both factions from opposite sides (Zone 1 edge = friendly, Zone 3 edge = hostile)
- [ ] Phase-gated enemy type pools: `min_phase` on pool entries (reuse EnemyPoolEntry pattern → `WarriorPoolEntry`)
- [ ] Escalating spawn rate: more enemies per phase, density increases phases 1→20
- [ ] Friendly spawn rate: base + Faster Muster army upgrade bonus
- [ ] Friendly types: swordsman, big guy, knight (no bombardier)
- [ ] Numerical advantage tracking — excess warriors advance to castle
- [ ] Spawn off-screen preference (reuse `_pick_hidden_spawn()` logic)

### 2.5 Melee Combat System [x]

GDD §6.4: Warriors pair off 1v1, roll-based attacks.

- [ ] `CombatManager` (autoload or level-local) — tracks pairings
- [ ] Pairing: unpaired warrior finds nearest unpaired enemy within detection range
- [ ] Once paired: both enter FOCUSING, move toward each other, then ATTACKING
- [ ] Attack rolls: each warrior has hit_chance (~0.5-0.7), rolls every 0.5-1s
- [ ] Damage per type (swordsman < big guy ≈ knight)
- [ ] On kill: winner returns to IDLE → ADVANCING
- [ ] Excess unpaired warriors keep advancing — they reach the castle

---

## 3 · Battlefield Systems

Castle defense, extraction schedule, destructibles, opportunities.

### 3.1 Castle HP System [x]

GDD §4.1: Castle starts at fixed HP. Enemies reaching walls deal damage. HP bar on HUD.

- [ ] Castle HP managed by RunManager (§1.1)
- [ ] `castle_wall.gd` — Area3D trigger at castle walls. When hostile melee warrior enters, deal `castle_damage` and kill the warrior.
- [ ] Bombardier: higher castle_damage on arrival
- [ ] Siege Equipment: passive HP drain per second while alive (§3.3)
- [ ] Visual feedback: castle geometry cracks/darkens at low HP (shader or material swap)
- [ ] HUD: castle HP bar (§3.5)
- [ ] Army upgrade: Reinforced Gates (+40% max HP)

### 3.2 Extraction Window System [x]

GDD §4.3: Timed windows on a schedule. Multiple points, one active at a time.

- [ ] Extraction window schedule hardcoded per GDD:
  - Early: after phases 2, 4, 6 — 15s duration
  - Mid: after phases 7, 10, 13 — 10s duration  
  - Late: after phases 15, 19 — 8s duration
- [ ] `extraction_window_manager.gd` — listens to `threat_phase_changed`, opens/closes windows
- [ ] Multiple extraction points in level; one randomly activates per window
- [ ] HUD notification: "EXTRACTION OPEN" with countdown timer
- [ ] Player must reach active point + hold E within window duration
- [ ] Extraction cancelled by movement or damage (existing mechanic)

### 3.3 Destructibles Rework [x]

Current: 5 types (crate, bottle, balloon, rat, bird) with skins.
GDD §7: 2 types — Powder Keg (AoE) and Siege Equipment (passive castle drain).

- [ ] **Delete** destructible_balloon, destructible_bird, destructible_bottle, destructible_crate, destructible_rat, destructible_moving_target, balloon_spawner
- [ ] **New** `powder_keg.gd` — static, one-shot, AoE explosion damages nearby enemies. Phase 1+. 80 score.
- [ ] **New** `siege_equipment.gd` — static, one-shot, drains castle HP/sec while alive. Phase 6+. 150 score. Animated attack cycle (catapult swing, ram rock).
- [ ] Powder kegs placed in Zone 2/3 near enemy clusters
- [ ] Siege equipment placed in Zone 3
- [ ] AoE damage system for powder keg (Area3D overlap → damage warriors in radius)
- [ ] Reuse `DestructibleTarget` base class pattern (one-shot kill, VFX/audio)
- [ ] Update `DestructiblePool`/`DestructiblePoolEntry` for new types

### 3.4 Opportunity System [x]

GDD §10: 6 dynamic in-run events, each paired 1:1 with army upgrades. Kill targets within time.

- [ ] `opportunity_runner.gd` — replaces `level_event_runner.gd`
- [ ] Each opportunity: announce on HUD, spawn target(s), start timer, track completion
- [ ] **Enemy Champion** (ph 4-15, 60s) — tougher warrior, visually distinct. Kill before castle.
- [ ] **Archer Ambush** (ph 6-16, 45s) — group of archers at unexpected positions. Kill all.
- [ ] **Siege Assault** (ph 8-18, 90s) — multiple siege weapons activate. Destroy all.
- [ ] **War Horn** (ph 5-15, instant) — horn carrier appears briefly. One-shot opportunity.
- [ ] **Siege Tower** (ph 10-20, 60s) — siege tower approaches. Destroy before arrival.
- [ ] **War Chief** (ph 12-20, 45s) — enemy commander buffs nearby warriors. Kill to break buff.
- [ ] First-ever completion: XP + unlock paired army upgrade (via SaveManager)
- [ ] Repeat completion: XP + extra mod choice at run end with rarity boost
- [ ] 1-2 opportunities per run, selected from eligible pool based on current phase
- [ ] HUD: opportunity name + countdown timer

### 3.5 HUD Updates [x]

Current HUD: crosshair, scope overlay, ammo counter, lives, breath meter, kill feed, extraction bar, threat display, run timer, weapon state.
GDD §12: Add castle HP bar, opportunity timer. Remove run timer (no time limit). Remove ammo type display.

- [ ] Add castle HP bar (prominent, always visible)
- [ ] Add extraction window notification + countdown
- [ ] Add opportunity notification + timer
- [ ] Update ammo counter: show total bullets remaining (no magazine/reserve split)
- [ ] Remove run timer display (replace with phase indicator if desired)
- [ ] Remove ammo type indicator
- [ ] Remove threat phase text display (phase number shown subtly or not at all)
- [ ] Keep: crosshair, scope overlay, lives, breath meter, kill feed, extraction progress bar

---

## 4 · Progression

Between-run systems. Mod generation, skills, army upgrades.

### 4.1 Procedural Mod Generation [x]

GDD §9: Mods generated on extraction. Rarity determines stat budget + durability. Stats rolled randomly per slot.

- [ ] `ModGenerator` static class:
  - `generate(slot: String, rarity: int) → RifleMod` — rolls stats from budget
  - Stat tables per slot (GDD §9.3): Barrel (velocity, accuracy, falloff), Stock (sway reduction, move speed), Bolt (cycle time, stay scoped bool), Magazine (capacity 4-10, headshot damage 1.5-3.0x), Scope (clarity, FOV 40°-8°, variable zoom bool)
  - Budget per rarity: Common (low, 2 runs), Uncommon (medium, 4), Rare (high, 7), Epic (very high, 10)
  - Boolean stats (stay scoped, variable zoom): % chance increasing with rarity, don't consume budget
  - Visual type: random 1-3 per slot
- [ ] `generate_choices(score: int, phase: int, count: int = 3) → Array[RifleMod]` — pick rarities from weighted pool based on score/phase, generate one mod per choice
- [ ] Rarity pool weights shift: early runs favor Common, late runs favor Rare/Epic (GDD §9.1 table)
- [ ] Repeat opportunity completion: +1 extra choice with rarity boost

### 4.2 Mod Inventory & Durability [x]

GDD §9.1: 5 per slot (25 total). Durability ticks on extraction. Lost on failure.

- [ ] Mod inventory in SaveManager (§1.4)
- [ ] Equip/unequip mod (1 per slot)
- [ ] Durability decrement on successful extraction (equipped mods only)
- [ ] Mods at 0 durability removed from inventory
- [ ] All equipped mods lost on run failure
- [ ] Stashed (unequipped) mods safe from failure and durability
- [ ] Inventory cap: 5 mods per slot, reject if full

### 4.3 Tiered Skills [x]

GDD §8.2: 4 skills with 3-4 tiers each. XP costs scale per tier.

- [ ] Skill data (hardcoded or .tres):
  - **Iron Lungs**: +1s / +3s / +5s breath
  - **Quick Hands**: 20% / 40% / 70% faster reload (→ bolt cycle since no reload)
  - **Last Stand**: +1 / +2 lives
  - **Deep Pockets**: +10 / +30 / +50 / +100 bullets
- [ ] `SkillRegistry` — lookup skill by id, get tier data, check if affordable
- [ ] `SaveManager.purchase_skill_tier()` — deduct XP, increment tier
- [ ] Weapon reads skill bonuses at run start: breath_max, bolt_cycle_time, lives, bullets
- [ ] XP costs TBD (e.g. 100/300/600 scaling)

### 4.4 Army Upgrades [x]

GDD §8.3: 6 upgrades, each unlocked by completing its paired opportunity for the first time.

- [ ] Data (6 upgrades): Hardened Warriors (+30% friendly HP), Battle Training (+25% friendly damage + hit chance), Reinforced Gates (+40% castle max HP), Faster Muster (+25% friendly spawn rate), Archer Tower (friendly turret), Elite Guard (elite knights every 5 phases)
- [ ] `ArmyUpgradeRegistry` — lookup, check unlocked status
- [ ] Apply stat upgrades at run start: modify warrior stats, castle HP, spawn rate
- [ ] Archer Tower: spawn friendly ranged entity on castle walls
- [ ] Elite Guard: spawn armored knights at phases 5, 10, 15, 20
- [ ] War Room hub station displays upgrade status + paired opportunity

### 4.5 Run Result Screen [x]

GDD §12: Score breakdown, opportunity completions, army unlock notification, mod choices, XP earned.

- [ ] Rework `run_result_screen.gd`:
  - Success: score breakdown (kills by type, headshots, destructibles, opportunities), mod choice UI (pick 1 of 3+), XP earned, army upgrade unlocked (if any)
  - Failure: "mods lost" display, XP kept, opportunity progress
- [ ] Mod choice cards: show slot, rarity, stats, durability
- [ ] Army upgrade unlock animation/notification

---

## 5 · Hub Rework

Current: Ammo Crate, Ammo Shop, Contract Panel, Deploy Board, Loadout Panel, Mod Bench, Mod Shop, Palette Station, Save Terminal, Skill Board, Skill Shop, Stats Panel, Stats Terminal.
GDD §11: Armory, Skill Board, War Room, Level Select, Palettes, Stats Terminal, Deploy.

### 5.1 Hub Stations [x]

- [ ] **Delete** `ammo_crate.gd`, `ammo_shop.gd` — no ammo economy
- [ ] **Delete** `contract_panel.gd` — no contracts
- [ ] **Delete** `mod_shop.gd` — mods earned via extraction, not purchased
- [ ] **Merge** `mod_bench.gd` + `loadout_panel.gd` → **`armory.gd`** — equip/unequip/browse/manage mods (5 per slot cap), show durability, show stats
- [ ] **Rework** `skill_board.gd` / `skill_shop.gd` → tiered skill purchase UI (show all 4 skills, tier progress, XP cost for next tier)
- [ ] **New** `war_room.gd` — display 6 army upgrades, paired opportunity status, visual unlock progress
- [ ] **Rework** `deploy_board.gd` → level select (only 1 level initially), show level stats, deploy button
- [ ] **Keep** `palette_station.gd` / `palette_panel.gd` — palette browsing/equip
- [ ] **Keep** `stats_terminal.gd` / `stats_panel.gd` — lifetime + per-level stats
- [ ] **Keep** `save_terminal.gd`
- [ ] Update `hub.gd` — rewire station layout, remove credit display

---

## 6 · Level — Castle Keep

Current: Industrial Yard (modern industrial theme, greybox). Grid system with constraint solver ready.
GDD §5: Three-zone layout. Level 1 = Castle Keep (stone castle, open meadow, wooden palisade enemy camp).

### 6.1 Three-Zone Block System [x]

- [ ] Define zone types in grid system: CASTLE (Zone 1), BATTLEFIELD (Zone 2), ENEMY (Zone 3)
- [ ] Zone 1 blocks: elevated walls, towers, ramparts, multiple firing positions, extraction points, castle gate
- [ ] Zone 2 blocks: open ground with 100-200m+ sightlines, cover/obstacles (rocks, barricades, trenches), terrain variants (flat, rocky, trenched, hilly)
- [ ] Zone 3 blocks: enemy spawn points, camps, siege positions, ranged enemy positions, destructible placements
- [ ] NavigationRegion3D for warrior pathfinding across battlefield
- [ ] Sniper nest anchors on castle walls for sightline lane generation

### 6.2 Castle Keep Blocks [x]

- [ ] **Delete** `industrial_blocks.gd`, `industrial_yard_builder.gd`, `industrial_yard_grid_level.gd`, `industrial_yard_level.gd`
- [ ] **New** `castle_keep_blocks.gd` — BlockBuilder for Castle Keep theme
- [ ] 10-15 block scenes:
  - Castle: wall straight, wall corner, gate section, tower, rampart
  - Battlefield: flat meadow, rocky field, trench, barricade cluster, hill
  - Enemy: camp, siege position, archer post, palisade wall, spawn area
- [ ] GridLevelRules for Castle Keep: zone placement, height rules, sightline requirements
- [ ] BlockCatalog + GridLevelData .tres files
- [ ] Spawn points per block: PLAYER (castle), ENEMY/FRIENDLY (Zone 2/3 edges), DESTRUCTIBLE (Zone 2/3), EXTRACTION (Zone 1)

### 6.3 Level Data [x]

- [ ] **Rewrite** `level_data.gd` — remove NPC pool, balloon config, entry_fee, unlock requirements (only 1 level). Add castle_hp, warrior pools (friendly + hostile), opportunity pool, extraction point config.
- [ ] Castle Keep .tres with warrior pools, destructible pools, opportunity pool
- [ ] Per-run variation: time of day, weather, layout, spawn timing, opportunity selection, extraction rotation

### 6.4 BaseLevel Rework [x]

- [ ] Remove `_spawn_npcs()`, `_setup_balloon_spawner()`, NPC-related code
- [ ] Replace `_spawn_enemies()` with `_setup_warrior_spawner()` (both sides)
- [ ] Add castle HP initialization from level data
- [ ] Add extraction window manager setup
- [ ] Add opportunity runner setup
- [ ] Keep: environment variation, weather particles, palette coloring, level slots, events, audio

---

## 7 · Content

Models, animations, audio, textures — everything for the medieval setting.

### 7.1 3D Models

> **Pipeline:** Low-poly modeling (Blender) or asset packs → palette-colored materials → Godot import.
> Strip textures, apply palette shader uniforms.

<details>
<summary>Characters (~8 models, shared humanoid skeleton)</summary>

**Melee Warriors (shared skeleton, distinguished by silhouette):**
- [ ] Swordsman — medium build, sword + light shield
- [ ] Big Guy — large build, heavy weapon (mace/hammer), padding
- [ ] Knight — armored, sword + full shield, helmet
- [ ] Bombardier — medium build, carries explosive barrel/sack (enemy-only)

**Ranged Warriors:**
- [ ] Archer — light build, bow
- [ ] Heavy Archer — medium build, large bow, quiver
- [ ] Crossbowman — medium build, crossbow
- [ ] Bird Trainer — distinct silhouette, birds perched/caged

</details>

<details>
<summary>Props (~20 models)</summary>

**Castle:** Stone wall sections, tower, gate (with damage states), rampart, battlement
**Battlefield:** Rock formations, wooden barricade, trench edge, hay bale
**Enemy Camp:** Wooden palisade, tent, siege catapult, battering ram, siege tower, war banner
**Destructibles:** Powder keg (barrel with fuse), siege equipment (catapult, ram)
**Shared:** Extraction marker, arrow (projectile), crossbow bolt, kamikaze bird

</details>

### 7.2 Animations (~20 via Mixamo or hand-animated)

<details>
<summary>Animation list</summary>

**Warrior shared:** Walk, Run, Idle (standing), Melee attack (sword swing), Melee attack (heavy), Death (fall), Death (headshot), Hit reaction
**Ranged:** Aim bow, Shoot bow, Aim crossbow, Shoot crossbow, Release bird
**Bombardier:** Run with barrel, Arrive at castle (place explosive)
**Siege:** Catapult swing cycle, Ram rock cycle, Siege tower roll
**Player arms:** (Optional) bolt cycling, scope animation

</details>

### 7.3 Audio

> Medieval soundscape. Player's modern rifle should sound alien and powerful against it.

| Category | Needed | Notes |
|----------|--------|-------|
| Rifle | 4 | Shot (keep), bolt cycle (keep), dry fire (keep), add reload if needed |
| Battlefield | 6 | Sword clashing, war cries, death sounds, marching, charge horn, crowd intensifying |
| Ranged enemies | 4 | Arrow whistle, crossbow thunk, bird screech, arrow impact |
| Castle | 3 | Stone impact, gate creaking, crumbling at low HP |
| Siege | 3 | Catapult launch, battering ram hit, siege tower creak |
| Destructibles | 2 | Powder keg explosion, siege equipment destruction |
| UI | 4 | Extraction alert, opportunity announce, army upgrade unlock, phase change |
| Ambient | 3 | Medieval battlefield ambience (calm/tense/intense per phase bracket) |
| Music | 2 | Hub theme, battle theme (escalating) |

> **Reuse:** Rifle sounds (5), UI sounds (8), some ambient. Replace: all enemy sounds, impact sounds, world sounds.

### 7.4 Textures & Materials

- [ ] Stone/brick (castle walls, towers)
- [ ] Wood (palisade, barricades, siege equipment)
- [ ] Grass/dirt (battlefield ground)
- [ ] Metal (knight armor, weapons)
- [ ] Fabric (tents, banners)
- [ ] All palette-driven — base B&W with accent colors via shader uniforms

### 7.5 UI Assets

- [ ] Medieval-inspired HUD frame/borders
- [ ] Castle HP bar art
- [ ] Warrior type icons (for kill feed)
- [ ] Mod rarity visual indicators (notch system per GDD §9.4)
- [ ] Opportunity icons
- [ ] Army upgrade icons
- [ ] Extraction window indicator

---

## 8 · Polish & Release

### 8.1 Steam Integration [ ]
- [ ] GodotSteam plugin
- [ ] Steam Cloud save sync
- [ ] Achievements (first extraction, survive phase 10, survive phase 20, unlock all army upgrades, etc.)
- [ ] Steam store page
- [ ] Launch build & Steam upload

### 8.2 Input & Accessibility [ ]
- [ ] Controller support (full gamepad mapping)
- [ ] Input remapping UI
- [ ] Accessibility options (colorblind mode, subtitles)

### 8.3 Localization [ ]
- [ ] Multiple languages

### 8.4 Performance [ ]
- [ ] Performance profiling (target 60fps with 100+ warriors on screen)
- [ ] LOD system for warriors at distance
- [ ] Warrior mesh instancing for large counts
- [ ] Occlusion culling tuning
- [ ] NavigationServer optimization for many agents

### 8.5 Balance & Playtesting [ ]
- [ ] Phase escalation curve tuning (20 phases)
- [ ] Warrior HP/damage/speed per type
- [ ] Castle HP economy (damage vs. player kill rate)
- [ ] Bullet economy (30 base, Deep Pockets scaling)
- [ ] Mod stat budgets per rarity
- [ ] Skill XP costs per tier
- [ ] Extraction window timing
- [ ] Opportunity difficulty + rewards
- [ ] Army upgrade impact (must make phase 20 winnable)

### 8.6 Marketing [ ]
- [ ] Trailer / marketing materials
- [ ] Steam store page assets (screenshots, capsule art)
