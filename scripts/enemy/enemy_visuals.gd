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

## Scope glint (flat billboard star)
var _glint_sprite: Sprite3D
var _glint_material: ShaderMaterial
var _glint_active: bool = false
var _glint_time: float = 0.0

## Laser sight
var _laser_mesh_instance: MeshInstance3D
var _laser_immediate_mesh: ImmediateMesh
var _laser_material: StandardMaterial3D

## Sight cone visualization
var _cone_mesh_instance: MeshInstance3D
var _cone_material: ShaderMaterial
var _cone_length: float = 20.0
var _cone_half_angle: float = 0.5

## State indicator
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
		_update_cone_color()


func on_death() -> void:
	_set_glint_visible(false)
	if _laser_mesh_instance:
		_laser_mesh_instance.visible = false
	if _cone_mesh_instance:
		_cone_mesh_instance.visible = false
	if _state_indicator:
		_state_indicator.visible = false


## ── Scope Glint (flat billboard 4-point star) ──────────────────────────────

const GLINT_SHADER_CODE := "
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(1.0, 0.95, 0.7, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 1.0;
void vertex() {
	// Billboard
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0,1,0), MAIN_CAM_INV_VIEW_MATRIX[2].xyz)), 0),
		vec4(0, 1, 0, 0),
		vec4(normalize(MAIN_CAM_INV_VIEW_MATRIX[2].xyz), 0),
		MODEL_MATRIX[3]);
}
void fragment() {
	// 4-point star shape from UV
	vec2 uv = UV * 2.0 - 1.0;
	float d_cross = min(abs(uv.x), abs(uv.y));
	float d_diag = min(abs(uv.x - uv.y), abs(uv.x + uv.y)) * 0.707;
	float star = exp(-d_cross * 6.0) * 0.9 + exp(-d_diag * 8.0) * 0.4;
	float circle = 1.0 - length(uv);
	star += smoothstep(0.0, 0.4, circle) * 0.5;
	star = clamp(star, 0.0, 1.0);
	ALBEDO = tint.rgb;
	ALPHA = star * tint.a * intensity;
}
"

func _setup_glint() -> void:
	var glint_pos := Vector3(0, EnemyBase.EYE_HEIGHT, -0.2)

	_glint_sprite = Sprite3D.new()
	_glint_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_glint_sprite.position = glint_pos
	_glint_sprite.pixel_size = 0.012
	_glint_sprite.visible = false
	_glint_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED  # Shader handles billboard

	# White square texture — shader draws the star shape
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex := ImageTexture.create_from_image(img)
	_glint_sprite.texture = tex

	var shader := Shader.new()
	shader.code = GLINT_SHADER_CODE
	_glint_material = ShaderMaterial.new()
	_glint_material.shader = shader
	_glint_material.set_shader_parameter("tint", glint_color)
	_glint_material.set_shader_parameter("intensity", 0.0)
	_glint_sprite.material_override = _glint_material

	enemy.add_child(_glint_sprite)


func _update_glint(delta: float) -> void:
	if not glint_enabled or not _glint_sprite:
		return

	var should_show := false
	var target_intensity := 0.0

	if not enemy.is_dead:
		match enemy.alert_state:
			EnemyBase.AlertState.ALERT:
				should_show = true
				target_intensity = 1.0
			EnemyBase.AlertState.SUSPICIOUS:
				should_show = true
				# Flicker on/off based on suspicion ratio
				var ratio := enemy.suspicion / enemy.alert_threshold
				var flicker := fmod(_glint_time * 4.0, 1.0) > 0.5
				target_intensity = ratio * (1.0 if flicker else 0.3)
			EnemyBase.AlertState.SEARCHING:
				should_show = true
				target_intensity = 0.5

	_set_glint_visible(should_show)

	if should_show:
		_glint_time += delta

		# Gentle pulse
		var pulse := 0.85 + 0.15 * sin(_glint_time * glint_pulse_speed * TAU)
		_glint_material.set_shader_parameter("intensity", target_intensity * pulse)

		# Scale pulse for a bit of life
		var s := 1.0 + 0.15 * sin(_glint_time * 3.0)
		_glint_sprite.scale = Vector3.ONE * s
	else:
		_glint_time = 0.0
		_glint_material.set_shader_parameter("intensity", 0.0)


func _set_glint_visible(vis: bool) -> void:
	if _glint_active == vis:
		return
	_glint_active = vis
	if _glint_sprite:
		_glint_sprite.visible = vis


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

	var eye := Vector3(0, EnemyBase.EYE_HEIGHT, -0.2)
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

## ── Sight Cone (flat ground-plane fan, built once via ArrayMesh) ────────────

const CONE_SHADER_CODE := "
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
uniform vec4 cone_color : source_color = vec4(0.2, 0.8, 0.2, 0.3);
varying float fade;
void vertex() {
	fade = COLOR.r;
}
void fragment() {
	ALBEDO = cone_color.rgb;
	ALPHA = cone_color.a * (1.0 - fade);
}
"

func _setup_debug_visuals() -> void:
	_cone_half_angle = deg_to_rad(enemy.fov_degrees)
	_cone_length = minf(enemy.max_sight_range, 25.0)
	_build_cone_mesh()

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


func _build_cone_mesh() -> void:
	## Builds a flat fan on the XZ plane: tip at origin, spreading forward (-Z).
	## Vertex color R channel stores 0 at tip, 1 at far edge (used for fade).
	var segments := 24
	var verts := PackedVector3Array()
	var colors := PackedColorArray()

	var origin := Vector3(0, 0.05, 0)  # Slightly above ground to avoid z-fight

	for i in segments:
		var frac_a := float(i) / float(segments)
		var frac_b := float(i + 1) / float(segments)
		# Angles spread from -half_angle to +half_angle around -Z
		var a_angle := lerpf(-_cone_half_angle, _cone_half_angle, frac_a)
		var b_angle := lerpf(-_cone_half_angle, _cone_half_angle, frac_b)

		var far_a := Vector3(sin(a_angle) * _cone_length, 0.05, -cos(a_angle) * _cone_length)
		var far_b := Vector3(sin(b_angle) * _cone_length, 0.05, -cos(b_angle) * _cone_length)

		# Triangle: origin → far_a → far_b
		verts.append(origin)
		colors.append(Color(0, 0, 0, 1))  # fade = 0 at tip
		verts.append(far_a)
		colors.append(Color(1, 0, 0, 1))  # fade = 1 at edge
		verts.append(far_b)
		colors.append(Color(1, 0, 0, 1))

	var arr_mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	# Shader material for fade
	var shader := Shader.new()
	shader.code = CONE_SHADER_CODE
	_cone_material = ShaderMaterial.new()
	_cone_material.shader = shader
	_cone_material.set_shader_parameter("cone_color", Color(0.2, 0.8, 0.2, 0.3))

	_cone_mesh_instance = MeshInstance3D.new()
	_cone_mesh_instance.mesh = arr_mesh
	_cone_mesh_instance.material_override = _cone_material
	_cone_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cone_mesh_instance.position = Vector3.ZERO

	enemy.add_child(_cone_mesh_instance)


func _update_cone_color() -> void:
	if not _cone_material:
		return

	_state_mat.albedo_color = STATE_COLORS.get(enemy.alert_state, Color.WHITE)

	var base: Color = STATE_COLORS.get(enemy.alert_state, Color.GREEN)
	var alpha: float = 0.3
	match enemy.alert_state:
		EnemyBase.AlertState.SUSPICIOUS:
			alpha = 0.35
		EnemyBase.AlertState.ALERT:
			alpha = 0.4
		EnemyBase.AlertState.SEARCHING:
			alpha = 0.35
	_cone_material.set_shader_parameter("cone_color", Color(base.r, base.g, base.b, alpha))
