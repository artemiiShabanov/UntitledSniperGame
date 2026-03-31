extends Node
## VFXFactory — autoloaded singleton for spawning one-shot visual effects.
## All VFX use palette colors and clean themselves up automatically.
## Pre-warms particle shaders on startup to avoid first-use stutter.

## ── Cached materials (created once, reused) ─────────────────────────────────

var _sparkle_mesh: QuadMesh
var _muzzle_mat: StandardMaterial3D
var _impact_mat: StandardMaterial3D
var _headshot_mat: StandardMaterial3D
var _extraction_mat: StandardMaterial3D

## VFX sprite textures (placeholder → replace with final art)
var _muzzle_flash_tex: Texture2D
var _impact_dust_tex: Texture2D
var _impact_blood_tex: Texture2D
var _smoke_puff_tex: Texture2D
var _shell_casing_tex: Texture2D


func _ready() -> void:
	_load_vfx_textures()
	_create_shared_resources()
	_prewarm_shaders()
	PaletteManager.palette_changed.connect(_on_palette_changed)


func _load_vfx_textures() -> void:
	_muzzle_flash_tex = UIUtils.try_load_tex("res://assets/sprites/vfx/muzzle_flash.png")
	_impact_dust_tex = UIUtils.try_load_tex("res://assets/sprites/vfx/impact_dust.png")
	_impact_blood_tex = UIUtils.try_load_tex("res://assets/sprites/vfx/impact_blood.png")
	_smoke_puff_tex = UIUtils.try_load_tex("res://assets/sprites/vfx/smoke_puff.png")
	_shell_casing_tex = UIUtils.try_load_tex("res://assets/sprites/vfx/shell_casing.png")




func _create_shared_resources() -> void:
	# Shared sparkle quad — tiny billboard quad used by all particle effects
	_sparkle_mesh = QuadMesh.new()
	_sparkle_mesh.size = Vector2(0.04, 0.04)

	# Muzzle flash material
	_muzzle_mat = _make_unshaded_billboard_mat(Color(1.0, 0.9, 0.6), 4.0)
	if _muzzle_flash_tex:
		_muzzle_mat.albedo_texture = _muzzle_flash_tex

	# Impact material
	_impact_mat = _make_unshaded_billboard_mat(PaletteManager.get_color(PaletteManager.SLOT_DANGER), 2.0)
	if _impact_dust_tex:
		_impact_mat.albedo_texture = _impact_dust_tex

	# Headshot material
	_headshot_mat = _make_unshaded_billboard_mat(Color.WHITE, 5.0)
	if _impact_blood_tex:
		_headshot_mat.albedo_texture = _impact_blood_tex

	# Extraction material
	var ext_color: Color = PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY)
	ext_color.a = 0.7
	_extraction_mat = _make_unshaded_billboard_mat(ext_color, 1.5)


func _make_unshaded_billboard_mat(color: Color, emission_energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = Color(color, 1.0)
	mat.emission_energy_multiplier = emission_energy
	mat.vertex_color_use_as_albedo = true
	mat.no_depth_test = false
	mat.render_priority = 1
	return mat


func _prewarm_shaders() -> void:
	## Spawn invisible one-shot particles offscreen to force shader compilation.
	## This prevents the stutter on first real use.
	var warmup := GPUParticles3D.new()
	warmup.emitting = true
	warmup.one_shot = true
	warmup.amount = 1
	warmup.lifetime = 0.05
	warmup.explosiveness = 1.0
	warmup.visibility_aabb = AABB(Vector3.ZERO, Vector3.ONE)

	var mat := ParticleProcessMaterial.new()
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.001
	mat.scale_max = 0.001
	warmup.process_material = mat
	warmup.draw_pass_1 = _sparkle_mesh
	warmup.material_override = _muzzle_mat

	add_child(warmup)
	warmup.position = Vector3(0, -1000, 0)  # Far below world

	get_tree().create_timer(0.2).timeout.connect(func():
		if is_instance_valid(warmup):
			warmup.queue_free()
	)


func _on_palette_changed(_p: PaletteResource) -> void:
	# Update cached materials with new palette colors
	var danger: Color = PaletteManager.get_color(PaletteManager.SLOT_DANGER)
	_impact_mat.albedo_color = danger
	_impact_mat.emission = Color(danger, 1.0)

	var friendly: Color = PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY)
	friendly.a = 0.7
	_extraction_mat.albedo_color = friendly
	_extraction_mat.emission = Color(friendly, 1.0)


## ── Muzzle Flash ────────────────────────────────────────────────────────────

func spawn_muzzle_flash(pos: Vector3, forward: Vector3, is_enemy: bool = false) -> void:
	var particles := GPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 12
	particles.lifetime = 0.08
	particles.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(forward.x, forward.y, forward.z)
	mat.spread = 35.0
	mat.initial_velocity_min = 4.0
	mat.initial_velocity_max = 10.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.5
	mat.scale_max = 1.5
	mat.damping_min = 8.0
	mat.damping_max = 12.0

	var color: Color = PaletteManager.get_color(PaletteManager.SLOT_DANGER) if is_enemy else Color(1.0, 0.9, 0.6)
	mat.color = color
	particles.process_material = mat

	particles.draw_pass_1 = _sparkle_mesh
	var flash_mat := _muzzle_mat.duplicate() as StandardMaterial3D
	flash_mat.albedo_color = color
	flash_mat.emission = Color(color, 1.0)
	particles.material_override = flash_mat

	_add_to_world(particles, pos, 0.5)


## ── Hit Impact ──────────────────────────────────────────────────────────────

func spawn_hit_impact(pos: Vector3, normal: Vector3, is_headshot: bool = false) -> void:
	var particles := GPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 20 if is_headshot else 8
	particles.lifetime = 0.5 if is_headshot else 0.3
	particles.visibility_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))

	var mat := ParticleProcessMaterial.new()
	mat.direction = normal
	mat.spread = 50.0 if is_headshot else 35.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 8.0 if is_headshot else 5.0
	mat.gravity = Vector3(0, -8, 0)
	mat.damping_min = 3.0
	mat.damping_max = 6.0
	mat.scale_min = 0.4
	mat.scale_max = 1.2 if is_headshot else 0.8

	var color: Color
	if is_headshot:
		color = Color.WHITE
	else:
		color = PaletteManager.get_color(PaletteManager.SLOT_DANGER)
	mat.color = color
	particles.process_material = mat

	particles.draw_pass_1 = _sparkle_mesh
	particles.material_override = _headshot_mat if is_headshot else _impact_mat

	_add_to_world(particles, pos, 1.0)

	# Headshot: additional expanding flash
	if is_headshot:
		_spawn_headshot_flash(pos)


func _spawn_headshot_flash(pos: Vector3) -> void:
	var flash := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.2, 0.2)
	flash.mesh = quad

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 6.0
	flash.material_override = mat

	get_tree().root.add_child(flash)
	flash.global_position = pos

	var tween := flash.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.15)
	tween.parallel().tween_property(flash, "scale", Vector3(3.0, 3.0, 3.0), 0.15)
	tween.tween_callback(flash.queue_free)


## ── Death Effect ────────────────────────────────────────────────────────────

func spawn_death_effect(enemy: Node3D, is_headshot: bool) -> void:
	## Tilts the enemy and fades out instead of hard color switch.
	var mesh_node: Node3D = enemy.get_node_or_null("Mesh")
	if not mesh_node:
		return

	# Gather all materials for fading
	var materials: Array[StandardMaterial3D] = []
	for child in mesh_node.get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = child.material_override
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			materials.append(mat)

	# Create death material if no existing materials to fade
	if materials.is_empty():
		var death_mat := StandardMaterial3D.new()
		death_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		death_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		death_mat.albedo_color = PaletteManager.get_color(PaletteManager.SLOT_FG_DARK)
		for child in mesh_node.get_children():
			if child is MeshInstance3D:
				child.material_override = death_mat
				materials.append(death_mat)
			elif child is CSGShape3D:
				child.material = death_mat
				materials.append(death_mat)

	# Tilt animation
	var tilt_angle := -85.0 if not is_headshot else -90.0
	var tilt_duration := 0.6 if not is_headshot else 0.3

	var tween := enemy.create_tween()
	tween.set_parallel(true)

	# Tilt forward
	tween.tween_property(mesh_node, "rotation_degrees:x", tilt_angle, tilt_duration) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Slight downward movement
	tween.tween_property(enemy, "global_position:y", enemy.global_position.y - 0.5, tilt_duration) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Fade out after tilt (all materials simultaneously)
	tween.chain()  # Wait for parallel tilt to finish, then continue sequentially
	if not materials.is_empty():
		tween.set_parallel(true)
		for mat in materials:
			tween.tween_property(mat, "albedo_color:a", 0.0, 1.5)
		tween.set_parallel(false)

	tween.tween_callback(func():
		if is_instance_valid(enemy):
			enemy.queue_free()
	)


## ── Extraction Zone Particles ───────────────────────────────────────────────

func create_extraction_particles(zone: Node3D, zone_size: Vector3) -> GPUParticles3D:
	## Creates a persistent ring of rising particles around an extraction zone.
	var particles := GPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = false
	particles.amount = 24
	particles.lifetime = 2.5
	particles.visibility_aabb = AABB(Vector3(-5, -2, -5), Vector3(10, 8, 10))

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(zone_size.x / 2.0, 0.1, zone_size.z / 2.0)
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 8.0
	mat.initial_velocity_min = 0.3
	mat.initial_velocity_max = 0.8
	mat.gravity = Vector3.ZERO
	mat.damping_min = 0.5
	mat.damping_max = 1.0
	mat.scale_min = 0.6
	mat.scale_max = 1.2

	var color: Color = PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY)
	color.a = 0.7
	mat.color = color
	particles.process_material = mat

	particles.draw_pass_1 = _sparkle_mesh
	particles.material_override = _extraction_mat

	zone.add_child(particles)

	# Palette swap updates are handled by _on_palette_changed via cached material
	# Also update process material color
	PaletteManager.palette_changed.connect(func(_p: PaletteResource) -> void:
		var new_color: Color = PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY)
		new_color.a = 0.7
		mat.color = new_color
	)

	return particles


## ── Bullet Tracer Trail ─────────────────────────────────────────────────────

func add_tracer_trail(bullet: Node3D, color: Color = Color.WHITE, length: float = 2.0) -> void:
	## Adds a stretched trail mesh behind a bullet that follows it each frame.
	var trail := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.008, 0.008, length)
	trail.mesh = box

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(color, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(color, 1.0)
	mat.emission_energy_multiplier = 2.0
	trail.material_override = mat

	bullet.add_child(trail)
	trail.position = Vector3(0, 0, length / 2.0)


## ── Helpers ─────────────────────────────────────────────────────────────────

func _add_to_world(node: Node, pos: Vector3, cleanup_time: float) -> void:
	get_tree().root.add_child(node)
	if node is Node3D:
		node.global_position = pos

	get_tree().create_timer(cleanup_time).timeout.connect(func():
		if is_instance_valid(node):
			node.queue_free()
	)
