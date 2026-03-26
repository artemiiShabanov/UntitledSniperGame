class_name ExtractionZone
extends Area3D
## Stand in zone + hold E to extract. Leaving or releasing E cancels.
## Requires a CollisionShape3D child defining the trigger volume.

@export var zone_size: Vector3 = Vector3(4, 3, 4)

@onready var mesh: MeshInstance3D = $MeshInstance3D

signal player_entered_zone
signal player_exited_zone

var player_inside: bool = false


func _ready() -> void:
	add_to_group("extraction_zone")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Palette: translucent friendly color (needs custom handling for alpha)
	_apply_zone_color()
	PaletteManager.palette_changed.connect(func(_p: PaletteResource) -> void: _apply_zone_color())

	# Rising particle ring
	VFXFactory.create_extraction_particles(self, zone_size)


func _apply_zone_color() -> void:
	if mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(PaletteManager.get_color(&"accent_friendly"), 0.3)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material_override = mat


func _process(_delta: float) -> void:
	if not player_inside or RunManager.game_state == RunManager.GameState.RESULT:
		return

	if Input.is_action_pressed("interact"):
		if RunManager.game_state == RunManager.GameState.IN_RUN:
			RunManager.begin_extraction()
			AudioManager.play_sfx(&"extraction_start", global_position)
		# While extracting, RunManager ticks the timer
	else:
		# Released E — cancel
		if RunManager.game_state == RunManager.GameState.EXTRACTING:
			RunManager.cancel_extraction()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		player_entered_zone.emit()


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		player_exited_zone.emit()
		if RunManager.game_state == RunManager.GameState.EXTRACTING:
			RunManager.cancel_extraction()
