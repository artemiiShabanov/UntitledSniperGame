class_name Scoring
## Central scoring constants per GDD §3.
## Warriors reference these when calling RunManager.record_kill_with_score().

## Per-type base scores (hostile kills)
const SWORDSMAN: int = 20
const BIG_GUY: int = 40
const KNIGHT: int = 70
const BOMBARDIER: int = 50
const ARCHER: int = 40
const HEAVY_ARCHER: int = 60
const CROSSBOWMAN: int = 80
const BIRD_TRAINER: int = 100

## Destructible scores
const POWDER_KEG: int = 80
const SIEGE_EQUIPMENT: int = 150

## Headshot multiplier (applied in RunManager.record_kill_with_score)
const HEADSHOT_MULT: float = 2.0

## Friendly kill penalty
const FRIENDLY_KILL_PENALTY: int = 30
