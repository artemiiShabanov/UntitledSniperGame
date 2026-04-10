class_name WarriorBirdTrainer
extends WarriorRangedBase
## Bird Trainer — releases kamikaze birds at the player. Phase 11+.
## Birds fly toward player and deal 1 life on arrival. Max 3 active birds.
## The trainer itself doesn't shoot projectiles — it spawns birds instead.

const MAX_ACTIVE_BIRDS: int = 3

@export var bird_scene: PackedScene  ## KamikazeBird scene
var _active_birds: Array[Node] = []


func _ready() -> void:
	max_hp = 70
	armor = 0
	move_speed = 2.5
	castle_damage = 0
	base_score = Scoring.BIRD_TRAINER
	min_phase = 11
	firing_range = 80.0
	accuracy = 1.0  # Birds always launch successfully
	shoot_interval = 3.5
	projectile_speed = 0.0  # Not used — birds have their own speed
	reposition_chance = 0.3
	reposition_radius = 10.0
	super._ready()


func _shoot_at_player(player: Node3D) -> void:
	## Override: spawn a bird instead of an arrow.
	# Clean up dead bird references.
	_active_birds = _active_birds.filter(func(b: Node) -> bool: return is_instance_valid(b))

	if _active_birds.size() >= MAX_ACTIVE_BIRDS:
		return
	if not bird_scene:
		return

	var bird: Node3D = bird_scene.instantiate()
	var spawn_pos := global_position + Vector3.UP * 1.8
	get_tree().root.add_child(bird)
	bird.global_position = spawn_pos

	if bird.has_method("set_target"):
		bird.set_target(player)

	_active_birds.append(bird)
