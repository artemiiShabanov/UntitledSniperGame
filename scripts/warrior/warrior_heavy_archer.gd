class_name WarriorHeavyArcher
extends WarriorRangedBase
## Heavy Archer — mid-tier ranged warrior. Phase 7+.
## Medium accuracy, repositions between shots.

func _ready() -> void:
	max_hp = 80
	armor = 0
	move_speed = 2.8
	castle_damage = 0
	base_score = Scoring.HEAVY_ARCHER
	min_phase = 7
	firing_range = 90.0
	accuracy = 0.35
	shoot_interval = 2.5
	projectile_speed = 40.0
	reposition_chance = 0.5
	reposition_radius = 12.0
	super._ready()
