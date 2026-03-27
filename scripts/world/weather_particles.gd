class_name WeatherParticles
extends Node3D
## Spawns GPU particle systems for weather effects (rain, snow).
## Follows the player camera. Created by BaseLevel based on current_weather.


var _rain_particles: GPUParticles3D
var _snow_particles: GPUParticles3D
var _camera: Camera3D


## ── Configuration ────────────────────────────────────────────────────────

const FOLLOW_AREA: float = 40.0   ## Particle box width/depth around player
const RAIN_HEIGHT: float = 25.0   ## How high above player rain spawns
const SNOW_HEIGHT: float = 20.0

const RAIN_AMOUNT: int = 3000
const SNOW_AMOUNT: int = 1500


func setup(weather: String, camera: Camera3D) -> void:
	_camera = camera
	match weather:
		"rain":
			_create_rain()
		"snow":
			_create_snow()
		_:
			# clear / overcast — no particles
			pass


func _process(_delta: float) -> void:
	if _camera:
		global_position = _camera.global_position


## ── Rain ─────────────────────────────────────────────────────────────────

func _create_rain() -> void:
	_rain_particles = GPUParticles3D.new()
	_rain_particles.name = "RainParticles"
	_rain_particles.amount = RAIN_AMOUNT
	_rain_particles.lifetime = 1.5
	# Large AABB so particles are never frustum-culled
	_rain_particles.visibility_aabb = AABB(
		Vector3(-50, -50, -50), Vector3(100, 100, 100)
	)

	# Process material
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(FOLLOW_AREA / 2.0, 1.0, FOLLOW_AREA / 2.0)

	# Rain falls fast and straight with slight angle
	mat.direction = Vector3(0.1, -1.0, 0.05)
	mat.spread = 5.0
	mat.initial_velocity_min = 15.0
	mat.initial_velocity_max = 20.0
	mat.gravity = Vector3(0.0, -12.0, 0.0)

	# Scale
	mat.scale_min = 1.0
	mat.scale_max = 1.5

	# Color with alpha
	var rain_color := PaletteManager.get_color(&"bg_light")
	mat.color = Color(rain_color.r, rain_color.g, rain_color.b, 0.6)

	_rain_particles.process_material = mat
	_rain_particles.position.y = RAIN_HEIGHT

	# Draw pass — thin stretched quad for rain streaks
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.03, 0.5)
	var draw_mat := StandardMaterial3D.new()
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.albedo_color = Color(rain_color.r, rain_color.g, rain_color.b, 0.6)
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	mesh.material = draw_mat
	_rain_particles.draw_pass_1 = mesh

	add_child(_rain_particles)

	# Connect palette changes
	PaletteManager.palette_changed.connect(func(_p: Resource) -> void:
		var c := PaletteManager.get_color(&"bg_light")
		mat.color = Color(c.r, c.g, c.b, 0.6)
		draw_mat.albedo_color = Color(c.r, c.g, c.b, 0.6)
	)


## ── Snow ─────────────────────────────────────────────────────────────────

func _create_snow() -> void:
	_snow_particles = GPUParticles3D.new()
	_snow_particles.name = "SnowParticles"
	_snow_particles.amount = SNOW_AMOUNT
	_snow_particles.lifetime = 4.0
	_snow_particles.visibility_aabb = AABB(
		Vector3(-FOLLOW_AREA / 2.0, -5.0, -FOLLOW_AREA / 2.0),
		Vector3(FOLLOW_AREA, SNOW_HEIGHT + 10.0, FOLLOW_AREA)
	)

	# Process material
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(FOLLOW_AREA / 2.0, 0.5, FOLLOW_AREA / 2.0)

	# Snow drifts slowly with some horizontal sway
	mat.direction = Vector3(0.0, -1.0, 0.0)
	mat.spread = 15.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 4.0
	mat.gravity = Vector3(0.5, -2.0, 0.3)

	# Small flakes with size variance
	mat.scale_min = 0.4
	mat.scale_max = 1.0

	# Slight turbulence via angular velocity
	mat.angular_velocity_min = -30.0
	mat.angular_velocity_max = 30.0

	# Palette-driven color
	var snow_color := PaletteManager.get_color(&"bg_light")
	snow_color.a = 0.7
	mat.color = snow_color

	_snow_particles.process_material = mat
	_snow_particles.position.y = SNOW_HEIGHT

	# Draw pass — small billboard quad for snowflakes
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.08, 0.08)
	var draw_mat := StandardMaterial3D.new()
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.albedo_color = Color(snow_color.r, snow_color.g, snow_color.b, 0.7)
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	draw_mat.no_depth_test = true
	mesh.material = draw_mat
	_snow_particles.draw_pass_1 = mesh

	add_child(_snow_particles)

	# Connect palette changes
	PaletteManager.palette_changed.connect(func(_p: Resource) -> void:
		var c := PaletteManager.get_color(&"bg_light")
		c.a = 0.7
		mat.color = c
		draw_mat.albedo_color = Color(c.r, c.g, c.b, 0.7)
	)
