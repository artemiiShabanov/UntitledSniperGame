class_name BlockInstance
extends Node3D
## Optional root script for block scenes that need internal randomization.
## Attach this to a block's root Node3D to enable prop shuffling on spawn.

@export var randomize_props: bool = false
## Probability (0-1) that each optional prop group is included
@export var prop_inclusion_chance: float = 0.6


func _ready() -> void:
	if randomize_props:
		_randomize_internal_props()


## Iterate children in the "Props/" group and randomly show/hide them.
func _randomize_internal_props() -> void:
	var props_node := get_node_or_null("Props")
	if not props_node:
		return

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for child in props_node.get_children():
		if child is Node3D:
			child.visible = rng.randf() < prop_inclusion_chance
			# Randomize Y rotation for variety
			if child.visible:
				child.rotation.y = rng.randf() * TAU
