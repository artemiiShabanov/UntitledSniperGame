class_name EnemyLookout
extends EnemyBase
## Lookout — the most basic enemy type.
## Stationary, narrow FOV, slow reactions. Tutorial-tier threat.

func _ready() -> void:
	# Override base defaults for a weak, stationary lookout
	fov_degrees = 30.0
	max_sight_range = 150.0  ## Can spot player at long range (but slow to react)
	suspicion_rate = 0.3
	suspicion_decay = 0.15
	alert_threshold = 1.0
	search_duration = 6.0

	reaction_time = 2.0
	fire_interval = 3.0
	accuracy = 0.4
	inaccuracy_deg = 6.0  ## Poor accuracy at range
	health = 100.0

	credit_reward = 50
	xp_reward = 25

	initial_behavior = Behavior.SCANNING
	scan_speed = 0.2
	scan_angle = 45.0

	body_color = Color(0.6, 0.2, 0.2)  # Dull red

	super._ready()
