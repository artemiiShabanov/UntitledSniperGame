class_name RifleMod
extends Resource
## A single rifle modification that can be equipped in one slot.

@export var id: String = ""
@export var mod_name: String = ""
@export var slot: String = ""  ## "barrel", "stock", "bolt", "magazine", "scope"
@export var cost: int = 0
@export var description: String = ""
@export var stat_overrides: Dictionary = {}  ## Maps weapon property name → value
@export var special: String = ""  ## Special behavior key (e.g. "variable_zoom")
@export var icon: Texture2D  ## UI icon (assets/icons/mods/)


static func create(p_id: String, p_name: String, p_slot: String, p_cost: int, p_desc: String, p_stats: Dictionary = {}, p_special: String = "") -> RifleMod:
	var mod := RifleMod.new()
	mod.id = p_id
	mod.mod_name = p_name
	mod.slot = p_slot
	mod.cost = p_cost
	mod.description = p_desc
	mod.stat_overrides = p_stats
	mod.special = p_special
	return mod
