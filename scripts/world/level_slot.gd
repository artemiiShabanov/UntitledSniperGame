class_name LevelSlot
extends Marker3D
## Place in a level to mark a blank zone that gets filled with a random chunk.
## The chunk scene is instanced as a child and inherits this node's transform.

@export var slot_data: LevelSlotData
