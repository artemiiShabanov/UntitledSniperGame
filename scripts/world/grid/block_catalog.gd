class_name BlockCatalog
extends Resource
## Collection of BlockDef entries for a level theme.
## Provides filtered lookups and weighted random selection for the solver.

@export var catalog_name: String = ""
@export var blocks: Array[BlockDef] = []


## ── Lookups ──────────────────────────────────────────────────────────────────

func get_by_id(block_id: String) -> BlockDef:
	for b in blocks:
		if b.id == block_id:
			return b
	return null


func get_blocks_by_type(type: BlockDef.BlockType) -> Array[BlockDef]:
	var result: Array[BlockDef] = []
	for b in blocks:
		if b.block_type == type:
			result.append(b)
	return result


func get_blocks_by_height(height: BlockDef.HeightType) -> Array[BlockDef]:
	var result: Array[BlockDef] = []
	for b in blocks:
		if b.height_type == height:
			result.append(b)
	return result


func get_blocks_by_tag(tag: String) -> Array[BlockDef]:
	var result: Array[BlockDef] = []
	for b in blocks:
		if tag in b.tags:
			result.append(b)
	return result


## ── Weighted selection ───────────────────────────────────────────────────────

## Pick a random block from [candidates] using weights.
## Returns null if candidates is empty.
static func pick_weighted_from(
	rng: RandomNumberGenerator,
	candidates: Array[BlockDef],
) -> BlockDef:
	if candidates.is_empty():
		return null

	var total_weight: float = 0.0
	for b in candidates:
		total_weight += b.weight

	if total_weight <= 0.0:
		return candidates[rng.randi() % candidates.size()]

	var roll: float = rng.randf() * total_weight
	var running: float = 0.0
	for b in candidates:
		running += b.weight
		if roll <= running:
			return b

	return candidates.back()
