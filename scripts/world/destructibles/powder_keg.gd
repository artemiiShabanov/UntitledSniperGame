class_name PowderKeg
extends DestructibleTarget
## Powder Keg — static, one-shot, AoE explosion damages nearby hostile warriors.
## Placed in Zone 2/3 near enemy clusters. Phase 1+. 80 score.

@export var explosion_radius: float = 8.0
@export var explosion_damage: int = 200


func _ready() -> void:
	score_reward = Scoring.POWDER_KEG
	super._ready()


func _on_destroy() -> void:
	_darken_mesh()
	_explode()


func _explode() -> void:
	VFXFactory.spawn_explosion(global_position, explosion_radius)
	AudioManager.play_sfx(&"explosion", global_position)

	# Damage all warriors in radius.
	var warriors := get_tree().get_nodes_in_group("warrior")
	for w in warriors:
		if w is WarriorBase and w.state != WarriorBase.State.DEAD:
			var dist: float = global_position.distance_to(w.global_position)
			if dist <= explosion_radius:
				# Full damage at center, falloff at edge.
				var falloff := 1.0 - (dist / explosion_radius)
				var damage := int(explosion_damage * falloff)
				w.take_melee_damage(damage)
