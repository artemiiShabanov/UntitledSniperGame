# Sniper Extraction: The Last Rifle — Development Plan

Legend: `[ ]` not started · `[~]` in progress · `[x]` done

---

## Status Overview

**Completed:** Sections 1–6 of the medieval pivot (Core Rework, Warriors, Battlefield, Progression, Hub, Level).
All 10 testing layers passed. Game is fully playable with placeholder assets.

| Section | Progress | Summary |
|---------|----------|---------|
| 7 · Content | ░░░░░ 0% | Models, animations, audio, textures for medieval setting |
| 8 · Polish & Release | ░░░░░ 0% | Steam, controller, balance, marketing |

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
