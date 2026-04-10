# Sniper Extraction: The Last Rifle — Test Plan

Dev tools: **F3** = Dev HUD overlay, **Backtick (`)** = Dev Console

---

## Layer 1: Basic Controls

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 1.1 | Movement | WASD in hub | Player moves, collides with walls |
| 1.2 | Sprint | Hold Shift + W | Faster movement, footstep sounds |
| 1.3 | Crouch | Hold Ctrl | Camera lowers, collision height shrinks |
| 1.4 | Jump | Spacebar | Player jumps, gravity returns |
| 1.5 | Look | Mouse movement | Camera rotates smoothly |
| 1.6 | Shoot | LMB (in run) | Bullet spawns, bolt cycles, bullet count decreases |
| 1.7 | Scope | RMB | FOV narrows, sway active, crosshair hides |
| 1.8 | Breath hold | Shift while scoped | Sway reduces, meter depletes |
| 1.9 | Interact | E near hub station | Panel opens, mouse visible |
| 1.10 | Pause | Escape during run | Pause menu appears |

---

## Layer 2: Warrior AI

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 2.1 | Hostile spawn | Deploy, wait for phase 1 | Swordsmen appear at hostile_spawn_points |
| 2.2 | Friendly spawn | Deploy, wait ~2s after run start | Friendly warriors appear at friendly_spawn_points |
| 2.3 | Hostile advance | Watch hostile swordsman | Walks toward random castle_wall_point |
| 2.4 | Friendly advance | Watch friendly swordsman | Walks toward frontline_point, then patrols |
| 2.5 | Melee pairing | Let warriors meet | CombatManager pairs them, they face each other |
| 2.6 | Melee combat | Watch paired warriors | Exchange hits, one dies, winner returns to IDLE/ADVANCING |
| 2.7 | Bombardier | Wait for phase 6+, watch bombardier | Ignores pairing, walks straight to castle |
| 2.8 | Phase gating | Dev: set phase to 1 | Only swordsmen spawn. Set to 10+: knights appear |
| 2.9 | Ranged advance | Wait for phase 4+, watch archer | Stops at firing range, does not advance further |
| 2.10 | Ranged shooting | Watch archer at range | Shoots arrow at player, bullet whizz near misses |
| 2.11 | Headshot kill | Shoot warrior in head | Dies in 1 shot regardless of armor |
| 2.12 | Body shot armor | Shoot knight in body | Damage reduced by armor value |
| 2.13 | Kill scoring | Kill hostile warrior | Score increases by warrior's base_score value |
| 2.14 | Friendly kill penalty | Shoot friendly warrior | Score decreases, kill feed shows penalty |
| 2.15 | Warrior death cleanup | Kill warrior, wait 5s | Body fades and is freed |

---

## Layer 3: Castle Defense

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 3.1 | Castle HP init | Deploy | Castle HP bar shows 100/100 (or upgraded value) |
| 3.2 | Wall arrival damage | Let hostile reach castle wall | Castle HP decreases by warrior's castle_damage |
| 3.3 | Bombardier damage | Let bombardier reach castle | Heavy castle_damage dealt |
| 3.4 | Siege equipment drain | Dev: place siege equipment | Castle HP ticks down per second |
| 3.5 | Destroy siege equip | Shoot siege equipment | Draining stops, score awarded |
| 3.6 | Castle HP = 0 | Dev: set HP to 1, let enemy hit | Run fails with "CASTLE FALLEN" title |
| 3.7 | HP bar color | Watch bar at various HP levels | Green > 50%, yellow > 25%, red < 25% |
| 3.8 | Reinforced Gates | Unlock upgrade, deploy | Castle HP shows +40% bonus |

---

## Layer 4: Extraction

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 4.1 | Window schedule | Reach end of phase 2 | "EXTRACTION OPEN" appears, 15s timer |
| 4.2 | Zone activation | Extraction opens | One random zone becomes visible |
| 4.3 | Hold to extract | Enter zone, hold E | Extraction bar fills over 3s |
| 4.4 | Successful extract | Complete hold | Run succeeds, result screen shows |
| 4.5 | Damage cancels | Hold E, take hit | Extraction cancelled, bar resets |
| 4.6 | Window closes | Wait out timer without extracting | "EXTRACTION CLOSED", zone deactivates |
| 4.7 | HUD countdown | Watch extraction window display | Timer counts down accurately |
| 4.8 | Multiple windows | Play through phases 2, 4, 6 | Each opens a window per schedule |

---

## Layer 5: Opportunities

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 5.1 | Opportunity trigger | Dev: trigger random opportunity | HUD shows opportunity name + timer |
| 5.2 | Kill progress | Kill enemies during opportunity | Progress counter increments (e.g., "2/3") |
| 5.3 | Completion | Meet kill target within timer | "COMPLETE" announcement, XP awarded |
| 5.4 | Failure | Let timer expire | "FAILED" announcement, no reward |
| 5.5 | Army unlock | Complete opportunity first time | Army upgrade unlocked, announcement |
| 5.6 | Repeat completion | Complete same opportunity again | XP reward, no duplicate unlock |
| 5.7 | Max per run | Complete 2 opportunities | No more offered (MAX_OPPORTUNITIES_PER_RUN = 2) |

---

## Layer 6: Destructibles

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 6.1 | Powder keg hit | Shoot powder keg | Explodes, VFX, sound |
| 6.2 | Keg AoE damage | Shoot keg near warriors | Warriors in radius take damage with falloff |
| 6.3 | Keg score | Destroy powder keg | 80 score awarded |
| 6.4 | Siege equip hit | Shoot siege equipment | Stops draining, darkens, 150 score |
| 6.5 | One-shot kill | Shoot destructible once | Destroyed on first bullet hit |

---

## Layer 7: Progression (Between Runs)

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 7.1 | Mod generation | Extract successfully | Mod choices offered (implied by score) |
| 7.2 | Equip mod | Open Armory, click EQUIP | Mod shows [EQUIPPED], stats applied |
| 7.3 | Unequip mod | Click equipped mod | Unequips, reverts to EQUIP button |
| 7.4 | Durability tick | Extract successfully with equipped mod | Durability decrements by 1 |
| 7.5 | Mod depletion | Mod reaches 0 durability | Auto-removed from inventory |
| 7.6 | Mods lost on death | Die during run | All equipped mods removed |
| 7.7 | Stashed mods safe | Die with stashed (unequipped) mods | Unequipped mods preserved |
| 7.8 | Slot cap | Have 5 mods in one slot, try adding 6th | Rejected, inventory full |
| 7.9 | Mod stats apply | Equip barrel mod, deploy | Weapon stats changed (check Dev HUD) |

---

## Layer 8: Skills & Army Upgrades

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 8.1 | Skill display | Open Skill Board | 4 skills shown with current tier |
| 8.2 | Purchase tier 1 | Have enough XP, click buy | XP deducted, tier incremented |
| 8.3 | Tier 2 cost | After tier 1 purchase | Higher cost shown for tier 2 |
| 8.4 | Max tier | Purchase all tiers of a skill | Shows "MAX TIER", button disabled |
| 8.5 | Insufficient XP | Try buying with too little XP | Button disabled, "need X more" shown |
| 8.6 | Stat application | Purchase Deep Pockets tier 1 | Bullets = 30 + 10 = 40 at run start |
| 8.7 | Army upgrade display | Open War Room | 6 upgrades shown, locked ones dimmed |
| 8.8 | Upgrade effect | Unlock Hardened Warriors, deploy | Friendly warriors have +30% HP |

---

## Layer 9: Hub Flow

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 9.1 | Hub load | Return from run or start game | Hub scene loads, player spawns |
| 9.2 | Deploy station | Interact with Deploy Board | Mission list shows Castle Keep |
| 9.3 | Deploy flow | Select Castle Keep | Level loads, run begins |
| 9.4 | Armory station | Interact with Armory | Armory panel opens with slot tabs |
| 9.5 | Skill station | Interact with Skill Board | Skill shop opens with tiered display |
| 9.6 | War Room station | Interact with War Room | Army upgrades displayed |
| 9.7 | Stats station | Interact with Stats Terminal | Stats panel shows lifetime stats |
| 9.8 | Palette station | Interact with Palettes | Palette picker opens |
| 9.9 | Save station | Interact with Save Terminal | "GAME SAVED" feedback appears |
| 9.10 | Panel close | Press Escape with panel open | Panel closes, mouse captured |
| 9.11 | XP display | Earn XP, return to hub | XP label shows correct total |

---

## Layer 10: Grid Level Generation

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 10.1 | Level generates | Deploy Castle Keep | Level builds without errors |
| 10.2 | Zone layout | Check Dev HUD warrior spawn dirs | Castle zone rows 0-2, battlefield 3-9, enemy 10-14 |
| 10.3 | Player spawn | Observe spawn position | On castle tower, elevated view |
| 10.4 | Extraction zones | Open extraction window | Zone appears in battlefield area |
| 10.5 | Warrior paths | Watch warriors advance | Navigate around obstacles via NavMesh |
| 10.6 | Spawn markers | Hostile spawn from zone 3 edge | Hostile markers in enemy camp blocks |
| 10.7 | Friendly markers | Friendly spawn from zone 1 | Friendly markers behind castle blocks |
| 10.8 | Frontline markers | Watch friendly patrol | Patrol near frontline points in zone 2 |
| 10.9 | Block variety | Restart level multiple times | Different block configurations each time |
| 10.10 | Performance | Reach phase 10+ with many warriors | FPS stays above 30 (check Dev HUD) |

---

## Dev Console Quick Tests

These use the dev console (backtick key) for rapid iteration:

| Test | Console Action | What to Verify |
|------|---------------|----------------|
| Warrior spawning works | "Spawn Hostile Swordsman" | Warrior appears, advances |
| Combat pairs form | Spawn 1 hostile + 1 friendly | They meet and fight |
| Phase escalation | "Phase +5" multiple times | Tougher enemies spawn |
| Castle HP danger | "Castle HP = 1" | HP bar red, next hit = failure |
| Extraction flow | "Open Extraction (15s)" | Window opens, zone activates |
| Opportunity flow | "Trigger Random Opportunity" | Opportunity appears on HUD |
| Mod system | "Give Random Mod" then check Armory | Mod appears in inventory |
| God mode | "Toggle God Mode" then get hit | No damage taken |
| Kill all | Spawn many warriors, "Kill All" | All removed instantly |
