class_name BlockDef
extends Resource
## Lightweight descriptor for a single placeable block type.
## The actual geometry lives in block_scene (.tscn) — this resource
## carries metadata used by the grid solver during level generation.

## ── Enums ────────────────────────────────────────────────────────────────────

enum HeightType { GROUND, LOW, MEDIUM, TALL, TOWER }
enum BlockType { EMPTY, PROPS, ENEMY, NPC, EVENT, SNIPER_NEST, CASTLE, BATTLEFIELD, ENEMY_CAMP }

## ── Properties ───────────────────────────────────────────────────────────────

@export var id: String = ""
@export var display_name: String = ""
@export var block_scene: PackedScene  ## The .tscn to instantiate at runtime
@export var grid_size: Vector2i = Vector2i(1, 1)  ## Width x Depth in cells

@export_group("Classification")
@export var height_type: HeightType = HeightType.GROUND
@export var block_type: BlockType = BlockType.PROPS
@export var tags: PackedStringArray = []  ## Freeform: "warehouse", "cover_heavy", etc.

@export_group("Selection")
@export var weight: float = 1.0  ## Higher = more likely to be picked during fill
@export var max_per_level: int = -1  ## -1 = unlimited

@export_group("Spawning")
@export var is_player_spawn: bool = false  ## Player can spawn on this block
@export var is_extraction_zone: bool = false  ## Extraction zone can be placed here

@export_group("Behavior")
@export var internal_randomization: bool = false  ## Scene randomizes its own props


## ── Factory ──────────────────────────────────────────────────────────────────

static func create(
	p_id: String,
	p_name: String,
	p_scene: PackedScene,
	p_height: HeightType,
	p_type: BlockType,
	p_tags: PackedStringArray = [],
	p_weight: float = 1.0,
	p_grid_size: Vector2i = Vector2i(1, 1),
	p_max_per_level: int = -1,
	p_randomize: bool = false,
	p_player_spawn: bool = false,
	p_extraction: bool = false,
) -> BlockDef:
	var def := BlockDef.new()
	def.id = p_id
	def.display_name = p_name
	def.block_scene = p_scene
	def.height_type = p_height
	def.block_type = p_type
	def.tags = p_tags
	def.weight = p_weight
	def.grid_size = p_grid_size
	def.max_per_level = p_max_per_level
	def.internal_randomization = p_randomize
	def.is_player_spawn = p_player_spawn
	def.is_extraction_zone = p_extraction
	return def
