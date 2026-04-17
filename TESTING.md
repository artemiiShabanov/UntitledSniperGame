# Test Progress Tracker

Status: `[ ]` not tested · `[~]` issue found · `[x]` passed

---

## Layer 1: Basic Controls

- [x] 1.1 Movement — WASD in hub, collides with walls
- [x] 1.2 Sprint — Shift+W faster movement
- [x] 1.3 Crouch — Ctrl lowers camera
- [x] 1.4 Jump — Spacebar
- [x] 1.5 Look — Mouse rotates camera
- [x] 1.6 Shoot — LMB in run, bolt cycles, bullet count drops
- [x] 1.7 Scope — RMB narrows FOV, sway active
- [x] 1.8 Breath hold — Shift while scoped, meter depletes
- [x] 1.9 Interact — E near hub station opens panel
- [x] 1.10 Pause — Escape during run

**Notes:**


---

## Layer 2: Warrior AI

- [x] 2.1 Hostile spawn — Swordsmen appear at phase 1
- [x] 2.2 Friendly spawn — Friendlies appear ~2s after run start
- [x] 2.3 Hostile advance — Walks toward castle wall point
- [x] 2.4 Friendly advance — Walks to frontline, then patrols
- [x] 2.5 Melee pairing — CombatManager pairs opposing warriors
- [x] 2.6 Melee combat — Paired warriors exchange hits, one dies
- [x] 2.7 Bombardier — Ignores pairing, walks to castle
- [x] 2.8 Phase gating — Only phase-appropriate types spawn
- [x] 2.9 Ranged advance — Archer stops at firing range
- [x] 2.10 Ranged shooting — Shoots arrow at player
- [x] 2.11 Headshot kill — 1-shot kill bypasses armor
- [x] 2.12 Body shot armor — Damage reduced on armored types
- [x] 2.13 Kill scoring — Score increases per kill
- [x] 2.14 Friendly kill penalty — Score decreases
- [x] 2.15 Warrior death cleanup — Body freed after delay

**Notes:**


---

## Layer 3: Castle Defense

- [x] 3.1 Castle HP init — Bar shows 100/100 on deploy
- [x] 3.2 Wall arrival damage — Hostile reaching wall drains HP
- [x] 3.3 Bombardier damage — Heavy damage on arrival
- [x] 3.4 Siege equipment drain — Passive HP drain per second
- [x] 3.5 Destroy siege equip — Shooting stops drain, awards score
- [x] 3.6 Castle HP = 0 — Run fails "CASTLE FALLEN"
- [x] 3.7 HP bar color — Green > yellow > red
- [ ] 3.8 Reinforced Gates — +40% HP with upgrade unlocked (moved to Layer 8)

**Notes:**


---

## Layer 4: Extraction

- [x] 4.1 Window schedule — Opens after phase 2 ends
- [x] 4.2 Zone activation — One random zone becomes visible
- [x] 4.3 Hold to extract — E fills bar over 3s
- [x] 4.4 Successful extract — Result screen shows
- [x] 4.5 Damage cancels — Hit during extract cancels it
- [x] 4.6 Window closes — Timer expires, zone deactivates
- [x] 4.7 HUD countdown — Timer counts down accurately
- [x] 4.8 Multiple windows — Phases 2, 4, 6 each open one

**Notes:**


---

## Layer 5: Opportunities

- [x] 5.1 Opportunity trigger — HUD shows name + timer
- [x] 5.2 Kill progress — Counter increments on kills
- [x] 5.3 Completion — XP awarded on meeting target
- [x] 5.4 Failure — Timer expires, "FAILED" announcement
- [x] 5.5 Army unlock — First completion unlocks upgrade
- [x] 5.6 Repeat completion — XP only, no duplicate unlock
- [x] 5.7 Max per run — No more than 2 offered

**Notes:**


---

## Layer 6: Destructibles

- [x] 6.1 Powder keg hit — Explodes on bullet
- [x] 6.2 Keg AoE damage — Warriors in radius take damage
- [x] 6.3 Keg score — 80 score awarded
- [x] 6.4 Siege equip hit — Stops drain, 150 score
- [x] 6.5 One-shot kill — Destroyed on first hit

**Notes:**


---

## Layer 7: Progression (Between Runs)

- [x] 7.1 Mod generation — Choices offered on extraction
- [x] 7.2 Equip mod — Shows [EQUIPPED] in armory
- [x] 7.3 Unequip mod — Reverts to EQUIP button
- [x] 7.4 Durability tick — Decrements per extraction
- [x] 7.5 Mod depletion — Removed at 0 durability
- [x] 7.6 Mods lost on death — Equipped mods stripped
- [x] 7.7 Stashed mods safe — Unequipped survive death
- [x] 7.8 Slot cap — 5 per slot max (or replace existing)
- [x] 7.9 Mod stats apply — Weapon stats change with mod

**Notes:**


---

## Layer 8: Skills & Army Upgrades

- [ ] 8.1 Skill display — 4 skills shown with tier
- [ ] 8.2 Purchase tier 1 — XP deducted, tier up
- [ ] 8.3 Tier 2 cost — Higher cost shown
- [ ] 8.4 Max tier — Button disabled
- [ ] 8.5 Insufficient XP — "need X more" shown
- [ ] 8.6 Stat application — Deep Pockets adds bullets
- [ ] 8.7 Army upgrade display — 6 upgrades in War Room
- [ ] 8.8 Upgrade effect — Hardened Warriors +30% friendly HP

**Notes:**


---

## Layer 9: Hub Flow

- [ ] 9.1 Hub load — Scene loads, player spawns
- [ ] 9.2 Deploy station — Mission list shows Castle Keep
- [ ] 9.3 Deploy flow — Level loads, run begins
- [ ] 9.4 Armory station — Panel opens with slot tabs
- [ ] 9.5 Skill station — Tiered display opens
- [ ] 9.6 War Room station — Army upgrades displayed
- [ ] 9.7 Stats station — Lifetime stats shown
- [ ] 9.8 Palette station — Palette picker opens
- [ ] 9.9 Save station — "GAME SAVED" feedback
- [ ] 9.10 Panel close — Escape closes panel
- [ ] 9.11 XP display — Correct XP total shown

**Notes:**


---

## Layer 10: Grid Level Generation

- [ ] 10.1 Level generates — No errors on deploy
- [ ] 10.2 Zone layout — Castle/battlefield/enemy zones correct
- [ ] 10.3 Player spawn — On castle tower, elevated
- [ ] 10.4 Extraction zones — Appear in battlefield
- [ ] 10.5 Warrior paths — Navigate via NavMesh
- [ ] 10.6 Hostile spawn markers — In enemy camp zone
- [ ] 10.7 Friendly spawn markers — Behind castle zone
- [ ] 10.8 Frontline markers — In battlefield zone
- [ ] 10.9 Block variety — Different layout each restart
- [ ] 10.10 Performance — FPS > 30 at phase 10+

**Notes:**


---

## Dev Tools

- [x] F3 — Dev HUD shows phase, HP, warriors, FPS
- [x] Backtick — Dev Console opens with buttons
- [x] Spawn warrior — Appears and advances
- [x] Kill all — All warriors removed
- [x] Phase +1/+5 — Phase updates, new types spawn
- [x] Castle HP adjust — Bar updates
- [x] Open extraction — Window opens, zone activates
- [x] Trigger opportunity — Appears on HUD
- [x] Give mod — Appears in armory
- [x] God mode — No damage taken
- [x] Refill bullets — Bullet count resets

**Notes:**


---

## Issues Log

| # | Layer | Test | Issue | Status |
|---|-------|------|-------|--------|
| | | | | |
