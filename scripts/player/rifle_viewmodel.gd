class_name RifleViewmodel
extends Node3D
## First-person rifle viewmodel built from CSG primitives.
## Swappable mod attachments update geometry based on equipped loadout.
## Colors itself via PaletteManager (fg_dark).

## ── Constants ───────────────────────────────────────────────────────────────

const HIPFIRE_POS := Vector3(0.25, -0.18, -0.35)
const HIPFIRE_ROT := Vector3(0.0, 0.0, 0.0)
const SCOPE_POS := Vector3(0.0, -0.09, -0.25)
const SCOPE_ROT := Vector3(0.0, 0.0, 0.0)
const LERP_SPEED: float = 14.0
const HIDE_AT_FOV: float = 25.0  ## Hide viewmodel when scoped past this FOV

## ── State ───────────────────────────────────────────────────────────────────

var _mod_parts: Dictionary = {}  ## { slot_name: Node3D }
var _material: StandardMaterial3D

## ── Mod geometry builders ───────────────────────────────────────────────────
## Each returns a Node3D with CSG children representing that mod visually.

func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.albedo_color = Color(0.15, 0.15, 0.15)

	position = HIPFIRE_POS
	rotation = HIPFIRE_ROT

	_build_base_rifle()
	_apply_loadout()
	_apply_palette()

	if PaletteManager:
		PaletteManager.palette_changed.connect(func(_p: PaletteResource) -> void: _apply_palette())


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return

	# Hide when deeply scoped
	var scoped := camera.fov < HIDE_AT_FOV
	visible = not scoped

	if not visible:
		return

	# Smooth position between hip and partial scope
	var is_aiming := camera.fov < 60.0
	var target_pos := SCOPE_POS if is_aiming else HIPFIRE_POS
	position = position.lerp(target_pos, LERP_SPEED * delta)


## ── Base rifle geometry ─────────────────────────────────────────────────────

func _build_base_rifle() -> void:
	# Receiver — the central body
	_add_box("receiver", Vector3(0.035, 0.04, 0.18), Vector3(0, 0, 0))

	# Trigger guard
	_add_box("trigger_guard", Vector3(0.02, 0.03, 0.04), Vector3(0, -0.03, 0.02))

	# Grip
	_add_box("grip", Vector3(0.025, 0.05, 0.03), Vector3(0, -0.045, 0.04))

	# Top rail (for scope mounting)
	_add_box("rail", Vector3(0.02, 0.008, 0.14), Vector3(0, 0.024, -0.01))


func _add_box(part_name: String, size: Vector3, pos: Vector3) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	mesh_instance.material_override = _material
	mesh_instance.name = part_name
	add_child(mesh_instance)
	return mesh_instance


func _add_cylinder(part_name: String, radius: float, height: float, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = 8
	mesh_instance.mesh = cyl
	mesh_instance.position = pos
	mesh_instance.rotation_degrees = rot_deg
	mesh_instance.material_override = _material
	mesh_instance.name = part_name
	add_child(mesh_instance)
	return mesh_instance


## ── Mod attachments ─────────────────────────────────────────────────────────

func _apply_loadout() -> void:
	var loadout: Dictionary = SaveManager.get_equipped_loadout()

	_build_barrel(loadout.get("barrel", "barrel_standard"))
	_build_stock(loadout.get("stock", "stock_standard"))
	_build_magazine(loadout.get("magazine", "magazine_standard"))
	_build_scope(loadout.get("scope", "scope_standard"))
	_build_bolt(loadout.get("bolt", "bolt_standard"))


func _clear_mod(slot: String) -> void:
	if _mod_parts.has(slot):
		var old_node: Node3D = _mod_parts[slot]
		old_node.queue_free()
		_mod_parts.erase(slot)


func _build_barrel(mod_id: String) -> void:
	_clear_mod("barrel")
	var parent := Node3D.new()
	parent.name = "mod_barrel"
	add_child(parent)
	_mod_parts["barrel"] = parent

	var is_long := mod_id == "barrel_long"
	var length: float = 0.35 if is_long else 0.22
	var radius: float = 0.012 if is_long else 0.014

	# Barrel tube
	var barrel := _make_cylinder("barrel_tube", radius, length, Vector3(0, 0, -0.09 - length / 2.0), Vector3(90, 0, 0))
	parent.add_child(barrel)

	# Muzzle brake (slightly wider end)
	if is_long:
		var brake := _make_box("muzzle_brake", Vector3(0.022, 0.022, 0.025), Vector3(0, 0, -0.09 - length + 0.012))
		parent.add_child(brake)


func _build_stock(mod_id: String) -> void:
	_clear_mod("stock")
	var parent := Node3D.new()
	parent.name = "mod_stock"
	add_child(parent)
	_mod_parts["stock"] = parent

	# Stock body — extends backward from receiver
	var stock := _make_box("stock_body", Vector3(0.03, 0.045, 0.16), Vector3(0, -0.005, 0.17))
	parent.add_child(stock)

	# Buttpad
	var butt := _make_box("stock_butt", Vector3(0.035, 0.06, 0.012), Vector3(0, -0.005, 0.255))
	parent.add_child(butt)

	# Cheek rest
	var cheek := _make_box("stock_cheek", Vector3(0.032, 0.015, 0.08), Vector3(0, 0.025, 0.17))
	parent.add_child(cheek)


func _build_magazine(mod_id: String) -> void:
	_clear_mod("magazine")
	var parent := Node3D.new()
	parent.name = "mod_magazine"
	add_child(parent)
	_mod_parts["magazine"] = parent

	var is_extended := mod_id == "magazine_extended"
	var height: float = 0.07 if is_extended else 0.04
	var width: float = 0.028 if is_extended else 0.025

	# Magazine body — hangs below receiver
	var mag := _make_box("mag_body", Vector3(width, height, 0.06), Vector3(0, -0.02 - height / 2.0, 0.03))
	parent.add_child(mag)

	# Baseplate
	var plate := _make_box("mag_plate", Vector3(width + 0.004, 0.005, 0.062), Vector3(0, -0.02 - height, 0.03))
	parent.add_child(plate)


func _build_scope(mod_id: String) -> void:
	_clear_mod("scope")
	var parent := Node3D.new()
	parent.name = "mod_scope"
	add_child(parent)
	_mod_parts["scope"] = parent

	var is_iron := mod_id == "scope_standard"

	if is_iron:
		# Front sight post
		var front := _make_box("front_sight", Vector3(0.004, 0.018, 0.004), Vector3(0, 0.04, -0.07))
		parent.add_child(front)

		# Front sight guard ring
		var guard := _make_cylinder("front_guard", 0.012, 0.005, Vector3(0, 0.035, -0.07), Vector3.ZERO)
		parent.add_child(guard)

		# Rear sight notch
		var rear := _make_box("rear_sight", Vector3(0.018, 0.015, 0.006), Vector3(0, 0.035, 0.04))
		parent.add_child(rear)
	else:
		# Scope tube
		var tube := _make_cylinder("scope_tube", 0.016, 0.16, Vector3(0, 0.045, -0.01), Vector3(90, 0, 0))
		parent.add_child(tube)

		# Objective lens (front, wider)
		var obj := _make_cylinder("scope_obj", 0.022, 0.02, Vector3(0, 0.045, -0.08), Vector3(90, 0, 0))
		parent.add_child(obj)

		# Eyepiece (rear, wider)
		var eye := _make_cylinder("scope_eye", 0.02, 0.02, Vector3(0, 0.045, 0.06), Vector3(90, 0, 0))
		parent.add_child(eye)

		# Scope rings (mount to rail)
		for z_off in [-0.03, 0.03]:
			var ring := _make_cylinder("scope_ring", 0.02, 0.012, Vector3(0, 0.035, z_off), Vector3.ZERO)
			parent.add_child(ring)


func _build_bolt(mod_id: String) -> void:
	_clear_mod("bolt")
	var parent := Node3D.new()
	parent.name = "mod_bolt"
	add_child(parent)
	_mod_parts["bolt"] = parent

	# Bolt handle — sticks out to the right
	var handle := _make_cylinder("bolt_handle", 0.006, 0.035, Vector3(0.03, 0.01, 0.06), Vector3(0, 0, 90))
	parent.add_child(handle)

	# Bolt knob
	var knob := _make_box("bolt_knob", Vector3(0.014, 0.014, 0.014), Vector3(0.05, 0.01, 0.06))
	parent.add_child(knob)


## ── Helpers (create mesh without adding to self) ────────────────────────────

func _make_box(part_name: String, size: Vector3, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = _material
	mi.name = part_name
	return mi


func _make_cylinder(part_name: String, radius: float, height: float, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = 8
	mi.mesh = cyl
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = _material
	mi.name = part_name
	return mi


## ── Palette ─────────────────────────────────────────────────────────────────

func _apply_palette() -> void:
	if not PaletteManager:
		return
	_material.albedo_color = PaletteManager.get_color("fg_dark")


## ── Public API ──────────────────────────────────────────────────────────────

func refresh_loadout() -> void:
	## Call after equipping mods in the hub to update visuals.
	_apply_loadout()
