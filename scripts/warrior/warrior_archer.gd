class_name WarriorArcher
extends WarriorRangedBase
## Archer — basic ranged warrior. Phase 4+.
## Low accuracy, visible arrow travel, slow advance.

func _ready() -> void:
	max_hp = 60
	armor = 0
	move_speed = 2.5
	castle_damage = 0
	base_score = Scoring.ARCHER
	min_phase = 4
	firing_range = 100.0
	accuracy = 0.2
	shoot_interval = 3.0
	projectile_speed = 35.0
	reposition_chance = 0.0
	super._ready()
