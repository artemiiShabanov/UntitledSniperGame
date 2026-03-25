extends Node
## Builds and maintains a Godot Theme resource driven by the active palette.
## Autoloaded — applies the theme to the root viewport so all UI inherits it.
## Only nodes with explicit overrides (e.g. conditional HUD colors) need manual work.

var theme: Theme

## Font resources (loaded once)
var _font_regular: Font
var _font_bold: Font

## Default sizes
const FONT_SIZE_DEFAULT := 16
const FONT_SIZE_SMALL := 13
const FONT_SIZE_LARGE := 22
const FONT_SIZE_TITLE := 36

## Panel styling
const PANEL_CORNER_RADIUS := 4
const PANEL_BORDER_WIDTH := 1
const BUTTON_CORNER_RADIUS := 3


func _ready() -> void:
	_load_fonts()
	theme = Theme.new()
	_build_theme()
	_apply_to_viewport()
	PaletteManager.palette_changed.connect(_on_palette_changed)


func _on_palette_changed(_palette: PaletteResource) -> void:
	_build_theme()


## ── Theme construction ──────────────────────────────────────────────────────

func _build_theme() -> void:
	var p := PaletteManager.current
	if not p:
		return

	_build_fonts()
	_build_label(p)
	_build_button(p)
	_build_panel(p)
	_build_progress_bar(p)
	_build_check_button(p)
	_build_slider(p)
	_build_line_edit(p)


func _build_fonts() -> void:
	## Set default font and sizes for all control types
	theme.default_font = _font_regular
	theme.default_font_size = FONT_SIZE_DEFAULT

	theme.set_font("font", "Label", _font_regular)
	theme.set_font("font", "Button", _font_regular)
	theme.set_font("font", "LineEdit", _font_regular)
	theme.set_font("font", "CheckButton", _font_regular)

	theme.set_font_size("font_size", "Label", FONT_SIZE_DEFAULT)
	theme.set_font_size("font_size", "Button", FONT_SIZE_DEFAULT)
	theme.set_font_size("font_size", "LineEdit", FONT_SIZE_DEFAULT)
	theme.set_font_size("font_size", "CheckButton", FONT_SIZE_DEFAULT)


func _build_label(p: PaletteResource) -> void:
	theme.set_color("font_color", "Label", p.accent_friendly)
	theme.set_color("font_shadow_color", "Label", Color(p.fg_dark, 0.3))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)


func _build_button(p: PaletteResource) -> void:
	var normal := _flat_box(p.fg_dark, BUTTON_CORNER_RADIUS, p.accent_friendly, PANEL_BORDER_WIDTH)
	var hover := _flat_box(Color(p.fg_dark, 0.9), BUTTON_CORNER_RADIUS, p.accent_friendly, PANEL_BORDER_WIDTH)
	var pressed := _flat_box(p.accent_friendly, BUTTON_CORNER_RADIUS, p.accent_friendly, 0)
	var disabled := _flat_box(Color(p.fg_dark, 0.4), BUTTON_CORNER_RADIUS, Color(p.bg_mid, 0.3), PANEL_BORDER_WIDTH)
	var focus := _flat_box(p.fg_dark, BUTTON_CORNER_RADIUS, p.accent_loot, 2)

	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", disabled)
	theme.set_stylebox("focus", "Button", focus)

	theme.set_color("font_color", "Button", p.accent_friendly)
	theme.set_color("font_hover_color", "Button", p.bg_light)
	theme.set_color("font_pressed_color", "Button", p.fg_dark)
	theme.set_color("font_disabled_color", "Button", Color(p.bg_mid, 0.5))
	theme.set_color("font_focus_color", "Button", p.accent_loot)


func _build_panel(p: PaletteResource) -> void:
	var panel_box := _flat_box(Color(p.fg_dark, 0.92), PANEL_CORNER_RADIUS, Color(p.accent_friendly, 0.3), PANEL_BORDER_WIDTH)
	theme.set_stylebox("panel", "PanelContainer", panel_box)
	theme.set_stylebox("panel", "Panel", panel_box)


func _build_progress_bar(p: PaletteResource) -> void:
	var bg := _flat_box(Color(p.fg_dark, 0.6), 2)
	var fill := _flat_box(p.accent_friendly, 2)
	theme.set_stylebox("background", "ProgressBar", bg)
	theme.set_stylebox("fill", "ProgressBar", fill)


func _build_check_button(p: PaletteResource) -> void:
	theme.set_color("font_color", "CheckButton", p.accent_friendly)
	theme.set_color("font_hover_color", "CheckButton", p.bg_light)
	theme.set_color("font_pressed_color", "CheckButton", p.accent_loot)


func _build_slider(p: PaletteResource) -> void:
	var slider_bg := _flat_box(Color(p.fg_dark, 0.6), 2)
	var grabber_area := _flat_box(p.accent_friendly, 2)
	theme.set_stylebox("slider", "HSlider", slider_bg)
	theme.set_stylebox("grabber_area", "HSlider", grabber_area)
	theme.set_stylebox("grabber_area_highlight", "HSlider", _flat_box(p.bg_light, 2))


func _build_line_edit(p: PaletteResource) -> void:
	var normal := _flat_box(Color(p.fg_dark, 0.8), 2, Color(p.accent_friendly, 0.4), 1)
	var focus := _flat_box(Color(p.fg_dark, 0.9), 2, p.accent_friendly, 1)
	theme.set_stylebox("normal", "LineEdit", normal)
	theme.set_stylebox("focus", "LineEdit", focus)
	theme.set_color("font_color", "LineEdit", p.accent_friendly)
	theme.set_color("caret_color", "LineEdit", p.accent_friendly)


## ── Helpers ─────────────────────────────────────────────────────────────────

func _flat_box(bg_color: Color, corner_radius: int, border_color: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg_color
	box.set_corner_radius_all(corner_radius)
	if border_width > 0:
		box.border_color = border_color
		box.set_border_width_all(border_width)
	box.set_content_margin_all(8)
	return box


func _load_fonts() -> void:
	_font_regular = load("res://assets/fonts/JetBrainsMono-Regular.ttf")
	_font_bold = load("res://assets/fonts/JetBrainsMono-Bold.ttf")
	if not _font_regular:
		push_warning("PaletteTheme: could not load regular font")
	if not _font_bold:
		push_warning("PaletteTheme: could not load bold font")


func _apply_to_viewport() -> void:
	var root := get_tree().root
	if root:
		root.theme = theme
