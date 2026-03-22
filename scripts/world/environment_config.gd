class_name EnvironmentConfig
extends RefCounted
## Static configuration for time of day and weather presets.
## Used by BaseLevel to apply environment settings on run start.


## ── Time of Day presets ─────────────────────────────────────────────────────

static var time_presets: Dictionary = {
	"morning": {
		"sun_color": Color(1.0, 0.75, 0.45),
		"sun_energy": 0.8,
		"sun_angle_x": -25.0,   # Low sun angle
		"sun_angle_y": -60.0,
		"ambient_color": Color(0.5, 0.4, 0.3),
		"ambient_energy": 0.4,
		"sky_top_color": Color(0.4, 0.5, 0.7),
		"sky_bottom_color": Color(0.8, 0.6, 0.4),
	},
	"day": {
		"sun_color": Color(1.0, 0.97, 0.9),
		"sun_energy": 1.0,
		"sun_angle_x": -55.0,   # High sun
		"sun_angle_y": -30.0,
		"ambient_color": Color(0.5, 0.55, 0.65),
		"ambient_energy": 0.5,
		"sky_top_color": Color(0.3, 0.5, 0.85),
		"sky_bottom_color": Color(0.65, 0.75, 0.9),
	},
	"evening": {
		"sun_color": Color(1.0, 0.45, 0.2),
		"sun_energy": 0.7,
		"sun_angle_x": -15.0,   # Very low sun
		"sun_angle_y": 120.0,
		"ambient_color": Color(0.45, 0.3, 0.25),
		"ambient_energy": 0.35,
		"sky_top_color": Color(0.25, 0.25, 0.5),
		"sky_bottom_color": Color(0.9, 0.4, 0.2),
	},
	"night": {
		"sun_color": Color(0.4, 0.5, 0.75),
		"sun_energy": 0.15,
		"sun_angle_x": -35.0,   # Moonlight angle
		"sun_angle_y": 45.0,
		"ambient_color": Color(0.15, 0.18, 0.3),
		"ambient_energy": 0.25,
		"sky_top_color": Color(0.05, 0.05, 0.15),
		"sky_bottom_color": Color(0.1, 0.1, 0.2),
	},
}


## ── Weather presets ─────────────────────────────────────────────────────────

static var weather_presets: Dictionary = {
	"clear": {
		"fog_enabled": false,
		"fog_density": 0.0,
		"fog_color": Color(0.8, 0.85, 0.9),
		"volumetric_fog_enabled": false,
		"volumetric_fog_density": 0.0,
		"visibility_multiplier": 1.0,   # Used by enemy detection range
	},
	"snow": {
		"fog_enabled": true,
		"fog_density": 0.01,
		"fog_color": Color(0.85, 0.88, 0.95),
		"volumetric_fog_enabled": true,
		"volumetric_fog_density": 0.03,
		"visibility_multiplier": 0.6,   # Reduced visibility from snowfall
	},
	"rain": {
		"fog_enabled": true,
		"fog_density": 0.005,
		"fog_color": Color(0.5, 0.55, 0.6),
		"volumetric_fog_enabled": false,
		"volumetric_fog_density": 0.0,
		"visibility_multiplier": 0.75,  # Slight visibility reduction
	},
	"overcast": {
		"fog_enabled": true,
		"fog_density": 0.003,
		"fog_color": Color(0.6, 0.6, 0.65),
		"volumetric_fog_enabled": false,
		"volumetric_fog_density": 0.0,
		"visibility_multiplier": 0.9,   # Minor visibility reduction
	},
}


## ── Application ─────────────────────────────────────────────────────────────

static func apply_time_of_day(sun: DirectionalLight3D, env: WorldEnvironment, preset_name: String) -> void:
	if not time_presets.has(preset_name):
		push_warning("Unknown time preset: %s" % preset_name)
		return

	var p: Dictionary = time_presets[preset_name]

	# Sun
	if sun:
		sun.light_color = p.sun_color
		sun.light_energy = p.sun_energy
		sun.rotation_degrees.x = p.sun_angle_x
		sun.rotation_degrees.y = p.sun_angle_y

	# Environment ambient + sky
	if env and env.environment:
		env.environment.ambient_light_color = p.ambient_color
		env.environment.ambient_light_energy = p.ambient_energy

		# Apply sky colors to ProceduralSkyMaterial
		if env.environment.sky and env.environment.sky.sky_material is ProceduralSkyMaterial:
			var sky_mat: ProceduralSkyMaterial = env.environment.sky.sky_material
			sky_mat.sky_top_color = p.sky_top_color
			sky_mat.sky_horizon_color = p.sky_bottom_color


static func apply_weather(env: WorldEnvironment, preset_name: String) -> void:
	if not weather_presets.has(preset_name):
		push_warning("Unknown weather preset: %s" % preset_name)
		return

	var p: Dictionary = weather_presets[preset_name]

	if not env or not env.environment:
		return

	env.environment.fog_enabled = p.fog_enabled
	if p.fog_enabled:
		env.environment.fog_density = p.fog_density
		env.environment.fog_light_color = p.fog_color

	env.environment.volumetric_fog_enabled = p.volumetric_fog_enabled
	if p.volumetric_fog_enabled:
		env.environment.volumetric_fog_density = p.volumetric_fog_density


static func get_visibility_multiplier(weather_name: String) -> float:
	if weather_presets.has(weather_name):
		return weather_presets[weather_name].visibility_multiplier
	return 1.0
