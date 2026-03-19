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


func _ready() -> void:
	_find_player()
	_find_extraction_zone()
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


func _find_extraction_zone() -> void:
	for child in _find_all_recursive(self):
		if child is ExtractionZone:
			extraction_zone = child
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
