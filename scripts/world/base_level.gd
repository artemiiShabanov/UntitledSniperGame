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

## Current run environment (set during _setup_run_variation)
var current_time_of_day: String = "day"
var current_weather: String = "clear"
var visibility_multiplier: float = 1.0  ## Affects enemy sight range


func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.randomize()

	_find_player()
	_setup_run_variation()
	_place_player_at_spawn()

	# Apply level data overrides
	if level_data:
		if level_data.run_time_override > 0.0:
			RunManager.run_timer = level_data.run_time_override
			RunManager.run_start_time = level_data.run_time_override

	# If loaded directly (not via deploy), auto-start a run for dev convenience
	if RunManager.game_state != RunManager.GameState.DEPLOYING and \
			RunManager.game_state != RunManager.GameState.IN_RUN:
		RunManager.run_timer = RunManager.run_start_time
		RunManager.lives = RunManager.default_lives
		RunManager.max_lives = RunManager.default_lives
		RunManager.is_dead = false
		RunManager.begin_run()


## ── Run variation ───────────────────────────────────────────────────────────

func _setup_run_variation() -> void:
	_pick_environment()
	_fill_level_slots()
	_spawn_enemies()
	_spawn_npcs()
	_spawn_destructibles()
	_setup_balloon_spawner()
	_pick_extraction_zone()
	_setup_opportunity_runner()
	_setup_enemy_spawner()

	# Palette: color all unscripted world geometry (ground, walls, etc.)
	# Entities handle their own coloring via PaletteManager.bind_meshes()
	PaletteManager.color_unscripted_meshes(self)

	# Start level audio — per-level streams with fallback to generic bank
	if level_data and level_data.level_ambient:
		AudioManager.play_ambient_stream(level_data.level_ambient)
	else:
		AudioManager.play_ambient(&"level_ambient")

	if level_data and level_data.level_theme:
		AudioManager.play_music_stream(level_data.level_theme)
	else:
		AudioManager.play_music(&"level_theme")

	RunManager.threat_phase_changed.connect(_on_threat_phase_changed)

	# Weather particles (rain/snow) — follows player camera
	_setup_weather_particles()


func _pick_environment() -> void:
	if not level_data:
		return

	# Pick random time of day from available options
	if level_data.available_times_of_day.size() > 0:
		current_time_of_day = level_data.available_times_of_day[
			rng.randi() % level_data.available_times_of_day.size()
		]

	# Pick random weather from available options
	if level_data.available_weather.size() > 0:
		current_weather = level_data.available_weather[
			rng.randi() % level_data.available_weather.size()
		]

	# Apply presets
	EnvironmentConfig.apply_time_of_day(sun, world_env, current_time_of_day)
	EnvironmentConfig.apply_weather(world_env, current_weather)

	# Cache visibility multiplier (used by enemies to adjust sight range)
	visibility_multiplier = EnvironmentConfig.get_visibility_multiplier(current_weather)

	# Night also reduces visibility
	if current_time_of_day == "night":
		visibility_multiplier *= 0.6


func _fill_level_slots() -> void:
	for node in UIUtils.find_all_recursive(self):
		if node is LevelSlot and node.slot_data and not node.slot_data.variants.is_empty():
			var variant: PackedScene = node.slot_data.variants[rng.randi() % node.slot_data.variants.size()]
			var chunk := variant.instantiate()
			node.add_child(chunk)


func _spawn_enemies() -> void:
	if not level_data or not level_data.enemy_pool:
		if level_data:
			push_warning("BaseLevel: level_data has no enemy_pool assigned")
		return

	var spawns := get_enemy_spawns()
	if spawns.is_empty():
		return

	# Shuffle and pick a subset
	var shuffled := spawns.duplicate()
	ArrayUtils.shuffle(shuffled, rng)

	var count := rng.randi_range(level_data.enemy_count_range.x, level_data.enemy_count_range.y)
	count = mini(count, shuffled.size())

	var used_counts: Dictionary = {}
	for i in count:
		var spawn: SpawnPoint = shuffled[i]
		var scene := level_data.enemy_pool.pick_random(rng, used_counts)
		if scene == null:
			continue

		var enemy := scene.instantiate()
		add_child(enemy)
		enemy.global_position = spawn.global_position
		enemy.rotation.y = deg_to_rad(spawn.facing_direction)

		if spawn.behavior_tag != "default" and "initial_behavior" in enemy:
			enemy.initial_behavior = EnemyBase.behavior_from_string(spawn.behavior_tag)

		# Track used counts for max_per_run
		var path := scene.resource_path
		used_counts[path] = used_counts.get(path, 0) + 1

	# Store unused spawns for reinforcement events
	for i in range(count, shuffled.size()):
		_unused_enemy_spawns.append(shuffled[i])


func _spawn_npcs() -> void:
	if not level_data or not level_data.npc_pool:
		return

	var activity_points := get_activity_points()
	if activity_points.is_empty():
		push_warning("BaseLevel: level has npc_pool but no ActivityPoints placed")
		return

	var count := rng.randi_range(level_data.npc_count_range.x, level_data.npc_count_range.y)
	var used_counts: Dictionary = {}

	for i in count:
		var scene := level_data.npc_pool.pick_random(rng, used_counts)
		if scene == null:
			continue

		var npc: NpcBase = scene.instantiate()

		# Set available points BEFORE add_child — _ready() needs them
		npc.available_points = activity_points

		add_child(npc)

		# Place at a random activity point matching its first activity
		var start_point := _pick_npc_start_point(npc, activity_points)
		if start_point:
			npc.global_position = start_point.global_position
			npc.rotation.y = deg_to_rad(start_point.facing_direction)
			npc.target_point = start_point
		else:
			# Fallback: place at any activity point
			var fallback := activity_points[rng.randi() % activity_points.size()]
			npc.global_position = fallback.global_position
			npc.rotation.y = deg_to_rad(fallback.facing_direction)

		var path := scene.resource_path
		used_counts[path] = used_counts.get(path, 0) + 1


func _pick_npc_start_point(npc: NpcBase, points: Array[ActivityPoint]) -> ActivityPoint:
	## Finds a random activity point matching the NPC's first activity.
	if npc.activity_list.is_empty():
		return null

	var first_activity: String = npc.activity_list[0]
	var matching: Array[ActivityPoint] = []
	for point in points:
		if point.get_activity_name() == first_activity:
			matching.append(point)

	if matching.is_empty():
		return null
	return matching[rng.randi() % matching.size()]


func get_activity_points() -> Array[ActivityPoint]:
	var result: Array[ActivityPoint] = []
	for child in UIUtils.find_all_recursive(self):
		if child is ActivityPoint:
			result.append(child)
	return result


func _spawn_destructibles() -> void:
	if not level_data or not level_data.destructible_pool:
		return

	var spawner := DestructibleSpawner.new()
	spawner.name = "DestructibleSpawner"
	add_child(spawner)
	spawner.setup(self, level_data.destructible_pool)

	# Static destructibles (crate, bottle) at DESTRUCTIBLE spawn points
	var static_count := rng.randi_range(
		level_data.static_destructible_count_range.x,
		level_data.static_destructible_count_range.y
	)
	spawner.spawn_static(static_count)

	# Dynamic destructibles (rat, bird) at random positions
	spawner.spawn_dynamic(level_data.dynamic_destructible_count)


func _setup_balloon_spawner() -> void:
	if not level_data:
		return

	var spawner := BalloonSpawner.new()
	spawner.name = "BalloonSpawner"
	spawner.spawn_interval = level_data.balloon_spawn_interval
	spawner.max_concurrent = level_data.balloon_max_concurrent
	spawner.spawn_chance = level_data.balloon_spawn_chance
	add_child(spawner)
	spawner.setup(self)


func _pick_extraction_zone() -> void:
	var zones: Array[ExtractionZone] = []
	for node in UIUtils.find_all_recursive(self):
		if node is ExtractionZone:
			zones.append(node)

	if zones.is_empty():
		return

	# Shuffle zones
	ArrayUtils.shuffle(zones, rng)

	var keep_count := 1
	if level_data:
		keep_count = mini(level_data.extraction_count, zones.size())

	extraction_zone = zones[0]
	for i in range(keep_count, zones.size()):
		zones[i].queue_free()


func _setup_weather_particles() -> void:
	if current_weather == "clear" or current_weather == "overcast":
		return  # No particles needed
	if not player:
		push_warning("WeatherParticles: no player found")
		return
	var cam: Camera3D = player.get_node_or_null("Head/Camera3D")
	if not cam:
		push_warning("WeatherParticles: no camera at Head/Camera3D")
		return
	var weather_fx := WeatherParticles.new()
	weather_fx.name = "WeatherParticles"
	weather_fx.setup(current_weather, cam)
	add_child(weather_fx)


func _on_threat_phase_changed(phase: int) -> void:
	if phase == 4:
		# First enemies appearing — tension music
		AudioManager.play_music(&"combat_tension")


func _setup_opportunity_runner() -> void:
	var runner := OpportunityRunner.new()
	runner.name = "OpportunityRunner"
	add_child(runner)


func _setup_enemy_spawner() -> void:
	if not level_data or not level_data.enemy_pool:
		return
	if _unused_enemy_spawns.is_empty():
		return

	var spawner := EnemySpawner.new()
	spawner.name = "EnemySpawner"

	# Apply spawner config from level data
	spawner.spawn_start_phase = level_data.spawn_start_phase
	spawner.spawn_interval_initial = level_data.spawn_interval_initial
	spawner.spawn_interval_final = level_data.spawn_interval_final
	spawner.max_enemies_initial = level_data.max_enemies_initial
	spawner.max_enemies_final = level_data.max_enemies_final

	add_child(spawner)
	spawner.setup(self, level_data.enemy_pool, _unused_enemy_spawns)


## ── Spawn helpers ────────────────────────────────────────────────────────────

func get_spawn_points(type: SpawnPoint.Type) -> Array[SpawnPoint]:
	var result: Array[SpawnPoint] = []
	for child in UIUtils.find_all_recursive(self):
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
