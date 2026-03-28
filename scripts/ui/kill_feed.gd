extends VBoxContainer
## Displays kill notifications with distance and bonus info.
## Each entry fades out after a few seconds.

const DISPLAY_DURATION: float = 4.0
const FADE_DURATION: float = 1.0
const KILL_FONT_SIZE: int = 28

var _entries: Array[Dictionary] = []  ## [{label: Label, timer: float}]
var _bold_font: Font
var _kill_icon: Texture2D
var _headshot_icon: Texture2D
var _long_range_icon: Texture2D
var _penetration_icon: Texture2D
var _target_icon: Texture2D


func _ready() -> void:
	_bold_font = load("res://assets/fonts/JetBrainsMono-Bold.ttf")
	_kill_icon = _load_icon("kill")
	_headshot_icon = _load_icon("headshot")
	_long_range_icon = _load_icon("long_range")
	_penetration_icon = _load_icon("penetration")
	_target_icon = _load_icon("target_destroyed")
	RunManager.enemy_killed_with_info.connect(_on_enemy_killed)
	RunManager.npc_killed_with_info.connect(_on_npc_killed)
	RunManager.target_destroyed_with_info.connect(_on_target_destroyed)


func _process(delta: float) -> void:
	var i := _entries.size() - 1
	while i >= 0:
		var entry: Dictionary = _entries[i]
		entry.timer -= delta
		var label: Node = entry.label

		if entry.timer <= 0.0:
			label.queue_free()
			_entries.remove_at(i)
		elif entry.timer < FADE_DURATION:
			label.modulate.a = entry.timer / FADE_DURATION
		i -= 1


func _make_feed_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", KILL_FONT_SIZE)
	if _bold_font:
		label.add_theme_font_override("font", _bold_font)
	return label


func _load_icon(icon_name: String) -> Texture2D:
	var path := "res://assets/icons/killfeed/%s.png" % icon_name
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _make_feed_row(icon: Texture2D = null) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_END
	if icon:
		var tex := TextureRect.new()
		tex.texture = icon
		tex.custom_minimum_size = Vector2(24, 24)
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(tex)
	return row


func _on_enemy_killed(info: Dictionary) -> void:
	# Choose icon based on kill type
	var icon: Texture2D = _kill_icon
	if info.headshot:
		icon = _headshot_icon
	elif info.distance_multiplier > 1.0:
		icon = _long_range_icon

	var row := _make_feed_row(icon)
	var label := _make_feed_label()

	# Build the kill text
	var text := ""
	var dist_m := int(info.distance)

	# Distance
	text += "%dm" % dist_m

	# Multiplier info
	var parts: PackedStringArray = []
	if info.headshot:
		parts.append("HEADSHOT")
	if info.distance_multiplier > 1.0:
		parts.append("x%.1f RANGE" % info.distance_multiplier)
	if parts.size() > 0:
		text += " | " + " | ".join(parts)

	# Credits earned
	text += " | +$%d" % info.final_credits

	label.text = text

	# Color based on multiplier
	if info.total_multiplier >= 3.0:
		label.add_theme_color_override("font_color", PaletteManager.get_color(&"reward"))
	elif info.total_multiplier >= 2.0:
		label.add_theme_color_override("font_color", PaletteManager.get_color(&"accent_loot"))
	elif info.headshot:
		label.add_theme_color_override("font_color", PaletteManager.get_color(&"accent_hostile"))
	else:
		label.add_theme_color_override("font_color", PaletteManager.get_color(&"accent_friendly"))

	row.add_child(label)
	add_child(row)
	_entries.append({"label": row, "timer": DISPLAY_DURATION})


func _on_npc_killed(info: Dictionary) -> void:
	var row := _make_feed_row(_kill_icon)
	var label := _make_feed_label()
	label.text = "CIVILIAN KILLED | -$%d" % info.penalty
	label.add_theme_color_override("font_color", PaletteManager.get_color(&"danger"))
	row.add_child(label)
	add_child(row)
	_entries.append({"label": row, "timer": DISPLAY_DURATION})


func _on_target_destroyed(info: Dictionary) -> void:
	var row := _make_feed_row(_target_icon)
	var label := _make_feed_label()
	label.text = "TARGET DESTROYED | +$%d" % info.credits
	label.add_theme_color_override("font_color", PaletteManager.get_color(&"accent_loot"))
	row.add_child(label)
	add_child(row)
	_entries.append({"label": row, "timer": DISPLAY_DURATION})
