class_name SiegeEquipment
extends DestructibleTarget
## Siege Equipment — static, one-shot, drains castle HP/sec while alive.
## Placed in Zone 3. Phase 6+. 150 score. High priority target.

@export var castle_drain_per_second: float = 2.0

var _draining: bool = true


func _ready() -> void:
	score_reward = Scoring.SIEGE_EQUIPMENT
	super._ready()
	_draining = true


func _process(delta: float) -> void:
	if not _draining or is_destroyed:
		return
	if RunManager.game_state != RunManager.GameState.IN_RUN:
		return

	# Passive castle HP drain.
	var damage := int(castle_drain_per_second * delta * 10.0)  # Accumulate fractional damage
	if damage > 0:
		RunManager.castle_take_damage(damage)


func _on_destroy() -> void:
	_draining = false
	_darken_mesh()
	AudioManager.play_sfx(&"siege_destroyed", global_position)
