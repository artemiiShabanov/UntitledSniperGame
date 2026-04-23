class_name PaletteMesh
extends MeshInstance3D
## Attach to any MeshInstance3D to drive its color from the active palette.
## Select a palette slot in the Inspector — color updates live on palette swap.
## For scripted entities, prefer PaletteManager.bind_meshes(self, &"slot") instead.

## Slot names matching PaletteResource property names.
## Using StringName directly avoids a duplicated enum.
@export_enum("gs_light", "gs_mid_light", "gs_mid_dark", "gs_dark", "good", "good_muted", "bad", "bad_muted", "accent", "accent_muted", "filler", "filler_muted")
var palette_slot: String = "gs_mid_light"

## Optional: blend with a base tint for variation (white = pure palette color).
@export var tint: Color = Color.WHITE

var _material: StandardMaterial3D


func _ready() -> void:
	@warning_ignore("static_called_on_instance")
	_material = PaletteManager._ensure_unique_material(self)
	PaletteManager.palette_changed.connect(_on_palette_changed)
	_apply_color()


func _on_palette_changed(_palette: PaletteResource) -> void:
	_apply_color()


func _apply_color() -> void:
	if not _material:
		return
	_material.albedo_color = PaletteManager.get_color(StringName(palette_slot)) * tint
