class_name WarriorKnight
extends WarriorBase
## Knight — elite armored warrior. Phase 10+.
## Very high HP, heavy armor, medium speed. Headshots are efficient.

func _ready() -> void:
	max_hp = 300
	armor = 60
	move_speed = 3.0
	castle_damage = 10
	base_score = Scoring.KNIGHT
	hit_chance = 0.65
	melee_damage = 30
	attack_interval = 0.9
	min_phase = 10
	super._ready()
