extends Label
## Displays player lives as heart icons (or text fallback).
## Attach to the LivesLabel node in the HUD scene.

var _heart_full_tex: Texture2D
var _heart_empty_tex: Texture2D
var _heart_icons: Array[TextureRect] = []
var _heart_container: HBoxContainer = null


func _ready() -> void:
	_heart_full_tex = UIUtils.try_load_tex("res://assets/icons/hud/heart_full.png")
	_heart_empty_tex = UIUtils.try_load_tex("res://assets/icons/hud/heart_empty.png")
	var bold_font: Font = PaletteTheme.bold_font
	if bold_font:
		add_theme_font_override("font", bold_font)
	RunManager.life_lost.connect(func(_lives: int) -> void: refresh())
	RunManager.run_started.connect(func() -> void: refresh())
	RunManager.run_failed.connect(func() -> void: refresh())
	PaletteManager.palette_changed.connect(func(_p: PaletteResource) -> void: refresh())
	refresh()


func refresh() -> void:
	if _heart_full_tex and _heart_empty_tex:
		_refresh_icons()
	else:
		_refresh_text_fallback()


func _refresh_icons() -> void:
	text = ""
	if not _heart_container:
		_heart_container = HBoxContainer.new()
		_heart_container.add_theme_constant_override("separation", 4)
		add_child(_heart_container)
	# Rebuild heart icons
	for icon in _heart_icons:
		icon.queue_free()
	_heart_icons.clear()
	var tint := PaletteManager.get_color(PaletteManager.SLOT_DANGER) if RunManager.lives <= 1 else PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY)
	for i in range(RunManager.max_lives):
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(28, 28)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		if i < RunManager.lives:
			icon.texture = _heart_full_tex
			icon.modulate = tint
		else:
			icon.texture = _heart_empty_tex
			icon.modulate = PaletteManager.get_color(PaletteManager.SLOT_BG_MID)
		_heart_container.add_child(icon)
		_heart_icons.append(icon)


func _refresh_text_fallback() -> void:
	var hearts := ""
	for i in range(RunManager.max_lives):
		if i < RunManager.lives:
			hearts += "♥ "
		else:
			hearts += "♡ "
	text = hearts.strip_edges()
	var color_slot := PaletteManager.SLOT_DANGER if RunManager.lives <= 1 else PaletteManager.SLOT_ACCENT_FRIENDLY
	add_theme_color_override("font_color", PaletteManager.get_color(color_slot))
