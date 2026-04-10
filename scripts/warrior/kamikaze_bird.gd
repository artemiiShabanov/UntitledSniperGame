class_name KamikazeBird
extends CharacterBody3D
## Kamikaze bird — flies toward the player, deals 1 life damage on arrival.
## Can be shot down by the player (1 hit kill).

@export var fly_speed: float = 15.0
@export var damage: float = 100.0  ## Lethal to self, triggers RunManager.take_hit()
@export var arrival_distance: float = 2.0
@export var lifetime: float = 15.0

var _target: Node3D = null
var _time_alive: float = 0.0


func _ready() -> void:
	add_to_group("enemy")  # So player bullets can hit it


func set_target(target: Node3D) -> void:
	_target = target


func _physics_process(delta: float) -> void:
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()
		return

	if not is_instance_valid(_target):
		queue_free()
		return

	var target_pos := _target.global_position + Vector3.UP * 1.2
	var dir := (target_pos - global_position).normalized()

	velocity = dir * fly_speed
	move_and_slide()

	# Face movement direction.
	if dir.length_squared() > 0.001:
		look_at(global_position + dir, Vector3.UP)

	# Check arrival.
	if global_position.distance_to(target_pos) < arrival_distance:
		RunManager.take_hit()
		queue_free()


func on_bullet_hit(_bullet: Node, _collision: KinematicCollision3D) -> void:
	## Shot down by the player. No score — killing the trainer is the reward.
	RunManager.record_shot_hit()
	queue_free()
