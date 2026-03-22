class_name BaseLevel
extends Node3D
## Attach to the root of every level scene.
## Finds spawn points, positions the player, and provides helpers
## for systems that need level info (enemy spawner, extraction, etc.).

@export var level_data: LevelData

## Future hooks for Layer 10 — references for TimeOfDay / Weather managers
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var world_env: WorldEnvironment = $WorldEnvironment

var player: CharacterBody3D
var extraction_zone: ExtractionZone
var rng: RandomNumberGenerator
var _unused_enemy_spawns: Array[SpawnPoint] = []  ## Spawns not picked this run


func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.randomize()

	_find_player()
	_setup_run_variation()
	_place_player_at_spawn()

	# Apply run time override from level data if set
	if level_data and level_data.run_time_override > 0.0:
		RunManager.run_timer = level_data.run_time_override

	# If loaded directly (not via deploy), auto-start a run for dev convenience
	if RunManager.game_state != RunManager.GameState.DEPLOYING and \
			RunManager.game_state != RunManager.GameState.IN_RUN:
		RunManager.run_timer = RunManager.default_run_time
		RunManager.lives = RunManager.default_lives
		RunManager.max_lives = RunManager.default_lives
		RunManager.is_dead = false
		RunManager.begin_run()


## ── Run variation ───────────────────────────────────────────────────────────

func _setup_run_variation() -> void:
	_fill_level_slots()
	_spawn_enemies()
	_pick_extraction_zone()
	_roll_events()


func _fill_level_slots() -> void:
	for node in _find_all_recursive(self):
		if node is LevelSlot and node.slot_data and not node.slot_data.variants.is_empty():
			var variant: PackedScene = node.slot_data.variants[rng.randi() % node.slot_data.variants.size()]
			var chunk := variant.instantiate()
			node.add_child(chunk)


func _spawn_enemies() -> void:
	if not level_data or not level_data.enemy_pool:
		return

	var spawns := get_enemy_spawns()
	if spawns.is_empty():
		return

	# Shuffle and pick a subset
	var shuffled := spawns.duplicate()
	for i in range(shuffled.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: SpawnPoint = shuffled[j]
		shuffled[j] = shuffled[i]
		shuffled[i] = tmp

	var count := rng.randi_range(level_data.enemy_count_range.x, level_data.enemy_count_range.y)
	count = mini(count, shuffled.size())

	var used_counts: Dictionary = {}
	for i in count:
		var spawn: SpawnPoint = shuffled[i]
		var scene := level_data.enemy_pool.pick_random(rng, used_counts)
		if scene == null:
			continue

		var enemy := scene.instantiate()
		enemy.global_position = spawn.global_position
		enemy.rotation.y = deg_to_rad(spawn.facing_direction)

		if spawn.behavior_tag != "default" and "initial_behavior" in enemy:
			enemy.initial_behavior = spawn.behavior_tag

		add_child(enemy)

		# Track used counts for max_per_run
		var path := scene.resource_path
		used_counts[path] = used_counts.get(path, 0) + 1

	# Store unused spawns for reinforcement events
	for i in range(count, shuffled.size()):
		_unused_enemy_spawns.append(shuffled[i])


func _pick_extraction_zone() -> void:
	var zones: Array[ExtractionZone] = []
	for node in _find_all_recursive(self):
		if node is ExtractionZone:
			zones.append(node)

	if zones.is_empty():
		return

	# Shuffle zones
	for i in range(zones.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: ExtractionZone = zones[j]
		zones[j] = zones[i]
		zones[i] = tmp

	var keep_count := 1
	if level_data:
		keep_count = mini(level_data.extraction_count, zones.size())

	extraction_zone = zones[0]
	for i in range(keep_count, zones.size()):
		zones[i].queue_free()


func _roll_events() -> void:
	if not level_data or level_data.level_events_pool.is_empty():
		return

	var selected: Array[LevelEventData] = []
	for event_data in level_data.level_events_pool:
		if rng.randf() <= event_data.probability:
			selected.append(event_data)

	if selected.is_empty():
		return

	# Limit to max_events_per_run
	while selected.size() > level_data.max_events_per_run:
		selected.remove_at(rng.randi() % selected.size())

	var runner := LevelEventRunner.new()
	runner.name = "LevelEventRunner"
	runner.setup(selected, rng, self)
	add_child(runner)


## ── Spawn helpers ────────────────────────────────────────────────────────────

func get_spawn_points(type: SpawnPoint.Type) -> Array[SpawnPoint]:
	var result: Array[SpawnPoint] = []
	for child in _find_all_recursive(self):
		if child is SpawnPoint and child.spawn_type == type:
			result.append(child)
	return result


func get_player_spawn() -> SpawnPoint:
	var spawns := get_spawn_points(SpawnPoint.Type.PLAYER)
	if spawns.size() > 0:
		return spawns[0]
	return null


func get_enemy_spawns() -> Array[SpawnPoint]:
	return get_spawn_points(SpawnPoint.Type.ENEMY)


## ── Internal ─────────────────────────────────────────────────────────────────

func _find_player() -> void:
	# Player is instanced as a direct child of the level
	for child in get_children():
		if child.is_in_group("player"):
			player = child
			return


func _place_player_at_spawn() -> void:
	if not player:
		return
	var spawn := get_player_spawn()
	if spawn:
		player.global_position = spawn.global_position


func _find_all_recursive(node: Node) -> Array[Node]:
	var nodes: Array[Node] = []
	for child in node.get_children():
		nodes.append(child)
		nodes.append_array(_find_all_recursive(child))
	return nodes
