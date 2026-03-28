extends Control
## Stats panel — displays lifetime stats, best records, and per-level breakdown.
## Compact two-column layout with dotted-line fill between label and value.

signal closed

@onready var content: VBoxContainer = $VBox/ScrollContainer/Content
@onready var close_btn: Button = $VBox/CloseButton

var _level_list: Array[String] = []


func _ready() -> void:
	close_btn.pressed.connect(func(): closed.emit())
	AudioManager.wire_button(close_btn, &"menu_cancel")
	PaletteManager.palette_changed.connect(func(_p: PaletteResource) -> void: _rebuild())


func open(levels: Array[String] = []) -> void:
	_level_list = levels
	visible = true
	_rebuild()
	close_btn.grab_focus()


func _rebuild() -> void:
	for child in content.get_children():
		child.queue_free()

	_add_section("LIFETIME STATS")
	_add_row("Total Runs", str(SaveManager.get_stat("total_runs")))
	_add_row("Extractions", str(SaveManager.get_stat("total_extractions")))
	_add_row("Deaths", str(SaveManager.get_stat("total_deaths")))
	_add_row("Total Kills", str(SaveManager.get_stat("total_kills")))
	_add_row("Headshots", str(SaveManager.get_stat("total_headshots")))
	_add_row("Shots Fired", str(SaveManager.get_stat("total_shots_fired")))
	_add_row("Shots Hit", str(SaveManager.get_stat("total_shots_hit")))
	_add_row("Accuracy", "%.1f%%" % SaveManager.get_accuracy_percent())
	_add_row("Headshot Rate", "%.1f%%" % SaveManager.get_headshot_percent())

	_add_separator()
	_add_section("BEST RECORDS")
	var best_time: float = SaveManager.get_stat("best_survival_time", 0.0)
	_add_row("Best Survival Time", FormatUtils.format_time(best_time))
	_add_row("Best Credits (One Run)", "$%d" % SaveManager.get_stat("best_credits_one_run"))
	_add_row("Best Kills (One Run)", str(SaveManager.get_stat("best_kills_one_run")))
	var longest: float = SaveManager.get_stat("longest_kill_distance", 0.0)
	_add_row("Longest Kill", "%.0fm" % longest if longest > 0.0 else "—")

	# Per-level stats
	for level_path in _level_list:
		var data := load(level_path) as LevelData
		if not data:
			continue
		var ls: Dictionary = SaveManager.get_level_stats(data.scene_path)
		if ls.is_empty():
			continue

		_add_separator()
		_add_section(data.level_name.to_upper())
		_add_row("Runs", str(ls.get("runs", 0)))
		_add_row("Extractions", str(ls.get("extractions", 0)))
		_add_row("Deaths", str(ls.get("deaths", 0)))
		_add_row("Kills", str(ls.get("total_kills", 0)))
		var lt: float = ls.get("best_time", 0.0)
		_add_row("Best Time", FormatUtils.format_time(lt))
		_add_row("Best Credits", "$%d" % ls.get("best_credits", 0))


func _add_section(title: String) -> void:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", PaletteManager.get_color(&"accent_loot"))
	var bold_font: Font = load("res://assets/fonts/JetBrainsMono-Bold.ttf")
	if bold_font:
		label.add_theme_font_override("font", bold_font)
	content.add_child(label)


func _add_row(label_text: String, value_text: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)

	var name_label := Label.new()
	name_label.text = label_text
	name_label.add_theme_color_override("font_color", PaletteManager.get_color(&"bg_light"))
	hbox.add_child(name_label)

	# Dot fill — stretches between name and value
	var dots := Label.new()
	dots.text = "·" # Single dot; clip handles the rest visually
	dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dots.add_theme_color_override("font_color", Color(PaletteManager.get_color(&"bg_mid"), 0.3))
	dots.clip_text = true
	# Fill with dots
	dots.text = "· " .repeat(80)
	hbox.add_child(dots)

	var value_label := Label.new()
	value_label.text = value_text
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var bold_font: Font = load("res://assets/fonts/JetBrainsMono-Bold.ttf")
	if bold_font:
		value_label.add_theme_font_override("font", bold_font)
	hbox.add_child(value_label)

	content.add_child(hbox)


func _add_separator() -> void:
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 16)
	content.add_child(sep)
