class_name RifleViewmodel
extends Node3D
## First-person rifle viewmodel built from CSG primitives.
## Swappable mod attachments update geometry based on equipped loadout.
## Colors itself via PaletteManager (accent_hostile).

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
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_material.metallic = 0.6
	_material.roughness = 0.35
	_material.metallic_specular = 0.5
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

	match mod_id:
		"barrel_extended":
			# Long barrel with muzzle brake
			var barrel := _make_cylinder("barrel_tube", 0.012, 0.35, Vector3(0, 0, -0.09 - 0.175), Vector3(90, 0, 0))
			parent.add_child(barrel)
			var brake := _make_box("muzzle_brake", Vector3(0.022, 0.022, 0.025), Vector3(0, 0, -0.09 - 0.35 + 0.012))
			parent.add_child(brake)

		"barrel_improvised_suppressor":
			# Standard-length barrel with a crude bottle silencer on the end
			var barrel := _make_cylinder("barrel_tube", 0.014, 0.22, Vector3(0, 0, -0.09 - 0.11), Vector3(90, 0, 0))
			parent.add_child(barrel)
			# Bottle body — wider cylinder, slightly off-center for janky look
			var bottle := _make_cylinder("bottle_body", 0.025, 0.08, Vector3(0.002, 0.001, -0.09 - 0.22 - 0.03), Vector3(90, 0, 0))
			parent.add_child(bottle)
			# Bottle neck — narrower, wraps around barrel end
			var neck := _make_cylinder("bottle_neck", 0.016, 0.025, Vector3(0.002, 0.001, -0.09 - 0.20), Vector3(90, 0, 0))
			parent.add_child(neck)

		"barrel_tactical":
			# Barrel with integrated suppressor shroud
			var barrel := _make_cylinder("barrel_tube", 0.012, 0.28, Vector3(0, 0, -0.09 - 0.14), Vector3(90, 0, 0))
			parent.add_child(barrel)
			# Suppressor shroud — clean cylinder over the front half
			var shroud := _make_cylinder("suppressor_shroud", 0.02, 0.14, Vector3(0, 0, -0.09 - 0.28 + 0.04), Vector3(90, 0, 0))
			parent.add_child(shroud)
			# Suppressor cap
			var cap := _make_cylinder("suppressor_cap", 0.022, 0.008, Vector3(0, 0, -0.09 - 0.28 - 0.03 + 0.004), Vector3(90, 0, 0))
			parent.add_child(cap)

		_:
			# Standard barrel
			var barrel := _make_cylinder("barrel_tube", 0.014, 0.22, Vector3(0, 0, -0.09 - 0.11), Vector3(90, 0, 0))
			parent.add_child(barrel)


func _build_stock(mod_id: String) -> void:
	_clear_mod("stock")
	var parent := Node3D.new()
	parent.name = "mod_stock"
	add_child(parent)
	_mod_parts["stock"] = parent

	match mod_id:
		"stock_light":
			# Slim, skeletal stock — thin body, no cheek rest
			var stock := _make_box("stock_body", Vector3(0.025, 0.035, 0.14), Vector3(0, -0.005, 0.16))
			parent.add_child(stock)
			var butt := _make_box("stock_butt", Vector3(0.028, 0.045, 0.008), Vector3(0, -0.005, 0.235))
			parent.add_child(butt)

		"stock_padded":
			# Standard shape with thicker rubber buttpad
			var stock := _make_box("stock_body", Vector3(0.03, 0.045, 0.16), Vector3(0, -0.005, 0.17))
			parent.add_child(stock)
			var butt := _make_box("stock_butt", Vector3(0.038, 0.065, 0.018), Vector3(0, -0.005, 0.258))
			parent.add_child(butt)
			var cheek := _make_box("stock_cheek", Vector3(0.034, 0.018, 0.08), Vector3(0, 0.025, 0.17))
			parent.add_child(cheek)

		"stock_heavy":
			# Wide, solid stock — chunky body, tall cheek rest, wide buttpad
			var stock := _make_box("stock_body", Vector3(0.038, 0.05, 0.18), Vector3(0, -0.005, 0.18))
			parent.add_child(stock)
			var butt := _make_box("stock_butt", Vector3(0.042, 0.07, 0.016), Vector3(0, -0.005, 0.275))
			parent.add_child(butt)
			var cheek := _make_box("stock_cheek", Vector3(0.04, 0.02, 0.1), Vector3(0, 0.028, 0.18))
			parent.add_child(cheek)

		"stock_competition":
			# Adjustable stock — body with visible adjustment rail + elevated cheek
			var stock := _make_box("stock_body", Vector3(0.03, 0.045, 0.16), Vector3(0, -0.005, 0.17))
			parent.add_child(stock)
			var butt := _make_box("stock_butt", Vector3(0.035, 0.06, 0.012), Vector3(0, -0.005, 0.255))
			parent.add_child(butt)
			# Adjustment rail — thin strip along the bottom
			var rail := _make_box("adjust_rail", Vector3(0.015, 0.006, 0.12), Vector3(0, -0.03, 0.18))
			parent.add_child(rail)
			# Elevated cheek riser
			var cheek := _make_box("stock_cheek", Vector3(0.032, 0.02, 0.07), Vector3(0, 0.032, 0.17))
			parent.add_child(cheek)

		_:
			# Standard stock
			var stock := _make_box("stock_body", Vector3(0.03, 0.045, 0.16), Vector3(0, -0.005, 0.17))
			parent.add_child(stock)
			var butt := _make_box("stock_butt", Vector3(0.035, 0.06, 0.012), Vector3(0, -0.005, 0.255))
			parent.add_child(butt)
			var cheek := _make_box("stock_cheek", Vector3(0.032, 0.015, 0.08), Vector3(0, 0.025, 0.17))
			parent.add_child(cheek)


func _build_magazine(mod_id: String) -> void:
	_clear_mod("magazine")
	var parent := Node3D.new()
	parent.name = "mod_magazine"
	add_child(parent)
	_mod_parts["magazine"] = parent

	var height: float
	var width: float

	match mod_id:
		"magazine_fast":
			# Compact, slim magazine
			height = 0.032
			width = 0.023
		"magazine_extended":
			# Tall, wide magazine
			height = 0.07
			width = 0.028
		_:
			# Standard
			height = 0.04
			width = 0.025

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

	match mod_id:
		"scope_red_dot":
			# Small reflex sight — low-profile box on rail
			var housing := _make_box("rd_housing", Vector3(0.022, 0.02, 0.03), Vector3(0, 0.04, 0.0))
			parent.add_child(housing)
			# Lens window (front)
			var lens := _make_box("rd_lens", Vector3(0.018, 0.016, 0.003), Vector3(0, 0.04, -0.017))
			parent.add_child(lens)

		"scope_grandma":
			# Oversized old scope — long, wide tube with big objective
			var tube := _make_cylinder("scope_tube", 0.02, 0.2, Vector3(0, 0.05, -0.01), Vector3(90, 0, 0))
			parent.add_child(tube)
			var obj := _make_cylinder("scope_obj", 0.028, 0.025, Vector3(0, 0.05, -0.1), Vector3(90, 0, 0))
			parent.add_child(obj)
			var eye := _make_cylinder("scope_eye", 0.024, 0.02, Vector3(0, 0.05, 0.08), Vector3(90, 0, 0))
			parent.add_child(eye)
			for z_off in [-0.04, 0.04]:
				var ring := _make_cylinder("scope_ring", 0.024, 0.014, Vector3(0, 0.038, z_off), Vector3.ZERO)
				parent.add_child(ring)

		"scope_cheap":
			# Medium scope — slightly shorter tube, basic mount
			var tube := _make_cylinder("scope_tube", 0.015, 0.14, Vector3(0, 0.045, -0.01), Vector3(90, 0, 0))
			parent.add_child(tube)
			var obj := _make_cylinder("scope_obj", 0.02, 0.016, Vector3(0, 0.045, -0.07), Vector3(90, 0, 0))
			parent.add_child(obj)
			var eye := _make_cylinder("scope_eye", 0.018, 0.016, Vector3(0, 0.045, 0.055), Vector3(90, 0, 0))
			parent.add_child(eye)
			# Single rail mount block
			var mount := _make_box("scope_mount", Vector3(0.02, 0.012, 0.06), Vector3(0, 0.033, 0.0))
			parent.add_child(mount)

		"scope_tactical":
			# Tactical variable scope — clean tube with adjustment turrets
			var tube := _make_cylinder("scope_tube", 0.018, 0.18, Vector3(0, 0.048, -0.01), Vector3(90, 0, 0))
			parent.add_child(tube)
			var obj := _make_cylinder("scope_obj", 0.024, 0.02, Vector3(0, 0.048, -0.09), Vector3(90, 0, 0))
			parent.add_child(obj)
			var eye := _make_cylinder("scope_eye", 0.022, 0.018, Vector3(0, 0.048, 0.07), Vector3(90, 0, 0))
			parent.add_child(eye)
			# Adjustment turrets (top and side knobs)
			var turret_top := _make_cylinder("turret_top", 0.008, 0.012, Vector3(0, 0.065, 0.0), Vector3.ZERO)
			parent.add_child(turret_top)
			var turret_side := _make_cylinder("turret_side", 0.008, 0.012, Vector3(0.025, 0.048, 0.0), Vector3(0, 0, 90))
			parent.add_child(turret_side)
			for z_off in [-0.04, 0.04]:
				var ring := _make_cylinder("scope_ring", 0.022, 0.012, Vector3(0, 0.037, z_off), Vector3.ZERO)
				parent.add_child(ring)

		_:
			# Iron sights (standard)
			var front := _make_box("front_sight", Vector3(0.004, 0.018, 0.004), Vector3(0, 0.04, -0.07))
			parent.add_child(front)
			var guard := _make_cylinder("front_guard", 0.012, 0.005, Vector3(0, 0.035, -0.07), Vector3.ZERO)
			parent.add_child(guard)
			var rear := _make_box("rear_sight", Vector3(0.018, 0.015, 0.006), Vector3(0, 0.035, 0.04))
			parent.add_child(rear)


func _build_bolt(mod_id: String) -> void:
	_clear_mod("bolt")
	var parent := Node3D.new()
	parent.name = "mod_bolt"
	add_child(parent)
	_mod_parts["bolt"] = parent

	match mod_id:
		"bolt_quick":
			# Larger tactical knob for fast manipulation
			var handle := _make_cylinder("bolt_handle", 0.006, 0.035, Vector3(0.03, 0.01, 0.06), Vector3(0, 0, 90))
			parent.add_child(handle)
			var knob := _make_box("bolt_knob", Vector3(0.018, 0.018, 0.018), Vector3(0.05, 0.01, 0.06))
			parent.add_child(knob)

		"bolt_smooth":
			# Extended handle with rounded knob — smooth action feel
			var handle := _make_cylinder("bolt_handle", 0.007, 0.04, Vector3(0.032, 0.01, 0.06), Vector3(0, 0, 90))
			parent.add_child(handle)
			var knob := _make_cylinder("bolt_knob", 0.01, 0.012, Vector3(0.055, 0.01, 0.06), Vector3(0, 0, 90))
			parent.add_child(knob)

		"bolt_prototype":
			# Bulky mechanism — wider handle, extra housing block
			var handle := _make_cylinder("bolt_handle", 0.008, 0.03, Vector3(0.028, 0.01, 0.06), Vector3(0, 0, 90))
			parent.add_child(handle)
			var knob := _make_box("bolt_knob", Vector3(0.02, 0.02, 0.02), Vector3(0.046, 0.01, 0.06))
			parent.add_child(knob)
			# Extra housing
			var housing := _make_box("bolt_housing", Vector3(0.025, 0.018, 0.04), Vector3(0.012, 0.01, 0.06))
			parent.add_child(housing)

		"bolt_light":
			# Slim, elegant handle — lightweight precision
			var handle := _make_cylinder("bolt_handle", 0.005, 0.038, Vector3(0.031, 0.01, 0.06), Vector3(0, 0, 90))
			parent.add_child(handle)
			var knob := _make_cylinder("bolt_knob", 0.008, 0.01, Vector3(0.053, 0.01, 0.06), Vector3(0, 0, 90))
			parent.add_child(knob)

		_:
			# Standard bolt
			var handle := _make_cylinder("bolt_handle", 0.006, 0.035, Vector3(0.03, 0.01, 0.06), Vector3(0, 0, 90))
			parent.add_child(handle)
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
	_material.albedo_color = PaletteManager.get_color(PaletteManager.SLOT_ACCENT_HOSTILE)


## ── Public API ──────────────────────────────────────────────────────────────

func refresh_loadout() -> void:
	## Call after equipping mods in the hub to update visuals.
	_apply_loadout()
