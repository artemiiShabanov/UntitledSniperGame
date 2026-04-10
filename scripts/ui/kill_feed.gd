extends VBoxContainer
## Displays kill notifications with distance and score info.
## Each entry fades out after a few seconds.

const DISPLAY_DURATION: float = 4.0
const FADE_DURATION: float = 1.0
const KILL_FONT_SIZE: int = 28

var _entries: Array[Dictionary] = []  ## [{label: Node, timer: float}]
var _bold_font: Font
var _kill_icon: Texture2D
var _headshot_icon: Texture2D
var _target_icon: Texture2D


func _ready() -> void:
	_bold_font = PaletteTheme.bold_font
	_kill_icon = _load_icon("kill")
	_headshot_icon = _load_icon("headshot")
	_target_icon = _load_icon("target_destroyed")
	RunManager.enemy_killed_with_info.connect(_on_enemy_killed)
	RunManager.friendly_killed_with_info.connect(_on_friendly_killed)
	RunManager.target_destroyed_with_info.connect(_on_target_destroyed)
	RunManager.event_announced.connect(_on_event_announced)


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
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		row.add_child(tex)
	return row


func _on_enemy_killed(info: Dictionary) -> void:
	var icon: Texture2D = _headshot_icon if info.headshot else _kill_icon
	var row := _make_feed_row(icon)
	var label := _make_feed_label()

	var text := "%dm" % int(info.distance)
	if info.headshot:
		text += " | HEADSHOT"
	text += " | +%d" % info.final_score

	label.text = text

	if info.headshot:
		label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_HOSTILE))
	else:
		label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY))

	row.add_child(label)
	add_child(row)
	_entries.append({"label": row, "timer": DISPLAY_DURATION})


func _on_friendly_killed(info: Dictionary) -> void:
	var row := _make_feed_row(_kill_icon)
	var label := _make_feed_label()
	label.text = "FRIENDLY KILLED | -%d" % info.penalty
	label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_DANGER))
	row.add_child(label)
	add_child(row)
	_entries.append({"label": row, "timer": DISPLAY_DURATION})


func _on_target_destroyed(info: Dictionary) -> void:
	var row := _make_feed_row(_target_icon)
	var label := _make_feed_label()
	label.text = "TARGET DESTROYED | +%d" % info.score
	label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT))
	row.add_child(label)
	add_child(row)
	_entries.append({"label": row, "timer": DISPLAY_DURATION})


func _on_event_announced(text: String) -> void:
	var row := _make_feed_row()
	var label := _make_feed_label()
	label.text = text
	label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_REWARD))
	row.add_child(label)
	add_child(row)
	_entries.append({"label": row, "timer": DISPLAY_DURATION * 1.5})
