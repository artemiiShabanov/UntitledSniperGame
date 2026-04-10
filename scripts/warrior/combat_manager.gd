class_name CombatManager
extends Node
## Manages 1v1 warrior pairings on the battlefield.
## Added as a child of the level scene — not an autoload.
## Each physics tick, pairs unpaired warriors from opposing factions.

const DETECTION_RANGE: float = 20.0  ## Max distance to form a pair
const PAIR_INTERVAL: float = 0.3     ## Seconds between pairing sweeps (perf)

var _pair_timer: float = 0.0


func _physics_process(delta: float) -> void:
	_pair_timer -= delta
	if _pair_timer > 0.0:
		return
	_pair_timer = PAIR_INTERVAL
	_run_pairing()


func _run_pairing() -> void:
	var friendlies: Array[Node] = get_tree().get_nodes_in_group("warrior_friendly")
	var hostiles: Array[Node] = get_tree().get_nodes_in_group("warrior_hostile")

	# Collect unpaired warriors from each side.
	var unpaired_friendly: Array[Node] = []
	var unpaired_hostile: Array[Node] = []

	for w in friendlies:
		if _is_available(w):
			unpaired_friendly.append(w)
	for w in hostiles:
		if _is_available(w):
			unpaired_hostile.append(w)

	# Pair each unpaired hostile with nearest unpaired friendly.
	# Iterate hostiles since they're the aggressors.
	for hostile in unpaired_hostile:
		if unpaired_friendly.is_empty():
			break
		var best_idx := -1
		var best_dist := DETECTION_RANGE
		for i in range(unpaired_friendly.size()):
			var dist: float = hostile.global_position.distance_to(unpaired_friendly[i].global_position)
			if dist < best_dist:
				best_dist = dist
				best_idx = i

		if best_idx >= 0:
			var friendly: Node = unpaired_friendly[best_idx]
			_form_pair(hostile, friendly)
			unpaired_friendly.remove_at(best_idx)


func _is_available(warrior: Node) -> bool:
	## A warrior is available for pairing if alive, not already paired, and not a bombardier.
	if not warrior.has_method("is_pairable"):
		return false
	return warrior.is_pairable()


func _form_pair(a: Node, b: Node) -> void:
	a.set_paired_target(b)
	b.set_paired_target(a)
