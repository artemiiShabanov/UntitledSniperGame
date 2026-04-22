# Sniper Extraction: The Last Rifle — Game Design Document

## 1. Overview

**Elevator Pitch:** A modern sniper is teleported onto a medieval battlefield. Perched on castle walls, you defend against an ever-growing siege — picking off warriors, destroying siege equipment, and managing limited ammunition. Lose your weapon mods if you fall. Unlock army upgrades across runs to eventually win the war.

**Genre:** First-person shooter / Roguelike defense · **Platform:** PC (Steam) · **Engine:** Godot 4.4

**Core Fantasy:** You are a modern sniper dropped into a medieval world. From atop castle walls, you look down on a raging battlefield — hundreds of warriors clashing below. Your rifle is impossibly powerful here. Every bullet can change the tide. But bullets are finite, the enemy grows stronger, and the castle won't hold forever.

**Key Pillars:**
- **Precision over speed** — every bullet counts; rewarding careful aim and target prioritization
- **Living battlefield** — warriors fight each other; the player influences but doesn't control the battle
- **Escalating siege** — threat grows continuously; the question is "how long can you hold"
- **Meaningful loss** — weapon mods are lost on failure
- **Meta-progression toward victory** — army upgrades across runs eventually enable winning the war

---

## 2. Core Loop

```
HUB (equip mods, select level) → DEPLOY (castle walls) → DEFEND (snipe, survive, handle opportunities) → EXTRACT or FALL → HUB
```

**In-run:** The player spawns on castle walls overlooking a battlefield. Friendly and enemy warriors clash below. The player scopes, prioritizes targets, and fires. Every shot is a decision — bullets are limited. The castle takes damage from enemies reaching the walls. Extraction windows appear periodically; miss one and wait for the next while the siege intensifies.

**Between runs:** Successful extractions award a choice of weapon mods (rarity based on score/phase). Failed runs lose all equipped mods. XP is always earned. Completing in-run opportunities permanently unlocks army upgrades, eventually enabling a winnable final stand at phase 20.

---

## 3. Player

### Movement
- WASD + mouse look, sprint, jump, crouch, slide (sprint + crouch)
- Ziplines between wall sections (deferred — add if playtesting demands faster traversal)

### Weapon — Sniper Rifle
The player's only weapon. Bolt-action, projectile-based (bullet drop + travel time), scope with sway (reduced by holding breath), magazine-based reload. Fixed **30 bullets per run** — no ammo types, no pickups, no resupply. Upgradeable via Deep Pockets skill. 5 mod slots: barrel, stock, bolt, magazine, scope.

### Lives
Limited lives per run (no health bar). Any ranged enemy hit costs one life. All lives lost = run failure. No healing mid-run.

### Scoring
Score determines mod rarity on extraction. Sources: enemy kills (per-type base value), headshot bonus (2x), destructibles, opportunity completion. Repeat opportunities grant additional mod choices with boosted rarity (§8).

---

## 4. Battlefield & Threat

### Run End Conditions
- Player extracts during an extraction window (success)
- Player loses all lives (failure — mods lost, XP kept)
- Castle HP reaches 0 (failure — mods lost, XP kept)

Phase 20 is simply the hardest phase — surviving it and extracting is the "win."

### Castle HP
Starts at a fixed value per level. Enemy melee warriors reaching the walls deal damage proportional to type. Player prevents damage by killing enemies before arrival. Visual feedback: HP bar on HUD.

### Phases (20 × 60 seconds = 20 min max)

| Phases | New Enemies | Notes |
|--------|------------|-------|
| 1-3 | Swordsmen | Calm battlefield, learn the flow |
| 4-5 | Archers | First ranged threats, spawning accelerates |
| 6-7 | Big Guys, Bombardiers, Heavy Archers | Castle pressure begins |
| 8-9 | Crossbowmen | Significant ranged + melee threat |
| **10** | **Knights** | **Major wave — tests mid-game readiness** |
| 11-14 | Bird Trainers | Knights become regular, castle damage spikes |
| **15** | — | **Elite wave — demands army upgrades** |
| 16-19 | — | Maximum density, all types, relentless |
| **20** | — | **Final stand — unwinnable without army upgrades** |

### Extraction Windows
Multiple extraction points exist; only one activates at a time per schedule:

| Period | Window After Phases | Duration | Frequency |
|--------|-------------------|----------|-----------|
| Early (1-6) | 2, 4, 6 | 15s | ~2 min |
| Mid (7-14) | 7, 10, 13 | 10s | ~3 min |
| Late (15-20) | 15, 19 | 8s | ~4 min |

8 total extraction windows per run. Hold E to extract (several seconds), cancelled by movement or damage.

---

## 5. Level Structure

Every level follows a three-zone layout:

- **Zone 1 — Castle:** Elevated walls, towers, ramparts. Multiple firing positions. Extraction points along walls. Castle gate where enemies attack.
- **Zone 2 — Battlefield:** Open ground with 100-200m+ sightlines. Cover/obstacles (rocks, barricades, trenches). Terrain variation via block variants (flat, rocky, trenched, hilly). Warriors navigate around obstacles using NavigationAgent3D.
- **Zone 3 — Enemy Positions:** Enemy spawn points, camps, siege positions. Ranged enemies and destructibles located here.

### Level Generation
Grid-based procedural generation from blocks. Castle blocks (Zone 1), battlefield blocks (Zone 2), enemy blocks (Zone 3). Constraint rules ensure spawn/extraction point placement. Each run generates a different layout.

### Level 1 — Castle Keep
Classic stone castle, open meadow battlefield, wooden palisade enemy camp. Introductory difficulty. Future levels (hilltop fortress, river crossing, etc.) added later with unique block catalogs.

### Per-Run Variation
Procedural layout, time of day (morning/day/evening/night), weather (clear/fog/rain), spawn timing, opportunity selection, extraction rotation.

---

## 6. Warriors

Warriors spawn from both sides, advance, and fight in melee. Friendly and enemy share the same types, distinguished by palette color (`accent_friendly` vs `accent_hostile`). The player doesn't control friendly warriors.

### Melee Types

| Type | Phase | HP | Armor | Speed | Score/XP | Castle Damage | Notes |
|------|-------|----|-------|-------|----------|---------------|-------|
| **Swordsman** | 1+ | Low | None | Medium | 20/10 | Low | One body shot kill. Backbone of the army. |
| **Big Guy** | 6+ | High | Light | Slow | 40/20 | Heavy | Survives a body shot. Headshot or 2 body shots. |
| **Knight** | 10+ | Very high | Heavy | Medium | 70/35 | Medium | Body shots reduced. Headshot efficient. Survives longest. |
| **Bombardier** | 6+ | Low | None | Medium | 50/25 | Heavy | **Enemy only.** Ignores warriors, runs straight to castle. Priority target. |

Headshots bypass armor on all types.

### Ranged Types (Threats to Player)
Spawn in Zone 3, advance through battlefield, stop ~80-100m from castle. Do not melee.

| Type | Phase | Accuracy | Score/XP | Behavior |
|------|-------|----------|----------|----------|
| **Archer** | 4+ | Low | 40/20 | Visible arrow travel. Advances slowly, stops to fire. |
| **Heavy Archer** | 7+ | Medium | 60/30 | Repositions between shots. |
| **Crossbowman** | 9+ | High | 80/40 | Very slow reload, high accuracy. Predictable timing. |
| **Bird Trainer** | 11+ | N/A | 100/50 | Releases kamikaze birds (max 3 active). Birds must be shot down. |

All ranged hits cost 1 life.

### Friendly Warriors
Same types (swordsman, big guy, knight — no friendly bombardiers). Killing a friendly incurs a score penalty. Strength upgraded via army upgrades.

### Warrior AI
Simple state machine: **Advancing → Focusing → Attacking → Idle → Advancing** (or Dead). Bombardiers skip Focusing/Attacking, go straight to castle.

**Combat:** Warriors pair off 1v1. Exchange roll-based attacks (hit/miss with ~0.5-1s delay). Excess warriors with no opponent continue advancing. Numerical advantage = more enemies reaching the castle.

**Pathing:** NavigationRegion3D / NavigationAgent3D. Most direct navigable route forward — no intelligent flanking.

---

## 7. Destructibles

Static one-shot targets in the enemy zone.

| Type | Phase | Score/XP | Effect |
|------|-------|----------|--------|
| **Powder Keg** | 1+ | 80/30 | AoE explosion damages nearby enemies. Ammo-efficient if enemies cluster. |
| **Siege Equipment** | 6+ | 150/60 | Passively drains castle HP/sec while alive. Animates attack cycle (catapult swing, ram rock). Priority target. |

---

## 8. Progression

### XP
Earned every run regardless of outcome. Spent on player skills only.

### Player Skills (Tiered)

| Skill | Tier 1 | Tier 2 | Tier 3 | Tier 4 |
|-------|--------|--------|--------|--------|
| **Iron Lungs** | +1s breath | +3s | +5s | — |
| **Quick Hands** | 20% reload | 40% | 70% | — |
| **Last Stand** | +1 life | +2 lives | — | — |
| **Deep Pockets** | +10 bullets | +30 | +50 | +100 |

XP costs scale per tier (TBD balancing).

### Army Upgrades (Global Goal)
Each upgrade unlocked by **completing its paired opportunity for the first time** (see Opportunities below). Cannot be purchased. All visible on the battlefield. ~15-20 runs to unlock all 6 and beat phase 20.

| Upgrade | Unlocked By | Effect | Visual |
|---------|-------------|--------|--------|
| **Hardened Warriors** | Enemy Champion | +30% friendly HP | Helmets/padding |
| **Battle Training** | Archer Ambush | +25% friendly damage + hit chance | Larger weapons |
| **Reinforced Gates** | Siege Assault | +40% castle max HP | Iron bands on gate |
| **Faster Muster** | War Horn | +25% friendly spawn rate | More warriors on field |
| **Archer Tower** | Siege Tower | Friendly turret on castle walls | Tower appears |
| **Elite Guard** | War Chief | Elite knights spawn every 5 phases | Armored knights march out |

First 4 are stat modifiers; Archer Tower and Elite Guard spawn new entities.

### Palettes
Achievement-gated color palette unlocks. Entire world recolors via global shader uniforms.
Slots: `bg_light`, `bg_mid`, `fg_dark`, `accent_hostile`, `accent_friendly`, `accent_loot`, `danger`, `reward`.

---

## 9. Weapon Mods

### Core Rules
- **Earned on extraction:** choose 1 from 3 randomly generated mods
- **Lost on failure:** all equipped mods lost on death or castle fall
- **Durability:** ticks down per successful extraction while equipped. Stashed mods don't degrade.
- **Inventory:** 5 per slot (25 total). Unequipped mods safe in hub stash.

### Procedural Generation
Each mod has: **slot**, **rarity** (stat budget + durability), **stats** (budget distributed randomly), **visual type** (1 of 3 per slot, cosmetic).

| Rarity | Budget | Durability | Drop % (early) | Drop % (late) |
|--------|--------|------------|----------------|---------------|
| Common | Low | 2 runs | 60% | 20% |
| Uncommon | Medium | 4 runs | 30% | 35% |
| Rare | High | 7 runs | 9% | 30% |
| Epic | Very high | 10 runs | 1% | 15% |

Budget determines total quality — distribution is random (specialist or balanced). Rarity pool depends on phase reached + score. Boolean stats (stay scoped, variable zoom) roll % chance increasing with rarity, don't consume budget.

### Stats Per Slot

| Slot | Stats |
|------|-------|
| **Barrel** | Velocity, Accuracy, Bullet falloff |
| **Stock** | Sway reduction (0-40%), Move speed (-20% to +15%) |
| **Bolt** | Cycle time (1.2s → 0.6s), Stay scoped (bool) |
| **Magazine** | Capacity (4-10), Headshot damage (1.5x → 3.0x) |
| **Scope** | Clarity, FOV (40° → 8°), Variable zoom (bool) |

### Rarity Visuals
No extra colors outside the palette. Rarity shown by model complexity:
Common = plain · Uncommon = 1 notch · Rare = 2 notches + detail · Epic = 3 notches + complex silhouette. Text label in UI.

---

## 10. Opportunities

Dynamic in-run events. Each paired 1:1 with an army upgrade. All follow the pattern: kill target(s) within time.

| Opportunity | Phases | Duration | Army Upgrade | Description |
|-------------|--------|----------|-------------|-------------|
| **Enemy Champion** | 4-15 | 60s | Hardened Warriors | Tougher warrior, visually distinct. Kill before it reaches castle. |
| **Archer Ambush** | 6-16 | 45s | Battle Training | Group of archers at unexpected positions. Kill all. |
| **Siege Assault** | 8-18 | 90s | Reinforced Gates | Multiple siege weapons activate. Destroy all. |
| **War Horn** | 5-15 | Instant | Faster Muster | War horn carrier appears briefly. One-shot opportunity. |
| **Siege Tower** | 10-20 | 60s | Archer Tower | Siege tower approaches. Destroy before arrival. |
| **War Chief** | 12-20 | 45s | Elite Guard | Enemy commander buffs nearby warriors. Kill to break buff. |

**Rewards:**
- **First completion ever:** XP + permanently unlocks paired army upgrade
- **Repeat completions:** XP + one additional mod choice at end of run (with rarity boost)

---

## 11. Hub

- **Armory** — equip/browse/manage weapon mods (5 per slot cap)
- **Skill Board** — spend XP on tiered player skills
- **War Room** — view army upgrades and opportunity completion status
- **Level Select** — choose level, view stats
- **Palettes** — browse and equip color palettes
- **Stats Terminal** — lifetime and per-level statistics
- **Deploy** — start a run

---

## 12. UI & HUD

**In-Run:** Crosshair (hidden when scoped), scope overlay, ammo counter (total bullets), lives (hearts), castle HP bar, breath meter, kill feed, extraction notification + progress bar, opportunity notification + timer, interaction prompt.

**Menus:** Main menu, pause menu, run result screen (score breakdown, opportunity completions, army unlock, mod choices, XP), failure screen (mods lost, XP kept), settings.

---

## 13. Audio

The player's modern rifle should sound alien and powerful against the medieval soundscape.

- **Rifle** — punchy shot, bolt cycling, reload, dry fire
- **Battlefield** — sword clashing, war cries, death sounds, marching (intensifies with phase)
- **Ranged enemies** — arrow whistles, crossbow thunks, bird screeches
- **Castle** — stone impacts, crumbling at low HP
- **UI** — extraction alerts, opportunity announcements

---

## 14. Art Direction

**Palette-driven voxel minimal.** Clean voxel geometry throughout. B&W base world with palette accent colors: `accent_hostile` (enemies), `accent_friendly` (allies/castle), `accent_loot` (destructibles/extraction). `danger`/`reward` for feedback. Film grain overlay.

**Voxel pipeline:** All assets modeled in MagicaVoxel. Vertex colors are remapped to palette slots via a global shader — no textures. Greedy-meshed exports keep tri counts low.

**Warriors:** Jointed voxel puppets (Minecraft/Crossy Road style). Each character is a hierarchy of separate voxel parts (head, torso, upper/lower arms, upper/lower legs) parented in Godot and animated via AnimationPlayer joint rotations — no skeletal rigging. Types distinguished by voxel silhouette: swordsman = medium, big guy = chunkier blocks and taller, knight = armored + shield voxels. Ranged enemies by weapon shape. Friendly vs enemy by palette color.

**Rifle:** Voxel-modeled, visually anachronistic against the medieval set. Each mod slot has 3 visual types. Rarity = model complexity (notches), not color.

**UI:** Clean, minimal, geometric. Monospace font. Subtle medieval-inspired borders. Palette-aware.

---

## 15. Save System

Multiple save slots. Per-slot: XP (total/spent), mod inventory (slot, rarity, stats, durability, visual type), equipped loadout, skill tiers, army upgrades unlocked, opportunity completion counts, unlocked palettes, lifetime stats, per-level stats. Save version with automatic migration.

---

## 16. References

| Game | Inspiration |
|------|-------------|
| Sniper Elite | Sniping mechanics, bullet physics |
| Slay the Spire | Roguelike item economy, risk/reward |
| Hades | Meta-progression, hub loop |
| Kingdom | Castle defense from elevated position |
| They Are Billions | Escalating siege, base HP |
| Neon White | Minimal aesthetic, bold accents |
| Obra Dinn | Monochrome + grain atmosphere |
| TABS | Chaotic battlefield spectacle |
| Rogue Legacy | Permanent upgrades across runs |
