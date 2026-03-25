extends Node
## VFXFactory — autoloaded singleton for spawning one-shot visual effects.
## All VFX use palette colors and clean themselves up automatically.

## ── Muzzle Flash ────────────────────────────────────────────────────────────

func spawn_muzzle_flash(pos: Vector3, forward: Vector3, is_enemy: bool = false) -> void:
	var particles := GPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 8
	particles.lifetime = 0.1
	particles.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(forward.x, forward.y, forward.z)
	mat.spread = 25.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 6.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.03
	mat.scale_max = 0.06
	mat.color = PaletteManager.get_color(&"danger") if is_enemy else Color(1.0, 0.9, 0.6)
	particles.process_material = mat

	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	var draw_pass := MeshInstance3D.new()
	draw_pass.mesh = mesh
	var draw_mat := StandardMaterial3D.new()
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.emission_enabled = true
	draw_mat.emission = mat.color
	draw_mat.emission_energy_multiplier = 4.0
	draw_mat.albedo_color = mat.color
	draw_pass.material_override = draw_mat
	particles.draw_pass_1 = mesh

	_add_to_world(particles, pos, 0.5)


## ── Hit Impact ──────────────────────────────────────────────────────────────

func spawn_hit_impact(pos: Vector3, normal: Vector3, is_headshot: bool = false) -> void:
	var particles := GPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 16 if is_headshot else 8
	particles.lifetime = 0.4 if is_headshot else 0.25
	particles.visibility_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))

	var mat := ParticleProcessMaterial.new()
	mat.direction = normal
	mat.spread = 45.0 if is_headshot else 30.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 5.0 if is_headshot else 3.0
	mat.gravity = Vector3(0, -6, 0)
	mat.scale_min = 0.02
	mat.scale_max = 0.06 if is_headshot else 0.04

	var color: Color = PaletteManager.get_color(&"danger")
	if is_headshot:
		color = Color(1.0, 1.0, 1.0)  # Bright white for headshots
	mat.color = color
	particles.process_material = mat

	particles.draw_pass_1 = _make_particle_mesh(color, 3.0 if is_headshot else 2.0)

	_add_to_world(particles, pos, 1.0)

	# Headshot: additional flash sphere
	if is_headshot:
		_spawn_headshot_flash(pos)


func _spawn_headshot_flash(pos: Vector3) -> void:
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	flash.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 5.0
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	flash.material_override = mat

	get_tree().root.add_child(flash)
	flash.global_position = pos

	# Quick fade-out tween
	var tween := flash.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.2)
	tween.parallel().tween_property(flash, "scale", Vector3(2.5, 2.5, 2.5), 0.2)
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
		death_mat.albedo_color = PaletteManager.get_color(&"fg_dark")
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

	# Fade out after tilt
	tween.set_parallel(false)
	for mat in materials:
		tween.tween_property(mat, "albedo_color:a", 0.0, 1.5)

	tween.tween_callback(func():
		if is_instance_valid(enemy):
			enemy.queue_free()
	)


## ── Extraction Zone Particles ───────────────────────────────────────────────

func create_extraction_particles(zone: Node3D, zone_size: Vector3) -> GPUParticles3D:
	## Creates a persistent ring of rising particles around an extraction zone.
	## Returns the node so the caller can manage its lifetime.
	var particles := GPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = false
	particles.amount = 24
	particles.lifetime = 2.0
	particles.visibility_aabb = AABB(Vector3(-5, -2, -5), Vector3(10, 8, 10))

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(zone_size.x / 2.0, 0.1, zone_size.z / 2.0)
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 10.0
	mat.initial_velocity_min = 0.5
	mat.initial_velocity_max = 1.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.03
	mat.scale_max = 0.06

	var color: Color = PaletteManager.get_color(&"accent_friendly")
	color.a = 0.7
	mat.color = color
	particles.process_material = mat

	particles.draw_pass_1 = _make_particle_mesh(color, 1.5)

	zone.add_child(particles)

	# Update color on palette swap
	PaletteManager.palette_changed.connect(func(_p: PaletteResource) -> void:
		var new_color: Color = PaletteManager.get_color(&"accent_friendly")
		new_color.a = 0.7
		mat.color = new_color
	)

	return particles


## ── Bullet Tracer Trail ─────────────────────────────────────────────────────

func add_tracer_trail(bullet: Node3D, color: Color = Color.WHITE, length: float = 2.0) -> void:
	## Adds a stretched trail mesh behind a bullet that follows it each frame.
	var trail := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.01, 0.01, length)
	trail.mesh = box

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(color, 0.6)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	trail.material_override = mat

	bullet.add_child(trail)
	# Offset trail behind bullet
	trail.position = Vector3(0, 0, length / 2.0)


## ── Helpers ─────────────────────────────────────────────────────────────────

func _make_particle_mesh(color: Color, emission_energy: float = 2.0) -> SphereMesh:
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	# Note: particle material is set via process_material.color
	# The mesh just provides the shape
	return sphere


func _add_to_world(node: Node, pos: Vector3, cleanup_time: float) -> void:
	get_tree().root.add_child(node)
	if node is Node3D:
		node.global_position = pos

	# Auto-cleanup
	get_tree().create_timer(cleanup_time).timeout.connect(func():
		if is_instance_valid(node):
			node.queue_free()
	)
