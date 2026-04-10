class_name WarriorSwordsman
extends WarriorBase
## Swordsman — basic melee warrior. Phase 1+.
## Low HP, no armor, medium speed. Cheap and plentiful.

func _ready() -> void:
	max_hp = 80
	armor = 0
	move_speed = 3.5
	castle_damage = 5
	base_score = Scoring.SWORDSMAN
	hit_chance = 0.55
	melee_damage = 20
	attack_interval = 0.8
	min_phase = 1
	super._ready()
