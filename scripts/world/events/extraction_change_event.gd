class_name ExtractionChangeEvent
extends RefCounted
## Level event: the current extraction zone deactivates and a new one
## spawns at a different location. Forces the player to reposition.
##
## Params (optional):
##   "announce_text": String — override HUD message (default: "EXTRACTION POINT RELOCATED")

const EXTRACTION_SCENE := preload("res://scenes/world/extraction_zone.tscn")


func execute(level: BaseLevel, params: Dictionary) -> void:
	var text: String = params.get("announce_text", "EXTRACTION POINT RELOCATED")

	# Find the current active extraction zone
	var old_zone: ExtractionZone = level.extraction_zone
	if not is_instance_valid(old_zone):
		push_warning("ExtractionChangeEvent: no active extraction zone found")
		return

	# Cancel any active extraction
	if RunManager.game_state == RunManager.GameState.EXTRACTING:
		RunManager.cancel_extraction()

	var old_pos := old_zone.global_position

	# Remove old zone
	old_zone.queue_free()

	# Pick a new position away from the old one
	var new_pos := _pick_new_position(level, old_pos)

	# Spawn a new zone
	var new_zone: ExtractionZone = EXTRACTION_SCENE.instantiate()
	new_zone.name = "ExtractionZone_Relocated"
	level.add_child(new_zone)
	new_zone.global_position = new_pos
	level.extraction_zone = new_zone

	# Announce on HUD
	RunManager.announce_event(text)
	AudioManager.play_sfx(&"extraction_start", new_pos)


func _pick_new_position(level: BaseLevel, old_pos: Vector3) -> Vector3:
	## Try to place the new zone far from the old one.
	## Uses extraction spawn points if available, otherwise picks a random
	## ground position away from the old zone.

	# Check for other extraction-type spawn points (placed in scene but zone was removed)
	var extraction_spawns := level.get_spawn_points(SpawnPoint.Type.EXTRACTION)
	if not extraction_spawns.is_empty():
		# Pick the farthest extraction spawn from the old position
		var best: SpawnPoint = null
		var best_dist := 0.0
		for spawn in extraction_spawns:
			var d := spawn.global_position.distance_squared_to(old_pos)
			if d > best_dist:
				best_dist = d
				best = spawn
		if best:
			return best.global_position

	# Fallback: pick a random enemy spawn point far from old zone
	var enemy_spawns := level.get_spawn_points(SpawnPoint.Type.ENEMY)
	if not enemy_spawns.is_empty():
		var best_pos := enemy_spawns[0].global_position
		var best_dist := 0.0
		for spawn in enemy_spawns:
			var d := spawn.global_position.distance_squared_to(old_pos)
			if d > best_dist:
				best_dist = d
				best_pos = spawn.global_position
		return best_pos

	# Last resort: offset from old position
	return old_pos + Vector3(30, 0, 30)
