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

Models, animations, audio, UI — everything for the medieval setting.

**Build order:**
1. **§7.1 Palette shader + source palette** — foundation; every voxel authored afterward depends on the source-color → palette-slot mapping. Locks faction recolor and global palette swap.
2. **§7.2 Prototype milestone** (Swordsman walk cycle → 50 instances at 60fps) — validates the whole pipeline end-to-end with the shader applied.
3. **§7.2 Remaining warriors** — paint on the existing rig; parallelizable.
4. **§7.2 Props / castle / siege / rifle** — independent tracks.
5. **§7.3 Audio, §7.4 UI** — in parallel with §7.2 once the prototype is green.

### 7.1 Palette Shader & Source Palette

Foundation for all voxel content. No textures. Voxels carry color as **vertex colors**; the voxel shader classifies each vertex against **6 canonical source colors**, then rewrites PRIMARY / SECONDARY based on each mesh's `mesh_type` (good / bad / accent / filler). Grayscale is permanent across palettes — only the 8 signal slots swap.

- [ ] Define canonical source colors in `scripts/voxel/voxel_source_palette.gd` (done — 6 colors):

  | Source hex | Source constant | Role | Resolves to |
  |------------|----------------|------|-------------|
  | `#E8E8E8` | `GS_LIGHT` | grayscale (permanent) | `SLOT_GS_LIGHT` |
  | `#909090` | `GS_MID_LIGHT` | grayscale (permanent) | `SLOT_GS_MID_LIGHT` |
  | `#505050` | `GS_MID_DARK` | grayscale (permanent) | `SLOT_GS_MID_DARK` |
  | `#1A1A1A` | `GS_DARK` | grayscale (permanent) | `SLOT_GS_DARK` |
  | `#FF00FF` | `PRIMARY` | bright signal (rewritten by mesh_type) | `good` / `bad` / `accent` / `filler` |
  | `#800080` | `SECONDARY` | muted signal (rewritten by mesh_type) | `*_muted` of same |

- [ ] Export `docs/voxel_source_palette.png` — MagicaVoxel-importable palette file with these 6 colors.
- [ ] Document authoring rules in `docs/voxel_source_palette.md`: rule of thumb, which assets get which mesh_type, how to handle mixed-role models (split into child meshes).
- [ ] `shaders/voxel_palette.gdshader` — 6-branch classifier + 4-way mesh_type switch (done).
- [ ] `VoxelMeshType` enum — `GOOD`, `BAD`, `ACCENT`, `FILLER` (done).
- [ ] Shared-material helper on `PaletteManager`: 4 pre-built `ShaderMaterial` instances (one per `mesh_type`), reused by every voxel mesh. API: `PaletteManager.get_voxel_material(VoxelMeshType.Type.GOOD)`.
- [ ] Faction swap via mesh_type: friendly warrior = `GOOD`, enemy warrior = `BAD`. Same `.vox`, same `.glb`, different material assignment. No per-instance uniform overrides needed — just point at a different shared material at spawn.
- [ ] Global palette swap: uniforms driven by `PaletteManager._push_to_shaders()`; verify voxel meshes pick it up for the "Palettes" unlock feature (GDD §8).
- [ ] Film grain post-process retained from existing setup.
- [ ] **Validation asset:** single test model using all 6 source colors → exported to Godot → voxel shader applied → cycle through all 4 `mesh_type` values at runtime → cycle through all palettes → confirm magenta-fallback appears only when a non-canonical source color is used.

### 7.2 3D Models & Animations

> **Pipeline:** All meshes authored in **MagicaVoxel** (free). Characters built as **jointed voxel puppets** — each body part is a separate voxel export, parented into a hierarchy in Godot, animated entirely via AnimationPlayer joint rotations. No skeletal rigging, no Mixamo, no Blender. Props/structures/rifle are single-mesh exports. Vertex colors are remapped to palette slots by a global shader (replaces the old "strip texture, apply uniform" pipeline).
>
> **Shared puppet rig:** Head, Torso, Upper Arm L/R, Lower Arm L/R + weapon attach point, Upper Leg L/R, Lower Leg L/R. Defined once, reused across all humanoid warriors. Animations authored once on this rig transfer to every warrior variant by parenting a different voxel body to the same joint hierarchy.

**Shared warrior animations (apply to all humanoid warriors below):** Idle · Walk · Run · Hit reaction · Death (fall) · Death (headshot)

All animations are Godot AnimationPlayer tracks on joint nodes — no imported animation clips. Estimate ~10–15 min per shared anim once the rig template exists.

#### A. Warrior Characters

| # | Model | Faction | Role-Specific Animations | Notes |
|---|-------|---------|--------------------------|-------|
| 1 | Swordsman | Both | Melee attack (sword swing) | Medium build, sword + light shield. Phase 1+. |
| 2 | Big Guy | Both | Melee attack (heavy swing) | Large build, mace/hammer, padding. Phase 6+. |
| 3 | Knight | Both | Melee attack (sword swing), Block (optional) | Armored, sword + full shield, helmet. Phase 10+. |
| 4 | Bombardier | Enemy only | Run with barrel, Arrive/place explosive, Detonate death | Low HP, runs straight to castle. Phase 6+. |
| 5 | Archer | Enemy | Aim bow, Shoot bow, Reposition step | Light build. Phase 4+. |
| 6 | Heavy Archer | Enemy | Aim bow, Shoot bow (drawn-out), Reposition walk | Medium build, large bow, quiver. Phase 7+. |
| 7 | Crossbowman | Enemy | Aim crossbow, Shoot crossbow, Reload (slow) | Medium build, crossbow. Phase 9+. |
| 8 | Bird Trainer | Enemy | Release bird, Whistle/call | Distinct silhouette (caged birds). Phase 11+. |

#### A-bis. Warrior Variants (same skeleton, gear/mesh swaps)

| # | Model | Based On | Purpose | Animations |
|---|-------|----------|---------|------------|
| 9 | Enemy Champion | Big Guy / Knight | Opportunity target (tougher variant) | Reuses base |
| 10 | War Horn carrier | Swordsman | One-shot opportunity target | +Blow horn |
| 11 | War Chief | Knight | Opportunity target, buffs nearby | +Command gesture idle |
| 12 | Elite Knight | Knight | Army upgrade: Elite Guard | Reuses Knight |
| 13 | Hardened Warrior overlay | Sword/Big/Knight | Army upgrade: helmets/padding | Attachments only |
| 14 | Larger-weapon overlay | Ranged trio | Army upgrade: Battle Training | Weapon mesh swaps |

#### B. Projectiles & Creatures

| # | Model | Animations | Notes |
|---|-------|------------|-------|
| 15 | Arrow | — | Rigid body, visible travel |
| 16 | Crossbow bolt | — | Faster than arrow |
| 17 | Kamikaze bird | Fly/flap loop, Dive, Explode-on-impact | Max 3 active |

#### C. Siege Equipment & Destructibles

| # | Model | Animations | Notes |
|---|-------|------------|-------|
| 18 | Powder Keg | Fuse flicker (optional), Explosion VFX | AoE one-shot. Phase 1+. |
| 19 | Catapult | Swing/fire cycle, Destroyed state | Drains castle HP. Phase 6+. |
| 20 | Battering Ram | Rock-forward cycle, Destroyed state | Drains castle HP. |
| 21 | Siege Tower | Roll-forward loop, Arrive/stop, Destroyed state | Opportunity target. |

#### D. Castle Structures (Zone 1)

| # | Model | Animations | Notes |
|---|-------|------------|-------|
| 22 | Stone wall section | — | Modular, tileable |
| 23 | Tower | — | Corner/keep piece, firing position |
| 24 | Gate (standard) | Open/close, Damage states (intact → cracked → broken) | Enemy attack point |
| 25 | Gate (reinforced) | Same as standard | Reinforced Gates upgrade variant |
| 26 | Rampart / battlement | — | Walk surface on walls |
| 27 | Extraction marker | Idle pulse, Active glow | Palette `accent_loot` |
| 28 | Archer Tower (friendly turret) | Idle, Fire | Archer Tower upgrade |

#### E. Battlefield Props (Zone 2)

| # | Model | Animations | Notes |
|---|-------|------------|-------|
| 29 | Rock formation (2–3 variants) | — | Cover |
| 30 | Wooden barricade | — | Cover |
| 31 | Trench edge | — | Terrain feature |
| 32 | Hay bale | — | Cover / set dressing |

#### F. Enemy Camp (Zone 3)

| # | Model | Animations | Notes |
|---|-------|------------|-------|
| 33 | Wooden palisade | — | Camp perimeter |
| 34 | Tent | — | Set dressing |
| 35 | War banner | Cloth sway (shader-based OK) | Faction identification |

#### G. Player Rifle (modern, anachronistic)

5 mod slots × 3 visual types each = 15 attachment meshes. Rarity = notch count on the same mesh, not separate models.

| # | Model | Animations | Notes |
|---|-------|------------|-------|
| 36 | Rifle body (base) | Shoot, Bolt cycle, Dry fire, Scope in/out, Breath hold sway | Shared rig |
| 37 | Barrel mods (×3) | — | Swap-on |
| 38 | Stock mods (×3) | — | Swap-on |
| 39 | Bolt mods (×3) | — | Swap-on |
| 40 | Magazine mods (×3) | — | Swap-on |
| 41 | Scope mods (×3) | — | Scope overlay is UI, not mesh |
| 42 | First-person arms | Inherits rifle anims | Gloves/sleeves |

**Totals:** 8 core warriors + 6 variants, 3 projectiles/creatures, 4 siege, 7 castle pieces, 4 battlefield props, 3 camp props, 1 rifle + 15 mod attachments + arms ≈ **52 meshes** (characters are ~10 voxel parts each; puppet rig template is shared, so authoring cost per warrior is mostly "paint the parts").

**Tools:**
- **MagicaVoxel** — all mesh authoring (free).
- **Godot AnimationPlayer** — all animations, authored directly in-engine via joint rotations on the shared puppet rig.
- **No Mixamo, no Blender, no external rigging** — the jointed-puppet approach eliminates the rigging/weight-painting pipeline entirely.

**Prototype milestone (de-risks the whole pipeline):** Model Swordsman parts in MagicaVoxel → parent into Godot hierarchy → author one walk cycle in AnimationPlayer → instance 50 copies via MultiMeshInstance3D and verify 60fps. If that loop works, every other warrior is a paint job on the same rig.

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

### 7.4 UI Assets

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
