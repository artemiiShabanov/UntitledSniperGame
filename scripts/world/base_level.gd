class_name BaseLevel
extends Node3D
## Attach to the root of every level scene.
## Finds spawn points, positions the player, and provides helpers
## for systems that need level info (warrior spawner, extraction, etc.).

@export var level_data: LevelData

## Future hooks for Layer 10 — references for TimeOfDay / Weather managers
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var world_env: WorldEnvironment = $WorldEnvironment

var player: CharacterBody3D
var rng: RandomNumberGenerator

## Current run environment (set during _setup_run_variation)
var current_time_of_day: String = "day"
var current_weather: String = "clear"


func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.randomize()

	_find_player()
	_setup_run_variation()
	_place_player_at_spawn()

	# Apply castle HP from level data.
	if level_data and level_data.castle_hp > 0:
		RunManager.castle_max_hp = level_data.castle_hp
		RunManager.castle_hp = level_data.castle_hp
		# Apply Reinforced Gates army upgrade.
		if SaveManager.is_army_upgrade_unlocked("reinforced_gates"):
			var bonus := int(RunManager.castle_max_hp * 0.4)
			RunManager.castle_max_hp += bonus
			RunManager.castle_hp += bonus

	# If loaded directly (not via deploy), auto-start a run for dev convenience.
	if RunManager.game_state != RunManager.GameState.DEPLOYING and \
			RunManager.game_state != RunManager.GameState.IN_RUN:
		RunManager.lives = RunManager.default_lives
		RunManager.max_lives = RunManager.default_lives
		RunManager.is_dead = false
		RunManager.begin_run()


## ── Run variation ───────────────────────────────────────────────────────────

func _setup_run_variation() -> void:
	_pick_environment()
	_fill_level_slots()
	_setup_warrior_spawner()
	_setup_extraction_window_manager()
	_setup_opportunity_runner()

	# Palette: color all unscripted world geometry (ground, walls, etc.)
	PaletteManager.color_unscripted_meshes(self)

	# Start level audio — per-level streams with fallback to generic bank.
	if level_data and level_data.level_ambient:
		AudioManager.play_ambient_stream(level_data.level_ambient)
	else:
		AudioManager.play_ambient(&"level_ambient")

	if level_data and level_data.level_theme:
		AudioManager.play_music_stream(level_data.level_theme)
	else:
		AudioManager.play_music(&"level_theme")

	RunManager.threat_phase_changed.connect(_on_threat_phase_changed)

	# Weather particles (rain/snow) — follows player camera.
	_setup_weather_particles()


func _pick_environment() -> void:
	if not level_data:
		return

	if level_data.available_times_of_day.size() > 0:
		current_time_of_day = level_data.available_times_of_day[
			rng.randi() % level_data.available_times_of_day.size()
		]

	if level_data.available_weather.size() > 0:
		current_weather = level_data.available_weather[
			rng.randi() % level_data.available_weather.size()
		]

	EnvironmentConfig.apply_time_of_day(sun, world_env, current_time_of_day)
	EnvironmentConfig.apply_weather(world_env, current_weather)


func _fill_level_slots() -> void:
	for node in UIUtils.find_all_recursive(self):
		if node is LevelSlot and node.slot_data and not node.slot_data.variants.is_empty():
			var variant: PackedScene = node.slot_data.variants[rng.randi() % node.slot_data.variants.size()]
			var chunk := variant.instantiate()
			node.add_child(chunk)


func _setup_warrior_spawner() -> void:
	var spawner := WarriorSpawner.new()
	spawner.name = "WarriorSpawner"
	add_child(spawner)


func _setup_extraction_window_manager() -> void:
	var manager := ExtractionWindowManager.new()
	manager.name = "ExtractionWindowManager"
	add_child(manager)


func _setup_opportunity_runner() -> void:
	var runner := OpportunityRunner.new()
	runner.name = "OpportunityRunner"
	add_child(runner)


func _on_threat_phase_changed(phase: int) -> void:
	if phase == 4:
		AudioManager.play_music(&"combat_tension")


func _setup_weather_particles() -> void:
	if current_weather == "clear" or current_weather == "overcast":
		return
	if not player:
		return
	var cam: Camera3D = player.get_node_or_null("Head/Camera3D")
	if not cam:
		return
	var weather_fx := WeatherParticles.new()
	weather_fx.name = "WeatherParticles"
	weather_fx.setup(current_weather, cam)
	add_child(weather_fx)


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


## ── Internal ─────────────────────────────────────────────────────────────────

func _find_player() -> void:
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
