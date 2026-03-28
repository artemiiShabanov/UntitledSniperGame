extends Node
## Ammo Registry — autoloaded singleton.
## Central catalog of all ammo types.

var _types: Array[AmmoType] = []


func _ready() -> void:
	_load_all()


func get_all_types() -> Array[AmmoType]:
	return _types


func get_type(ammo_id: String) -> AmmoType:
	for t in _types:
		if t.ammo_id == ammo_id:
			return t
	return null


func _load_all() -> void:
	var paths := [
		"res://data/ammo/standard.tres",
		"res://data/ammo/armor_piercing.tres",
		"res://data/ammo/high_damage.tres",
		"res://data/ammo/shock.tres",
		"res://data/ammo/golden.tres",
	]
	for path in paths:
		var res := load(path)
		if res is AmmoType:
			if not res.icon:
				var icon_path := "res://assets/icons/ammo/%s.png" % res.ammo_id
				if ResourceLoader.exists(icon_path):
					res.icon = load(icon_path)
			_types.append(res)
