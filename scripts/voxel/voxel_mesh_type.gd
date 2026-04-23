class_name VoxelMeshType
extends RefCounted
## Per-mesh semantic role for voxel models. Determines which palette slots
## the shader uses to replace PRIMARY / SECONDARY source colors.
##
## Rule: each voxel model uses exactly one type. If a model needs multiple
## roles (e.g. War Chief body + accent-tagged cape), split into child meshes
## and tag each child independently.

enum Type {
	GOOD,    # friendly warriors, friendly banners, kill confirm
	BAD,     # enemy warriors, damage flash, low-HP warning
	ACCENT,  # extraction markers, opportunity targets, muzzle flash
	FILLER,  # wood, leather, cloth, skin — material-warmth objects
}

## Returns a StringName suitable for logging / inspector display.
static func name_of(t: Type) -> StringName:
	match t:
		Type.GOOD:   return &"good"
		Type.BAD:    return &"bad"
		Type.ACCENT: return &"accent"
		Type.FILLER: return &"filler"
	return &"invalid"
