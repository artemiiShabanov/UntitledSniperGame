class_name RifleMod
extends Resource
## A procedurally generated rifle modification.
## Generated on extraction — rarity determines stat budget and durability.

enum Rarity { COMMON, UNCOMMON, RARE, EPIC }
enum Slot { BARREL, STOCK, BOLT, MAGAZINE, SCOPE }

const SLOT_NAMES := ["barrel", "stock", "bolt", "magazine", "scope"]
const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Epic"]

## Budget points allocated per rarity.
const RARITY_BUDGETS := [30, 60, 100, 150]
## Max durability (runs) per rarity.
const RARITY_DURABILITY := [2, 4, 7, 10]

@export var slot: Slot = Slot.BARREL
@export var rarity: Rarity = Rarity.COMMON
@export var stat_budget: int = 0
@export var stats: Dictionary = {}  ## e.g. {"velocity": 1.2, "stay_scoped": true}
@export var durability: int = 2
@export var max_durability: int = 2
@export var visual_type: int = 1  ## 1-3 per slot, determines visual appearance


## Stat tables per slot — keys are the stat names, values are [min, max] ranges.
## Budget is distributed across these stats proportionally.
const SLOT_STAT_TABLES := {
	Slot.BARREL: {
		"velocity": [0.8, 1.5],        # muzzle velocity multiplier
		"accuracy": [0.8, 1.3],         # accuracy multiplier
		"falloff": [0.8, 1.4],          # damage falloff range multiplier
	},
	Slot.STOCK: {
		"sway_reduction": [0.0, 0.5],   # sway amplitude reduction (0-50%)
		"move_speed": [0.85, 1.15],      # movement speed multiplier
	},
	Slot.BOLT: {
		"cycle_time": [0.6, 1.2],        # bolt cycle duration (seconds, lower=better)
		"stay_scoped": [40],              # boolean — costs 40 budget to activate
	},
	Slot.MAGAZINE: {
		"capacity": [4.0, 10.0],          # extra bullet capacity added to base 30
		"headshot_damage": [1.5, 3.0],    # headshot damage multiplier
	},
	Slot.SCOPE: {
		"clarity": [0.5, 1.0],            # scope clarity (affects sway while scoped)
		"fov": [8.0, 40.0],               # scoped FOV in degrees (lower=more zoom)
		"variable_zoom": [50],             # boolean — costs 50 budget to activate
	},
}

## Boolean stats are entries with a single-element array [cost].
## They are purchased from the budget at that fixed cost.
## All other stats have a two-element [min, max] range.


static func slot_from_name(name: String) -> Slot:
	var idx := SLOT_NAMES.find(name)
	if idx >= 0:
		return idx as Slot
	return Slot.BARREL


static func slot_to_name(s: Slot) -> String:
	return SLOT_NAMES[s]


func get_slot_name() -> String:
	return SLOT_NAMES[slot]


func get_rarity_name() -> String:
	return RARITY_NAMES[rarity]


func tick_durability() -> bool:
	## Decrements durability. Returns true if mod is now depleted (should be removed).
	durability -= 1
	return durability <= 0


func serialize() -> Dictionary:
	return {
		"slot": slot,
		"rarity": rarity,
		"stat_budget": stat_budget,
		"stats": stats.duplicate(),
		"durability": durability,
		"max_durability": max_durability,
		"visual_type": visual_type,
	}


static func deserialize(data: Dictionary) -> RifleMod:
	var mod := RifleMod.new()
	mod.slot = data.get("slot", Slot.BARREL) as Slot
	mod.rarity = data.get("rarity", Rarity.COMMON) as Rarity
	mod.stat_budget = data.get("stat_budget", 0)
	mod.stats = data.get("stats", {}).duplicate()
	mod.durability = data.get("durability", 1)
	mod.max_durability = data.get("max_durability", 1)
	mod.visual_type = data.get("visual_type", 1)
	return mod
