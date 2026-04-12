# Test Progress Tracker

Status: `[ ]` not tested · `[~]` issue found · `[x]` passed

---

## Layer 1: Basic Controls

- [ ] 1.1 Movement — WASD in hub, collides with walls
- [ ] 1.2 Sprint — Shift+W faster movement
- [ ] 1.3 Crouch — Ctrl lowers camera
- [ ] 1.4 Jump — Spacebar
- [ ] 1.5 Look — Mouse rotates camera
- [ ] 1.6 Shoot — LMB in run, bolt cycles, bullet count drops
- [ ] 1.7 Scope — RMB narrows FOV, sway active
- [ ] 1.8 Breath hold — Shift while scoped, meter depletes
- [ ] 1.9 Interact — E near hub station opens panel
- [ ] 1.10 Pause — Escape during run

**Notes:**


---

## Layer 2: Warrior AI

- [ ] 2.1 Hostile spawn — Swordsmen appear at phase 1
- [ ] 2.2 Friendly spawn — Friendlies appear ~2s after run start
- [ ] 2.3 Hostile advance — Walks toward castle wall point
- [ ] 2.4 Friendly advance — Walks to frontline, then patrols
- [ ] 2.5 Melee pairing — CombatManager pairs opposing warriors
- [ ] 2.6 Melee combat — Paired warriors exchange hits, one dies
- [ ] 2.7 Bombardier — Ignores pairing, walks to castle
- [ ] 2.8 Phase gating — Only phase-appropriate types spawn
- [ ] 2.9 Ranged advance — Archer stops at firing range
- [ ] 2.10 Ranged shooting — Shoots arrow at player
- [ ] 2.11 Headshot kill — 1-shot kill bypasses armor
- [ ] 2.12 Body shot armor — Damage reduced on armored types
- [ ] 2.13 Kill scoring — Score increases per kill
- [ ] 2.14 Friendly kill penalty — Score decreases
- [ ] 2.15 Warrior death cleanup — Body freed after delay

**Notes:**


---

## Layer 3: Castle Defense

- [ ] 3.1 Castle HP init — Bar shows 100/100 on deploy
- [ ] 3.2 Wall arrival damage — Hostile reaching wall drains HP
- [ ] 3.3 Bombardier damage — Heavy damage on arrival
- [ ] 3.4 Siege equipment drain — Passive HP drain per second
- [ ] 3.5 Destroy siege equip — Shooting stops drain, awards score
- [ ] 3.6 Castle HP = 0 — Run fails "CASTLE FALLEN"
- [ ] 3.7 HP bar color — Green > yellow > red
- [ ] 3.8 Reinforced Gates — +40% HP with upgrade unlocked

**Notes:**


---

## Layer 4: Extraction

- [ ] 4.1 Window schedule — Opens after phase 2 ends
- [ ] 4.2 Zone activation — One random zone becomes visible
- [ ] 4.3 Hold to extract — E fills bar over 3s
- [ ] 4.4 Successful extract — Result screen shows
- [ ] 4.5 Damage cancels — Hit during extract cancels it
- [ ] 4.6 Window closes — Timer expires, zone deactivates
- [ ] 4.7 HUD countdown — Timer counts down accurately
- [ ] 4.8 Multiple windows — Phases 2, 4, 6 each open one

**Notes:**


---

## Layer 5: Opportunities

- [ ] 5.1 Opportunity trigger — HUD shows name + timer
- [ ] 5.2 Kill progress — Counter increments on kills
- [ ] 5.3 Completion — XP awarded on meeting target
- [ ] 5.4 Failure — Timer expires, "FAILED" announcement
- [ ] 5.5 Army unlock — First completion unlocks upgrade
- [ ] 5.6 Repeat completion — XP only, no duplicate unlock
- [ ] 5.7 Max per run — No more than 2 offered

**Notes:**


---

## Layer 6: Destructibles

- [ ] 6.1 Powder keg hit — Explodes on bullet
- [ ] 6.2 Keg AoE damage — Warriors in radius take damage
- [ ] 6.3 Keg score — 80 score awarded
- [ ] 6.4 Siege equip hit — Stops drain, 150 score
- [ ] 6.5 One-shot kill — Destroyed on first hit

**Notes:**


---

## Layer 7: Progression (Between Runs)

- [ ] 7.1 Mod generation — Choices offered on extraction
- [ ] 7.2 Equip mod — Shows [EQUIPPED] in armory
- [ ] 7.3 Unequip mod — Reverts to EQUIP button
- [ ] 7.4 Durability tick — Decrements per extraction
- [ ] 7.5 Mod depletion — Removed at 0 durability
- [ ] 7.6 Mods lost on death — Equipped mods stripped
- [ ] 7.7 Stashed mods safe — Unequipped survive death
- [ ] 7.8 Slot cap — 5 per slot max
- [ ] 7.9 Mod stats apply — Weapon stats change with mod

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

- [ ] F3 — Dev HUD shows phase, HP, warriors, FPS
- [ ] Backtick — Dev Console opens with buttons
- [ ] Spawn warrior — Appears and advances
- [ ] Kill all — All warriors removed
- [ ] Phase +1/+5 — Phase updates, new types spawn
- [ ] Castle HP adjust — Bar updates
- [ ] Open extraction — Window opens, zone activates
- [ ] Trigger opportunity — Appears on HUD
- [ ] Give mod — Appears in armory
- [ ] God mode — No damage taken
- [ ] Refill bullets — Bullet count resets

**Notes:**


---

## Issues Log

| # | Layer | Test | Issue | Status |
|---|-------|------|-------|--------|
| | | | | |
