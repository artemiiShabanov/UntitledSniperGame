extends Control
## Debug UI for spawning individual enemy types during testing.
## Attach to the dev test level. Press number keys 1-7 to spawn enemies
## at a fixed position in front of the player.

const ENEMY_SCENES: Array[Dictionary] = [
	{"key": KEY_1, "name": "Lookout", "scene": "res://scenes/enemy/enemy_lookout.tscn"},
	{"key": KEY_2, "name": "Spotter", "scene": "res://scenes/enemy/enemy_spotter.tscn"},
	{"key": KEY_3, "name": "Marksman", "scene": "res://scenes/enemy/enemy_marksman.tscn"},
	{"key": KEY_4, "name": "Drone", "scene": "res://scenes/enemy/enemy_drone.tscn"},
	{"key": KEY_5, "name": "Ghost", "scene": "res://scenes/enemy/enemy_ghost.tscn"},
	{"key": KEY_6, "name": "Heavy", "scene": "res://scenes/enemy/enemy_heavy.tscn"},
]

const SPAWN_DISTANCE: float = 30.0  ## Meters in front of player
const PATROL_RADIUS: float = 10.0  ## For patrol-based enemies

var _spawned: Array[Node] = []
var _label: Label


func _ready() -> void:
	# Build the hint label
	_label = Label.new()
	_label.name = "SpawnHints"
	_label.position = Vector2(10, 10)
	var text := "=== ENEMY TEST SPAWNER ===\n"
	for entry in ENEMY_SCENES:
		var key_name: String = OS.get_keycode_string(entry["key"])
		text += "[%s] Spawn %s\n" % [key_name, entry["name"]]
	text += "[0] Clear all spawned\n"
	text += "[9] Spawn all types"
	_label.text = text
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)

	# Don't capture mouse — let player handle that
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Clear all
		if event.keycode == KEY_0:
			_clear_all()
			return

		# Spawn all types
		if event.keycode == KEY_9:
			_spawn_all()
			return

		# Individual spawn
		for entry in ENEMY_SCENES:
			if event.keycode == entry["key"]:
				_spawn_enemy(entry["scene"], entry["name"])
				return


func _spawn_enemy(scene_path: String, enemy_name: String) -> void:
	var scene: PackedScene = load(scene_path)
	if not scene:
		push_warning("EnemyTestSpawner: failed to load %s" % scene_path)
		return

	var enemy: Node3D = scene.instantiate()

	# Find player and spawn in front of them
	var players := get_tree().get_nodes_in_group("player")
	var spawn_pos := Vector3(0, 0, -SPAWN_DISTANCE)
	if not players.is_empty():
		var player: Node3D = players[0]
		var forward := -player.global_basis.z
		forward.y = 0.0
		forward = forward.normalized()
		spawn_pos = player.global_position + forward * SPAWN_DISTANCE

	# Set up patrol points for enemies that need them
	if "patrol_points" in enemy:
		var patrol: Array[Vector3] = []
		for i in 4:
			var angle := TAU * float(i) / 4.0
			patrol.append(spawn_pos + Vector3(cos(angle) * PATROL_RADIUS, 0, sin(angle) * PATROL_RADIUS))
		enemy.patrol_points = patrol

	get_tree().root.get_child(0).add_child(enemy)
	enemy.global_position = spawn_pos

	_spawned.append(enemy)
	print("Spawned: %s at %s" % [enemy_name, spawn_pos])


func _spawn_all() -> void:
	var offset := 0.0
	var players := get_tree().get_nodes_in_group("player")
	var player_pos := Vector3.ZERO
	var forward := Vector3(0, 0, -1)
	var right := Vector3(1, 0, 0)

	if not players.is_empty():
		var player: Node3D = players[0]
		forward = -player.global_basis.z
		forward.y = 0.0
		forward = forward.normalized()
		right = forward.cross(Vector3.UP).normalized()
		player_pos = player.global_position

	for i in ENEMY_SCENES.size():
		var entry: Dictionary = ENEMY_SCENES[i]
		var scene: PackedScene = load(entry["scene"])
		if not scene:
			continue
		var enemy: Node3D = scene.instantiate()

		# Spread enemies in a line
		var lateral := (float(i) - float(ENEMY_SCENES.size()) / 2.0) * 5.0
		var spawn_pos := player_pos + forward * SPAWN_DISTANCE + right * lateral

		if "patrol_points" in enemy:
			var patrol: Array[Vector3] = []
			for j in 4:
				var angle := TAU * float(j) / 4.0
				patrol.append(spawn_pos + Vector3(cos(angle) * PATROL_RADIUS, 0, sin(angle) * PATROL_RADIUS))
			enemy.patrol_points = patrol

		get_tree().root.get_child(0).add_child(enemy)
		enemy.global_position = spawn_pos
		_spawned.append(enemy)
		print("Spawned: %s at %s" % [entry["name"], spawn_pos])


func _clear_all() -> void:
	for enemy in _spawned:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_spawned.clear()
	print("Cleared all test enemies")
