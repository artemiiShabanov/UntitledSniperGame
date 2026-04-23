extends Control
## Draws a horizontal castle HP bar. Always visible during a run.
## Listens to RunManager.castle_hp_changed directly.

var _hp: int = 100
var _max_hp: int = 100

const BAR_WIDTH: float = 200.0
const BAR_HEIGHT: float = 16.0
const LABEL_MARGIN: float = 4.0


func _ready() -> void:
	RunManager.castle_hp_changed.connect(_on_castle_hp_changed)
	RunManager.run_started.connect(_on_run_started)
	RunManager.run_completed.connect(func(_s: bool) -> void: visible = false)
	PaletteManager.palette_changed.connect(func(_p: PaletteResource) -> void: queue_redraw())
	visible = false


func _on_run_started() -> void:
	_hp = RunManager.castle_hp
	_max_hp = RunManager.castle_max_hp
	visible = true
	queue_redraw()


func _on_castle_hp_changed(hp: int, max_hp: int) -> void:
	_hp = hp
	_max_hp = max_hp
	queue_redraw()


func _draw() -> void:
	if _max_hp <= 0:
		return

	var ratio := clampf(float(_hp) / float(_max_hp), 0.0, 1.0)

	# Background.
	var bg_color := PaletteManager.get_color(PaletteManager.SLOT_FG_DARK)
	draw_rect(Rect2(0, 0, BAR_WIDTH, BAR_HEIGHT), bg_color)

	# Fill — good (healthy) → accent (warning) → bad (critical).
	var fill_color: Color
	if ratio > 0.5:
		fill_color = PaletteManager.get_color(PaletteManager.SLOT_GOOD)
	elif ratio > 0.25:
		fill_color = PaletteManager.get_color(PaletteManager.SLOT_ACCENT)
	else:
		fill_color = PaletteManager.get_color(PaletteManager.SLOT_BAD)

	var fill_width := BAR_WIDTH * ratio
	if fill_width > 0.0:
		draw_rect(Rect2(0, 0, fill_width, BAR_HEIGHT), fill_color)

	# Outline.
	var outline_color := PaletteManager.get_color(PaletteManager.SLOT_BG_LIGHT)
	draw_rect(Rect2(0, 0, BAR_WIDTH, BAR_HEIGHT), outline_color, false, 2.0)

	# Label.
	var font := ThemeDB.fallback_font
	var font_size := 14
	var label_text := "CASTLE %d/%d" % [_hp, _max_hp]
	var text_pos := Vector2(0, BAR_HEIGHT + font_size + LABEL_MARGIN)
	draw_string(font, text_pos, label_text, HORIZONTAL_ALIGNMENT_LEFT, BAR_WIDTH, font_size, outline_color)
