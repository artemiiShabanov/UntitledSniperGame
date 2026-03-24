extends Node
## Contract Registry — autoloaded singleton.
## Holds all available contracts. Each run, a random selection is offered.

var _contracts: Dictionary = {}  ## { id: Contract }

const CONTRACTS_OFFERED_PER_RUN := 3


func _ready() -> void:
	_register_all()


func get_contract(id: String) -> Contract:
	return _contracts.get(id, null)


func get_all_contracts() -> Array[Contract]:
	var result: Array[Contract] = []
	for c: Contract in _contracts.values():
		result.append(c)
	return result


func get_random_selection(count: int = CONTRACTS_OFFERED_PER_RUN) -> Array[Contract]:
	## Returns a random subset of contracts for the player to choose from.
	var all := get_all_contracts()
	all.shuffle()
	var result: Array[Contract] = []
	for i in range(mini(count, all.size())):
		result.append(all[i])
	return result


## ── Contract Definitions ────────────────────────────────────────────────────

func _register_all() -> void:
	_add(Contract.create(
		"kill_3", "Clean Sweep",
		"Eliminate at least 3 enemies.",
		Contract.Type.KILL_COUNT, 3.0, 75, 30
	))
	_add(Contract.create(
		"kill_5", "Body Count",
		"Eliminate at least 5 enemies.",
		Contract.Type.KILL_COUNT, 5.0, 150, 50
	))
	_add(Contract.create(
		"headshot_2", "Precision Work",
		"Score at least 2 headshots.",
		Contract.Type.HEADSHOT_COUNT, 2.0, 100, 40
	))
	_add(Contract.create(
		"headshot_4", "Dead Eye",
		"Score at least 4 headshots.",
		Contract.Type.HEADSHOT_COUNT, 4.0, 200, 75
	))
	_add(Contract.create(
		"accuracy_80", "Sharpshooter",
		"Finish with at least 80% accuracy.",
		Contract.Type.ACCURACY, 80.0, 150, 50
	))
	_add(Contract.create(
		"no_hits", "Ghost",
		"Extract without taking any damage.",
		Contract.Type.NO_HITS, 0.0, 200, 80
	))
	_add(Contract.create(
		"speed_60", "Quick Job",
		"Extract within 60 seconds.",
		Contract.Type.SPEED_EXTRACT, 60.0, 175, 60
	))


func _add(contract: Contract) -> void:
	_contracts[contract.id] = contract
