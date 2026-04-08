class_name EnemySpotter
extends EnemyBase
## Spotter — uses binoculars to scan for the player. Doesn't shoot.
## When they spot the player (ALERT), all enemies within alert_radius
## immediately go ALERT too. Priority target — kill them first.

@export var alert_radius: float = 80.0

var _has_alerted: bool = false


func _ready() -> void:
	# Wide FOV, good sight range — they're scanning
	fov_degrees = 70.0
	max_sight_range = 200.0
	suspicion_rate = 0.5
	suspicion_decay = 0.1
	alert_threshold = 1.2
	search_duration = 10.0

	# Spotters don't shoot
	reaction_time = 999.0
	fire_interval = 999.0
	accuracy = 0.0
	health = 80.0

	# Slow scanning behavior
	initial_behavior = Behavior.SCANNING
	scan_speed = 0.2
	scan_angle = 80.0

	credit_reward = 60
	xp_reward = 30

	body_color = Color(0.2, 0.3, 0.6)  # Blue

	# Binocular glint — always visible as a warning
	glint_enabled = true
	glint_color = Color(0.7, 0.85, 1.0, 1.0)  # Blueish tint to distinguish from snipers
	glint_max_energy = 2.0
	laser_enabled = false

	super._ready()


func _set_alert_state(new_state: AlertState) -> void:
	var was_alert := alert_state == AlertState.ALERT
	super._set_alert_state(new_state)

	# On first transition to ALERT, broadcast to all nearby enemies
	if new_state == AlertState.ALERT and not was_alert and not _has_alerted:
		_has_alerted = true
		_broadcast_alert()


func _broadcast_alert() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for node in enemies:
		if node == self or not node is EnemyBase:
			continue
		var enemy_node: EnemyBase = node
		if enemy_node.is_dead:
			continue
		if global_position.distance_to(enemy_node.global_position) > alert_radius:
			continue
		# Force them to ALERT with player's position
		enemy_node.suspicion = enemy_node.alert_threshold
		enemy_node.last_known_player_pos = last_known_player_pos
		enemy_node._set_alert_state(AlertState.ALERT)


## Reset alert broadcast when returning to unaware
func _update_alert_state(delta: float) -> void:
	super._update_alert_state(delta)
	if alert_state == AlertState.UNAWARE:
		_has_alerted = false


## Spotters don't shoot — just track the player when ALERT
func _update_combat(delta: float) -> void:
	if alert_state != AlertState.ALERT:
		return
	_face_player_smooth(delta)
