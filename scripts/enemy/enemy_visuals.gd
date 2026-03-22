class_name EnemyVisuals
extends Node
## Manages scope glint, laser sight, and debug visualization for enemies.
## Added as a child of EnemyBase at runtime.

## ── Configuration (set by EnemyBase on creation) ────────────────────────────

var enemy: EnemyBase

## Glint settings
var glint_enabled: bool = true
var glint_color: Color = Color(1.0, 0.95, 0.7, 1.0)
var glint_max_energy: float = 3.0
var glint_pulse_speed: float = 3.0
var glint_suspicious_flash: bool = true
var glint_suspicious_threshold: float = 0.7

## Laser settings
var laser_enabled: bool = true
var laser_color: Color = Color(1.0, 0.1, 0.1, 0.6)
var laser_length: float = 3.0
var laser_width: float = 0.02

## Debug settings
var show_debug: bool = false

## ── Internal state ──────────────────────────────────────────────────────────

## Scope glint
var _glint_sprite: Sprite3D
var _glint_light: OmniLight3D
var _glint_material: StandardMaterial3D
var _glint_active: bool = false
var _glint_time: float = 0.0

## Laser sight
var _laser_mesh_instance: MeshInstance3D
var _laser_immediate_mesh: ImmediateMesh
var _laser_material: StandardMaterial3D

## Debug visualization
var _debug_mesh_instance: MeshInstance3D
var _debug_immediate_mesh: ImmediateMesh
var _debug_material: StandardMaterial3D
var _state_indicator: MeshInstance3D
var _state_mat: StandardMaterial3D

const STATE_COLORS := {
	EnemyBase.AlertState.UNAWARE: Color(0.2, 0.8, 0.2, 0.8),
	EnemyBase.AlertState.SUSPICIOUS: Color(1.0, 0.8, 0.0, 0.8),
	EnemyBase.AlertState.ALERT: Color(1.0, 0.1, 0.1, 0.8),
	EnemyBase.AlertState.SEARCHING: Color(1.0, 0.5, 0.0, 0.8),
}


func setup(owner_enemy: EnemyBase) -> void:
	enemy = owner_enemy

	# Copy settings from enemy exports
	glint_enabled = enemy.glint_enabled
	glint_color = enemy.glint_color
	glint_max_energy = enemy.glint_max_energy
	glint_pulse_speed = enemy.glint_pulse_speed
	glint_suspicious_flash = enemy.glint_suspicious_flash
	glint_suspicious_threshold = enemy.glint_suspicious_threshold
	laser_enabled = enemy.laser_enabled
	laser_color = enemy.laser_color
	laser_length = enemy.laser_length
	laser_width = enemy.laser_width
	show_debug = enemy.show_debug

	if show_debug:
		_setup_debug_visuals()
	if glint_enabled:
		_setup_glint()
	if laser_enabled:
		_setup_laser()


## ── Update (called by EnemyBase each frame) ─────────────────────────────────

func update_visuals(delta: float) -> void:
	_update_glint(delta)
	_update_laser()
	if show_debug:
		_update_debug_visuals()


func on_death() -> void:
	_set_glint_visible(false)
	if _laser_mesh_instance:
		_laser_mesh_instance.visible = false
	if _debug_mesh_instance:
		_debug_mesh_instance.visible = false
	if _state_indicator:
		_state_indicator.visible = false


## ── Scope Glint ─────────────────────────────────────────────────────────────

func _setup_glint() -> void:
	var glint_pos := Vector3(0, 1.5, -0.2)

	# Billboard sprite
	_glint_sprite = Sprite3D.new()
	_glint_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_glint_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_glint_sprite.position = glint_pos
	_glint_sprite.pixel_size = 0.005
	_glint_sprite.visible = false

	# Radial gradient texture
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 64
	tex.height = 64
	_glint_sprite.texture = tex

	# Additive unshaded material
	_glint_material = StandardMaterial3D.new()
	_glint_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glint_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_glint_material.albedo_color = glint_color
	_glint_material.render_priority = 1
	_glint_sprite.material_override = _glint_material

	enemy.add_child(_glint_sprite)

	# OmniLight
	_glint_light = OmniLight3D.new()
	_glint_light.position = glint_pos
	_glint_light.omni_range = 2.0
	_glint_light.light_color = Color(glint_color.r, glint_color.g, glint_color.b)
	_glint_light.light_energy = 0.0
	_glint_light.visible = false

	enemy.add_child(_glint_light)


func _update_glint(delta: float) -> void:
	if not glint_enabled or not _glint_sprite:
		return

	var should_show := false

	if not enemy.is_dead:
		match enemy.alert_state:
			EnemyBase.AlertState.ALERT:
				should_show = enemy.can_see_player
			EnemyBase.AlertState.SUSPICIOUS:
				if glint_suspicious_flash and enemy.can_see_player:
					var ratio := enemy.suspicion / enemy.alert_threshold
					if ratio >= glint_suspicious_threshold:
						should_show = fmod(_glint_time * 4.0, 1.0) > 0.5

	_set_glint_visible(should_show)

	if should_show:
		_glint_time += delta
		var pulse := 0.5 + 0.5 * sin(_glint_time * glint_pulse_speed * TAU)
		_glint_material.albedo_color = glint_color * (0.5 + pulse * 0.5)
		_glint_light.light_energy = glint_max_energy * pulse
	else:
		_glint_time = 0.0


func _set_glint_visible(vis: bool) -> void:
	if _glint_active == vis:
		return
	_glint_active = vis
	if _glint_sprite:
		_glint_sprite.visible = vis
	if _glint_light:
		_glint_light.visible = vis


## ── Laser Sight ─────────────────────────────────────────────────────────────

func _setup_laser() -> void:
	_laser_immediate_mesh = ImmediateMesh.new()
	_laser_mesh_instance = MeshInstance3D.new()
	_laser_mesh_instance.mesh = _laser_immediate_mesh
	_laser_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_laser_mesh_instance.visible = false

	_laser_material = StandardMaterial3D.new()
	_laser_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_laser_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_laser_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_laser_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_laser_material.vertex_color_use_as_albedo = true
	_laser_material.no_depth_test = false

	enemy.add_child(_laser_mesh_instance)


func _update_laser() -> void:
	if not laser_enabled or not _laser_immediate_mesh:
		return

	var should_show := not enemy.is_dead
	_laser_mesh_instance.visible = should_show

	if not should_show:
		_laser_immediate_mesh.clear_surfaces()
		return

	var eye := Vector3(0, 1.5, -0.2)
	var forward := -enemy.global_basis.z
	var end := eye + forward * laser_length
	var hw := laser_width * 0.5

	var up := Vector3(0, hw, 0)
	var right := enemy.global_basis.x.normalized() * hw

	var color_start := laser_color
	var color_end := Color(laser_color.r, laser_color.g, laser_color.b, 0.0)

	_laser_immediate_mesh.clear_surfaces()
	_laser_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _laser_material)

	_draw_laser_quad(eye - up, eye + up, end + up, end - up, color_start, color_end)
	_draw_laser_quad(eye - right, eye + right, end + right, end - right, color_start, color_end)

	_laser_immediate_mesh.surface_end()


func _draw_laser_quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		color_start: Color, color_end: Color) -> void:
	_laser_immediate_mesh.surface_set_color(color_start)
	_laser_immediate_mesh.surface_add_vertex(a)
	_laser_immediate_mesh.surface_set_color(color_start)
	_laser_immediate_mesh.surface_add_vertex(b)
	_laser_immediate_mesh.surface_set_color(color_end)
	_laser_immediate_mesh.surface_add_vertex(c)
	_laser_immediate_mesh.surface_set_color(color_start)
	_laser_immediate_mesh.surface_add_vertex(a)
	_laser_immediate_mesh.surface_set_color(color_end)
	_laser_immediate_mesh.surface_add_vertex(c)
	_laser_immediate_mesh.surface_set_color(color_end)
	_laser_immediate_mesh.surface_add_vertex(d)


## ── Debug Visualization ─────────────────────────────────────────────────────

func _setup_debug_visuals() -> void:
	_debug_immediate_mesh = ImmediateMesh.new()
	_debug_mesh_instance = MeshInstance3D.new()
	_debug_mesh_instance.mesh = _debug_immediate_mesh
	_debug_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_debug_material = StandardMaterial3D.new()
	_debug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_debug_material.albedo_color = Color(0.2, 0.8, 0.2, 0.15)
	_debug_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_debug_material.no_depth_test = true

	enemy.add_child(_debug_mesh_instance)

	# State indicator sphere above head
	_state_indicator = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	_state_indicator.mesh = sphere
	_state_indicator.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_state_indicator.position = Vector3(0, 2.3, 0)

	_state_mat = StandardMaterial3D.new()
	_state_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_state_mat.albedo_color = STATE_COLORS[EnemyBase.AlertState.UNAWARE]
	_state_indicator.material_override = _state_mat

	enemy.add_child(_state_indicator)


func _update_debug_visuals() -> void:
	if not _debug_immediate_mesh:
		return

	_state_mat.albedo_color = STATE_COLORS.get(enemy.alert_state, Color.WHITE)

	var cone_color: Color = STATE_COLORS.get(enemy.alert_state, Color.GREEN)
	cone_color.a = 0.1 if enemy.alert_state == EnemyBase.AlertState.UNAWARE else 0.2
	_debug_material.albedo_color = cone_color

	_debug_immediate_mesh.clear_surfaces()
	_debug_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _debug_material)

	var eye_offset := Vector3(0, 1.5, 0)
	var cone_length: float = minf(enemy.max_sight_range, 20.0)
	var half_angle := deg_to_rad(enemy.fov_degrees)
	var segments := 16

	for i in range(segments):
		var angle_a := TAU * float(i) / float(segments)
		var angle_b := TAU * float(i + 1) / float(segments)

		var dir_a := Vector3(
			sin(half_angle) * cos(angle_a),
			sin(half_angle) * sin(angle_a),
			-cos(half_angle)
		) * cone_length
		var dir_b := Vector3(
			sin(half_angle) * cos(angle_b),
			sin(half_angle) * sin(angle_b),
			-cos(half_angle)
		) * cone_length

		_debug_immediate_mesh.surface_add_vertex(eye_offset)
		_debug_immediate_mesh.surface_add_vertex(eye_offset + dir_a)
		_debug_immediate_mesh.surface_add_vertex(eye_offset + dir_b)

	_debug_immediate_mesh.surface_end()
