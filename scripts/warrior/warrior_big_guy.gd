class_name WarriorBigGuy
extends WarriorBase
## Big Guy — tanky melee warrior. Phase 6+.
## High HP, light armor, slow speed, heavy castle damage.
## Takes 2 body shots or 1 headshot.

func _ready() -> void:
	max_hp = 200
	armor = 30
	move_speed = 2.5
	castle_damage = 15
	base_score = Scoring.BIG_GUY
	hit_chance = 0.6
	melee_damage = 35
	attack_interval = 1.0
	min_phase = 6
	super._ready()
