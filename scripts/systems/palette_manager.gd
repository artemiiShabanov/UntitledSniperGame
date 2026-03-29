extends Node
## Global palette manager — autoloaded singleton.
## Holds the active palette, pushes colors to shaders, and handles cycling.
##
## ── Quick integration guide ─────────────────────────────────────────────────
## 3D nodes (one line):
##     PaletteManager.bind_meshes(self, &"accent_hostile")
##
## UI nodes:
##     PaletteManager.get_color(&"accent_friendly")           # read once
##     PaletteManager.palette_changed.connect(_refresh_colors) # stay reactive

## Emitted whenever the palette changes (on cycle or explicit set).
signal palette_changed(palette: PaletteResource)

## All available palettes. Populated automatically from data/palettes/*.tres.
@export var palettes: Array[PaletteResource] = []

## The palette currently in use.
var current: PaletteResource:
	set(value):
		current = value
		_push_to_shaders()
		palette_changed.emit(current)

var _index: int = 0

const PREFS_PATH := "user://palette_prefs.json"

## Tracks bound nodes: { node_id: { meshes: [...], slot: StringName } }
var _bound: Dictionary = {}

## Shared materials for bulk-colored meshes (one per slot).
## Updating the shared material recolors ALL meshes using it in one go.
var _shared_materials: Dictionary = {}  ## { StringName slot: StandardMaterial3D }


func _ready() -> void:
	_load_palettes()
	if palettes.is_empty():
		push_warning("PaletteManager: no palettes found in data/palettes/.")
		return
	var saved_name := _load_pref()
	if saved_name != "":
		for i in palettes.size():
			if String(palettes[i].palette_name) == saved_name:
				_index = i
				break
	current = palettes[_index]


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cycle_palette"):
		cycle_next_unlocked()
	elif event.is_action_pressed("cycle_palette_prev"):
		cycle_prev_unlocked()


## ── Public API: Cycling ─────────────────────────────────────────────────────

func cycle_next() -> void:
	if palettes.is_empty():
		return
	_index = (_index + 1) % palettes.size()
	current = palettes[_index]
	_save_pref()
	AudioManager.play_sfx_2d(&"palette_switch")


func cycle_prev() -> void:
	if palettes.is_empty():
		return
	_index = (_index - 1 + palettes.size()) % palettes.size()
	current = palettes[_index]
	_save_pref()
	AudioManager.play_sfx_2d(&"palette_switch")


func cycle_next_unlocked() -> void:
	## Cycles to the next palette that the player has unlocked.
	var unlocked := _get_unlocked_indices()
	if unlocked.size() <= 1:
		return
	var cur_pos := unlocked.find(_index)
	if cur_pos < 0:
		cur_pos = 0
	var next_pos := (cur_pos + 1) % unlocked.size()
	_index = unlocked[next_pos]
	current = palettes[_index]
	_save_pref()
	AudioManager.play_sfx_2d(&"palette_switch")


func cycle_prev_unlocked() -> void:
	## Cycles to the previous palette that the player has unlocked.
	var unlocked := _get_unlocked_indices()
	if unlocked.size() <= 1:
		return
	var cur_pos := unlocked.find(_index)
	if cur_pos < 0:
		cur_pos = 0
	var prev_pos := (cur_pos - 1 + unlocked.size()) % unlocked.size()
	_index = unlocked[prev_pos]
	current = palettes[_index]
	_save_pref()
	AudioManager.play_sfx_2d(&"palette_switch")


func get_unlocked_palette_resources() -> Array[PaletteResource]:
	## Returns all palettes the player has unlocked.
	var result: Array[PaletteResource] = []
	var unlocked_names: Array = SaveManager.get_unlocked_palettes() if SaveManager else [] as Array
	for p in palettes:
		if String(p.palette_name).to_lower() in unlocked_names:
			result.append(p)
	return result


func is_palette_unlocked(palette_name: StringName) -> bool:
	if not SaveManager:
		return true  # No save system = all unlocked
	return SaveManager.has_palette(String(palette_name).to_lower())


func _get_unlocked_indices() -> Array[int]:
	var result: Array[int] = []
	var unlocked_names: Array = SaveManager.get_unlocked_palettes() if SaveManager else [] as Array
	for i in palettes.size():
		if String(palettes[i].palette_name).to_lower() in unlocked_names:
			result.append(i)
	if result.is_empty() and not palettes.is_empty():
		result.append(0)  # Fallback: always have at least one
	return result


func set_palette_by_name(palette_name: StringName) -> void:
	for i in palettes.size():
		if palettes[i].palette_name == palette_name:
			_index = i
			current = palettes[i]
			_save_pref()
			return
	push_warning("PaletteManager: palette '%s' not found." % palette_name)


## ── Public API: Color access ────────────────────────────────────────────────

func get_color(slot: StringName) -> Color:
	## Returns the current palette color for the given slot name.
	## Slot names match PaletteResource properties:
	##   &"bg_light", &"bg_mid", &"fg_dark",
	##   &"accent_hostile", &"accent_loot", &"accent_friendly",
	##   &"danger", &"reward"
	if current == null:
		return Color.MAGENTA
	return current.get(slot) if slot in current else Color.MAGENTA


## ── Public API: 3D mesh binding (one-liner integration) ─────────────────────

func bind_meshes(node: Node, slot: StringName) -> void:
	## Makes all MeshInstance3D descendants of `node` follow the palette slot.
	## Colors them immediately, auto-updates on palette swap, auto-cleans on exit.
	##
	## Usage:  PaletteManager.bind_meshes(self, &"accent_hostile")
	var meshes := _collect_meshes(node)
	if meshes.is_empty():
		return

	# Ensure unique materials and color them
	var prepared: Array[Dictionary] = []
	for mesh_node in meshes:
		var mat := _ensure_unique_material(mesh_node)
		if mat:
			prepared.append({"mesh": mesh_node, "material": mat})
			mat.albedo_color = get_color(slot)

	# Track for palette updates
	var node_id := node.get_instance_id()
	_bound[node_id] = {"entries": prepared, "slot": slot}

	# Auto-cleanup when the node exits the tree
	if not node.tree_exiting.is_connected(_on_bound_node_exiting):
		node.tree_exiting.connect(_on_bound_node_exiting.bind(node_id))


func unbind_meshes(node: Node) -> void:
	## Stops palette updates for this node. Called automatically on tree exit.
	_bound.erase(node.get_instance_id())


func bind_mesh_single(mesh_node: MeshInstance3D, slot: StringName) -> void:
	## Binds a single MeshInstance3D (useful when you don't want children scanned).
	var mat := _ensure_unique_material(mesh_node)
	if not mat:
		return
	mat.albedo_color = get_color(slot)
	var node_id := mesh_node.get_instance_id()
	_bound[node_id] = {"entries": [{"mesh": mesh_node, "material": mat}], "slot": slot}
	if not mesh_node.tree_exiting.is_connected(_on_bound_node_exiting):
		mesh_node.tree_exiting.connect(_on_bound_node_exiting.bind(node_id))


## ── Public API: Bulk level coloring ─────────────────────────────────────────

func color_unscripted_meshes(root: Node) -> void:
	## Colors all MeshInstance3D descendants that are NOT already bound
	## or managed by PaletteMesh. Uses bg_mid as the default world color.
	## Uses a SHARED material so palette swaps update all meshes instantly.
	## Call once in _ready — bound nodes handle their own updates.
	var shared_mat := _get_shared_material(&"bg_mid")
	for node in _find_all_recursive(root):
		if not (node is MeshInstance3D):
			continue
		if node is PaletteMesh:
			continue
		# Skip if already bound (child of an entity that called bind_meshes)
		if _is_bound_or_child_of_bound(node):
			continue
		# All unscripted meshes share one material — no per-node tracking needed
		node.material_override = shared_mat


## ── Internal: shared materials ───────────────────────────────────────────────

func _get_shared_material(slot: StringName) -> StandardMaterial3D:
	## Returns a shared material for the given slot, creating it if needed.
	## All meshes using the same shared material update in one assignment.
	if _shared_materials.has(slot):
		return _shared_materials[slot]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = get_color(slot)
	_shared_materials[slot] = mat
	return mat


## ── Internal: palette change propagation ────────────────────────────────────

func _on_palette_changed_update_bound(_palette: PaletteResource) -> void:
	## Called internally when palette changes — recolors all bound meshes
	## and all shared materials.

	# Update shared materials first (covers hundreds of unscripted meshes instantly)
	for slot: StringName in _shared_materials:
		var mat: StandardMaterial3D = _shared_materials[slot]
		mat.albedo_color = get_color(slot)

	# Update individually-bound meshes
	var stale_ids: Array[int] = []
	for node_id: int in _bound:
		var binding: Dictionary = _bound[node_id]
		var slot: StringName = binding.slot
		var color := get_color(slot)
		for entry: Dictionary in binding.entries:
			var mesh_node: MeshInstance3D = entry.mesh
			var mat: StandardMaterial3D = entry.material
			if is_instance_valid(mesh_node) and mat:
				mat.albedo_color = color
			else:
				stale_ids.append(node_id)
				break
	for stale_id in stale_ids:
		_bound.erase(stale_id)


func _on_bound_node_exiting(node_id: int) -> void:
	_bound.erase(node_id)


## ── Internal: mesh utilities ────────────────────────────────────────────────

func _collect_meshes(node: Node) -> Array[MeshInstance3D]:
	## Finds all MeshInstance3D descendants, skipping PaletteMesh nodes.
	var result: Array[MeshInstance3D] = []
	for child in _find_all_recursive(node):
		if child is PaletteMesh:
			continue
		if child is MeshInstance3D:
			result.append(child)
	return result


static func _ensure_unique_material(mesh_node: MeshInstance3D) -> StandardMaterial3D:
	## Returns a unique StandardMaterial3D for surface 0, creating if needed.
	## Uses material_override as a safe fallback for any edge case.
	if mesh_node.material_override is StandardMaterial3D:
		return mesh_node.material_override as StandardMaterial3D
	# Always use material_override — avoids surface_override_materials
	# array bounds issues when Godot hasn't initialized the array yet
	var base: Material = null
	if mesh_node.mesh and mesh_node.mesh.get_surface_count() > 0:
		base = mesh_node.mesh.surface_get_material(0)
	var mat: StandardMaterial3D
	if base is StandardMaterial3D:
		mat = base.duplicate() as StandardMaterial3D
	else:
		mat = StandardMaterial3D.new()
	mesh_node.material_override = mat
	return mat


func _is_bound_or_child_of_bound(node: Node) -> bool:
	var check := node.get_parent()
	while check:
		if _bound.has(check.get_instance_id()):
			return true
		check = check.get_parent()
	return false


static func _find_all_recursive(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		result.append(n)
		for child in n.get_children():
			stack.append(child)
	return result


## ── Internal: palette loading & persistence ─────────────────────────────────

func _load_palettes() -> void:
	var dir := DirAccess.open("res://data/palettes/")
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load("res://data/palettes/" + file_name)
			if res is PaletteResource:
				palettes.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	palettes.sort_custom(func(a: PaletteResource, b: PaletteResource) -> bool:
		return String(a.palette_name) < String(b.palette_name)
	)
	# Connect internal bound-mesh updater
	palette_changed.connect(_on_palette_changed_update_bound)


func _save_pref() -> void:
	var file := FileAccess.open(PREFS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"palette": String(current.palette_name)}))
		file.close()


func _load_pref() -> String:
	if not FileAccess.file_exists(PREFS_PATH):
		return ""
	var file := FileAccess.open(PREFS_PATH, FileAccess.READ)
	if not file:
		return ""
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return ""
	var d: Dictionary = json.data
	return d.get("palette", "")


func _push_to_shaders() -> void:
	if current == null:
		return
	RenderingServer.global_shader_parameter_set("palette_bg_light", current.bg_light)
	RenderingServer.global_shader_parameter_set("palette_bg_mid", current.bg_mid)
	RenderingServer.global_shader_parameter_set("palette_fg_dark", current.fg_dark)
	RenderingServer.global_shader_parameter_set("palette_accent_hostile", current.accent_hostile)
	RenderingServer.global_shader_parameter_set("palette_accent_loot", current.accent_loot)
	RenderingServer.global_shader_parameter_set("palette_accent_friendly", current.accent_friendly)
	RenderingServer.global_shader_parameter_set("palette_danger", current.danger)
	RenderingServer.global_shader_parameter_set("palette_reward", current.reward)
