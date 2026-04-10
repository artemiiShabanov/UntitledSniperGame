class_name BlockBuilderRegistry
extends RefCounted
## Maps block IDs to their builder functions.
## Used by GridLevelBuilder to construct blocks that use code-based geometry
## instead of (or in addition to) PackedScene .tscn files.

## Builder function signature: func(BlockBuilderBase) -> void
var _builders: Dictionary = {}  ## { block_id: Callable }


func _init() -> void:
	_register_industrial()
	_register_castle_keep()


## ── Registration ─────────────────────────────────────────────────────────────

func _register_industrial() -> void:
	_builders["empty_ground"] = IndustrialBlocks.build_empty_ground
	_builders["ground_cover"] = IndustrialBlocks.build_ground_cover
	_builders["containers"] = IndustrialBlocks.build_containers
	_builders["warehouse_small"] = IndustrialBlocks.build_warehouse_small
	_builders["warehouse_large"] = IndustrialBlocks.build_warehouse_large
	_builders["office"] = IndustrialBlocks.build_office
	_builders["silo_cluster"] = IndustrialBlocks.build_silo_cluster
	_builders["crane"] = IndustrialBlocks.build_crane
	_builders["sniper_tower"] = IndustrialBlocks.build_sniper_tower
	_builders["scaffolding"] = IndustrialBlocks.build_scaffolding
	_builders["fuel_tanks"] = IndustrialBlocks.build_fuel_tanks
	_builders["enemy_rooftop"] = IndustrialBlocks.build_enemy_rooftop
	_builders["enemy_ground"] = IndustrialBlocks.build_enemy_ground
	_builders["enemy_nest"] = IndustrialBlocks.build_enemy_nest
	_builders["npc_work_area"] = IndustrialBlocks.build_npc_work_area
	_builders["npc_rest_area"] = IndustrialBlocks.build_npc_rest_area
	_builders["wall_segment"] = IndustrialBlocks.build_wall_segment


func _register_castle_keep() -> void:
	# Castle (Zone 1)
	_builders["castle_wall"] = CastleKeepBlocks.build_castle_wall
	_builders["castle_tower"] = CastleKeepBlocks.build_castle_tower
	_builders["castle_gate"] = CastleKeepBlocks.build_castle_gate
	_builders["rampart"] = CastleKeepBlocks.build_rampart
	# Battlefield (Zone 2)
	_builders["flat_meadow"] = CastleKeepBlocks.build_flat_meadow
	_builders["rocky_field"] = CastleKeepBlocks.build_rocky_field
	_builders["trench"] = CastleKeepBlocks.build_trench
	_builders["barricade_cluster"] = CastleKeepBlocks.build_barricade_cluster
	_builders["hill"] = CastleKeepBlocks.build_hill
	# Enemy Camp (Zone 3)
	_builders["enemy_camp"] = CastleKeepBlocks.build_enemy_camp
	_builders["siege_position"] = CastleKeepBlocks.build_siege_position
	_builders["archer_post"] = CastleKeepBlocks.build_archer_post
	_builders["palisade_wall"] = CastleKeepBlocks.build_palisade_wall
	_builders["spawn_area"] = CastleKeepBlocks.build_spawn_area


## ── Lookup ───────────────────────────────────────────────────────────────────

func has_builder(block_id: String) -> bool:
	return block_id in _builders


func build_block(block_id: String, block_root: Node3D, rng: RandomNumberGenerator) -> void:
	if block_id not in _builders:
		push_warning("BlockBuilderRegistry: no builder for '%s'" % block_id)
		return

	var base := BlockBuilderBase.new()
	base.setup(block_root, rng)
	_builders[block_id].call(base)
