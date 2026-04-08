class_name DestructibleMovingTarget
extends CharacterBody3D
## Base class for moving destructible targets (rat, bird, balloon).
## Mirrors DestructibleTarget's destroy contract for CharacterBody3D types.

signal target_destroyed(target: DestructibleMovingTarget)

@export var credit_reward: int = 25
@export var xp_reward: int = 10

var is_destroyed: bool = false


func _ready() -> void:
	add_to_group("destructible")


func on_bullet_hit(_bullet: Bullet, _collision: KinematicCollision3D) -> void:
	if is_destroyed:
		return
	_destroy()


func _destroy() -> void:
	is_destroyed = true
	velocity = Vector3.ZERO
	target_destroyed.emit(self)
	RunManager.record_target_destroyed(credit_reward, xp_reward)
	AudioManager.play_sfx(&"target_destroyed", global_position)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	_on_destroy()


## Override in subclasses for custom destruction effects.
func _on_destroy() -> void:
	VFXFactory.spawn_death_effect(self, false)
