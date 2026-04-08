class_name DestructibleTreasure
extends DestructibleTarget
## Rare treasure — 1-2 per run, placed randomly. Small, high reward.
## Glows with a pulsing emissive effect to catch the player's eye through scope.
## Skins: gold coins, jewel box, gold bar.

enum SkinType { GOLD_COINS, JEWEL_BOX, GOLD_BAR }

@export var skin: SkinType = SkinType.GOLD_COINS
@export var glow_color: Color = Color(1.0, 0.85, 0.2)
@export var glow_speed: float = 2.0
@export var glow_min: float = 1.0
@export var glow_max: float = 3.0

var _glow_mat: StandardMaterial3D


func _ready() -> void:
	credit_reward = 150
	xp_reward = 50
	_apply_skin()
	super._ready()
	_setup_glow()


func _process(delta: float) -> void:
	if is_destroyed or not _glow_mat:
		return
	var t := (sin(Time.get_ticks_msec() * 0.001 * glow_speed) + 1.0) * 0.5
	_glow_mat.emission_energy_multiplier = lerpf(glow_min, glow_max, t)


func _apply_skin() -> void:
	if not mesh:
		return
	var body: MeshInstance3D = mesh.get_node_or_null("Body")
	if not body:
		return

	match skin:
		SkinType.GOLD_COINS:
			# Short cylinder stack
			var m := CylinderMesh.new()
			m.top_radius = 0.12
			m.bottom_radius = 0.15
			m.height = 0.1
			body.mesh = m
		SkinType.JEWEL_BOX:
			var m := BoxMesh.new()
			m.size = Vector3(0.2, 0.12, 0.15)
			body.mesh = m
		SkinType.GOLD_BAR:
			var m := BoxMesh.new()
			m.size = Vector3(0.22, 0.08, 0.1)
			body.mesh = m


func _setup_glow() -> void:
	if not mesh:
		return
	_glow_mat = StandardMaterial3D.new()
	_glow_mat.albedo_color = glow_color
	_glow_mat.emission_enabled = true
	_glow_mat.emission = glow_color
	_glow_mat.emission_energy_multiplier = glow_min

	var body: MeshInstance3D = mesh.get_node_or_null("Body")
	if body:
		body.material_override = _glow_mat


func _on_destroy() -> void:
	AudioManager.play_sfx(&"treasure_collected", global_position)
	if mesh:
		mesh.visible = false
