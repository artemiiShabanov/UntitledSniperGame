class_name WarriorBombardier
extends WarriorBase
## Bombardier — suicide runner. Phase 6+. Enemy-only.
## Ignores warriors, runs straight to castle. Heavy castle damage on arrival.
## Low HP, no armor, fast. CombatManager skips bombardiers (not pairable).

func _ready() -> void:
	max_hp = 60
	armor = 0
	move_speed = 4.5
	castle_damage = 25
	base_score = Scoring.BOMBARDIER
	hit_chance = 0.0
	melee_damage = 0
	attack_interval = 999.0
	min_phase = 6
	super._ready()


func is_pairable() -> bool:
	## Bombardiers are never paired — they always advance to the castle.
	return false
