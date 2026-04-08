class_name EnemyMarksman
extends EnemyBase
## Marksman — competent sniper that repositions periodically and reactively.
## Moves to a new position every 20s while UNAWARE. When hearing sound or
## taking damage, repositions first, then goes SUSPICIOUS. Forces the player
## to re-acquire the target after every engagement.


func _ready() -> void:
	fov_degrees = 40.0
	max_sight_range = 180.0
	suspicion_rate = 0.6
	suspicion_decay = 0.15
	alert_threshold = 0.8
	search_duration = 10.0

	reaction_time = 2.0
	fire_interval = 2.0
	accuracy = 0.65
	inaccuracy_deg = 4.0
	health = 100.0

	initial_behavior = Behavior.SCANNING
	scan_speed = 0.3
	scan_angle = 50.0

	# Reposition behavior
	can_reposition = true
	reposition_speed = 4.0
	patrol_speed = reposition_speed
	auto_reposition_interval = 20.0

	credit_reward = 75
	xp_reward = 35

	body_color = Color(0.5, 0.35, 0.15)  # Brown

	glint_enabled = true
	laser_enabled = true

	super._ready()
