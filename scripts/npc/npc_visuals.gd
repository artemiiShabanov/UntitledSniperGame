class_name NpcVisuals
extends Node
## Manages debug visualization for NPCs.
## Lightweight — no glint, no laser, just a state indicator sphere.

var npc: NpcBase

## Debug
var _state_indicator: MeshInstance3D
var _state_mat: StandardMaterial3D
var show_debug: bool = false

const STATE_COLORS := {
	NpcBase.PanicState.CALM: Color(0.2, 0.6, 0.9, 0.8),     ## Blue
	NpcBase.PanicState.PANICKING: Color(1.0, 0.8, 0.0, 0.8), ## Yellow
}


func setup(owner_npc: NpcBase) -> void:
	npc = owner_npc
	show_debug = npc.show_debug

	# Apply mesh color from NPC type
	if npc.npc_type and npc.mesh:
		_apply_mesh_color(npc.npc_type.mesh_color)

	if show_debug:
		_setup_debug_visuals()


func update_visuals() -> void:
	if show_debug and _state_mat:
		_state_mat.albedo_color = STATE_COLORS.get(npc.panic_state, Color.WHITE)


func on_death() -> void:
	if _state_indicator:
		_state_indicator.visible = false


func _apply_mesh_color(color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	for child in npc.mesh.get_children():
		if child is MeshInstance3D:
			child.material_override = mat
		elif child is CSGShape3D:
			child.material = mat


func _setup_debug_visuals() -> void:
	_state_indicator = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	_state_indicator.mesh = sphere
	_state_indicator.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_state_indicator.position = Vector3(0, 2.3, 0)

	_state_mat = StandardMaterial3D.new()
	_state_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_state_mat.albedo_color = STATE_COLORS[NpcBase.PanicState.CALM]
	_state_indicator.material_override = _state_mat

	npc.add_child(_state_indicator)
