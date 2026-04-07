class_name EnemyGhost
extends EnemyBase
## Ghost — nearly invisible to the naked eye, fully visible through scope.
## Behaves like a Marksman (auto-reposition, reactive reposition on sound/hit)
## but with transparency that rewards scope discipline.

@export var unscoped_opacity: float = 0.08  ## Faint shimmer when not scoped
@export var scoped_opacity: float = 1.0

## Transparency
var _body_materials: Array[StandardMaterial3D] = []
var _weapon_ref: WeakRef = WeakRef.new()


func _ready() -> void:
	fov_degrees = 25.0
	max_sight_range = 200.0
	suspicion_rate = 0.7
	suspicion_decay = 0.2
	alert_threshold = 0.6
	search_duration = 8.0

	reaction_time = 2.0
	fire_interval = 2.5
	accuracy = 0.75
	inaccuracy_deg = 3.0
	health = 80.0

	initial_behavior = Behavior.SCANNING
	patrol_speed = reposition_speed
	scan_speed = 0.5
	scan_angle = 70.0

	# Reposition behavior
	can_reposition = true
	reposition_speed = 5.0
	auto_reposition_interval = 20.0

	credit_reward = 100
	xp_reward = 45

	body_color = Color(0.15, 0.2, 0.25)  # Dark grey-blue — spectral

	glint_enabled = true
	glint_color = Color(0.6, 0.8, 1.0, 1.0)
	glint_max_energy = 1.5
	laser_enabled = false

	super._ready()

	_setup_transparent_materials()


func _setup_transparent_materials() -> void:
	if not mesh:
		return
	for child in mesh.get_children():
		if child is MeshInstance3D:
			var mat: StandardMaterial3D
			if child.material_override and child.material_override is StandardMaterial3D:
				mat = child.material_override
			else:
				var active: Material = child.get_active_material(0)
				if active and active is StandardMaterial3D:
					mat = active.duplicate()
					child.material_override = mat
			if mat:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				_body_materials.append(mat)


func _physics_process(delta: float) -> void:
	if is_dead or RunManager.game_state != RunManager.GameState.IN_RUN:
		return

	_update_ghost_opacity()
	super._physics_process(delta)


func _update_ghost_opacity() -> void:
	var scoped := _is_player_scoped()
	var target_alpha := scoped_opacity if scoped else unscoped_opacity
	for mat in _body_materials:
		var c := mat.albedo_color
		c.a = target_alpha
		mat.albedo_color = c


func _is_player_scoped() -> bool:
	var weapon = _weapon_ref.get_ref()
	if weapon and is_instance_valid(weapon):
		return weapon.is_scoped

	if not player:
		return false
	var weapon_node = player.get_node_or_null("Head/Camera3D/Weapon")
	if weapon_node and "is_scoped" in weapon_node:
		_weapon_ref = weakref(weapon_node)
		return weapon_node.is_scoped
	return false
