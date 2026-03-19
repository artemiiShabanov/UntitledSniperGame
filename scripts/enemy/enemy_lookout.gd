class_name EnemyLookout
extends EnemyBase
## Lookout — the most basic enemy type.
## Stationary, narrow FOV, slow reactions. Tutorial-tier threat.

func _ready() -> void:
	# Override base defaults for a weak, stationary lookout
	fov_degrees = 60.0
	max_sight_range = 60.0
	suspicion_rate = 0.3
	suspicion_decay = 0.15
	alert_threshold = 1.0
	search_duration = 6.0

	reaction_time = 2.0
	fire_interval = 3.0
	accuracy = 0.4
	health = 100.0

	credit_reward = 50
	xp_reward = 25

	super._ready()
