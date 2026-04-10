class_name WarriorCrossbowman
extends WarriorRangedBase
## Crossbowman — high-accuracy, slow-reload ranged warrior. Phase 9+.
## Dangerous but punishable during long reload.

func _ready() -> void:
	max_hp = 70
	armor = 10
	move_speed = 2.2
	castle_damage = 0
	base_score = Scoring.CROSSBOWMAN
	min_phase = 9
	firing_range = 100.0
	accuracy = 0.5
	shoot_interval = 4.0
	projectile_speed = 55.0
	reposition_chance = 0.2
	reposition_radius = 8.0
	super._ready()
