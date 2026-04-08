class_name DestructibleBalloon
extends DestructibleMovingTarget
## Balloon — rising target that must be shot before it floats away.
## 3 tiers tied to threat phases, spawns near enemies mid-run.
## Pops (despawns with no reward) when it reaches max height.

enum Tier { BRONZE, SILVER, GOLD }

@export var tier: Tier = Tier.BRONZE
@export var rise_speed: float = 1.5  ## Meters per second
@export var max_height: float = 40.0  ## Pops at this height above spawn
@export var sway_amount: float = 0.3  ## Horizontal sway amplitude
@export var sway_speed: float = 1.5

var _spawn_y: float = 0.0
var _mesh_node: Node3D
var _time: float = 0.0

const TIER_CONFIG: Dictionary = {
	Tier.BRONZE: {
		"credits": 50, "xp": 20,
		"color": Color(0.8, 0.5, 0.2),
		"radius": 0.4, "rise_speed": 1.8, "max_height": 35.0,
	},
	Tier.SILVER: {
		"credits": 100, "xp": 40,
		"color": Color(0.75, 0.75, 0.8),
		"radius": 0.35, "rise_speed": 2.2, "max_height": 40.0,
	},
	Tier.GOLD: {
		"credits": 200, "xp": 75,
		"color": Color(1.0, 0.85, 0.15),
		"radius": 0.3, "rise_speed": 2.8, "max_height": 50.0,
	},
}

## Phase thresholds — tier unlocks at this threat phase
const TIER_MIN_PHASE: Dictionary = {
	Tier.BRONZE: 3,
	Tier.SILVER: 5,
	Tier.GOLD: 7,
}


func _ready() -> void:
	super._ready()
	_spawn_y = global_position.y
	_mesh_node = get_node_or_null("Mesh")
	_apply_tier()
	_time = randf() * TAU  # Random sway offset


func _physics_process(delta: float) -> void:
	if is_destroyed:
		return

	_time += delta

	# Rise
	velocity.y = rise_speed

	# Gentle sway
	var sway_x := sin(_time * sway_speed) * sway_amount
	var sway_z := cos(_time * sway_speed * 0.7) * sway_amount * 0.5
	velocity.x = sway_x
	velocity.z = sway_z

	move_and_slide()

	# Pop if too high
	if global_position.y - _spawn_y >= max_height:
		_pop()


func _apply_tier() -> void:
	var config: Dictionary = TIER_CONFIG.get(tier, TIER_CONFIG[Tier.BRONZE])
	credit_reward = config.credits
	xp_reward = config.xp
	rise_speed = config.rise_speed
	max_height = config.max_height

	if not _mesh_node:
		return
	var body: MeshInstance3D = _mesh_node.get_node_or_null("Body")
	if not body:
		return

	# Sphere mesh for balloon
	var sphere := SphereMesh.new()
	sphere.radius = config.radius
	sphere.height = config.radius * 2.5  # Slightly elongated
	body.mesh = sphere

	# Emissive material so it's visible at distance
	var mat := StandardMaterial3D.new()
	mat.albedo_color = config.color
	mat.emission_enabled = true
	mat.emission = config.color
	mat.emission_energy_multiplier = 1.5
	body.material_override = mat


func _pop() -> void:
	## Balloon reached max height — despawn with no reward.
	is_destroyed = true
	velocity = Vector3.ZERO
	AudioManager.play_sfx(&"target_destroyed", global_position)
	queue_free()


static func get_tier_for_phase(phase: int) -> Tier:
	## Returns the highest tier available at the given threat phase.
	if phase >= TIER_MIN_PHASE[Tier.GOLD]:
		return Tier.GOLD
	elif phase >= TIER_MIN_PHASE[Tier.SILVER]:
		return Tier.SILVER
	else:
		return Tier.BRONZE


static func can_spawn_at_phase(phase: int) -> bool:
	return phase >= TIER_MIN_PHASE[Tier.BRONZE]
