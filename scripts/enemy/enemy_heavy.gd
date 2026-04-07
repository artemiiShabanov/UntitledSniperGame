class_name EnemyHeavy
extends EnemyBase
## Heavy Sniper — armored enemy that shrugs off standard ammo.
## Requires AP ammo or a headshot to deal real damage. Stationary,
## slow reactions, but hits hard. High bounty for taking them down.


func _ready() -> void:
	fov_degrees = 60.0
	max_sight_range = 150.0
	suspicion_rate = 0.3
	suspicion_decay = 0.1
	alert_threshold = 1.0
	search_duration = 12.0

	# Slow but deadly
	reaction_time = 2.0
	fire_interval = 3.5
	accuracy = 0.7
	inaccuracy_deg = 3.5
	enemy_bullet_speed = 250.0
	shot_damage = 2.0  # Can take 2 lives in one hit
	health = 200.0

	# Armored — core mechanic
	is_armored = true
	armor_reduction = 0.15  # Standard ammo does 15% damage

	# Stationary
	initial_behavior = Behavior.SCANNING
	scan_speed = 0.15
	scan_angle = 40.0

	# High reward
	credit_reward = 120
	xp_reward = 50

	body_color = Color(0.35, 0.25, 0.15)  # Dark brown / armored look

	glint_enabled = true
	glint_color = Color(1.0, 0.6, 0.2, 1.0)  # Orange tint — warning color
	glint_max_energy = 4.0
	laser_enabled = true
	laser_color = Color(1.0, 0.3, 0.0, 0.6)

	super._ready()
