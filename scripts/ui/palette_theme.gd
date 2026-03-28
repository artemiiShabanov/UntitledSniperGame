extends Node
## Builds and maintains a Godot Theme resource driven by the active palette.
## Autoloaded — applies the theme to the root viewport so all UI inherits it.
## Bold, punchy, tactical aesthetic — color-driven hierarchy, subtle borders.

var theme: Theme

## Font resources (loaded once)
var _font_regular: Font
var _font_bold: Font

## Default sizes — large and readable
const FONT_SIZE_DEFAULT := 28
const FONT_SIZE_SMALL := 22
const FONT_SIZE_LARGE := 36
const FONT_SIZE_TITLE := 64

## Panel styling — sharp, color-forward
const PANEL_CORNER_RADIUS := 2
const PANEL_BORDER_WIDTH := 1
const BUTTON_CORNER_RADIUS := 2
const BUTTON_BORDER_WIDTH := 1


func _enter_tree() -> void:
	## Build and apply theme as early as possible to avoid unstyled flash.
	_load_fonts()
	theme = Theme.new()
	_build_theme()
	_apply_to_viewport()
	PaletteManager.palette_changed.connect(_on_palette_changed)


func _on_palette_changed(_palette: PaletteResource) -> void:
	_build_theme()
	_apply_to_canvas_layers()


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
	_build_separator(p)
	_build_scroll_container(p)


func _build_fonts() -> void:
	## Bold font for buttons, regular for everything else
	theme.default_font = _font_regular
	theme.default_font_size = FONT_SIZE_DEFAULT

	theme.set_font("font", "Label", _font_regular)
	theme.set_font("font", "Button", _font_bold if _font_bold else _font_regular)
	theme.set_font("font", "LineEdit", _font_regular)
	theme.set_font("font", "CheckButton", _font_bold if _font_bold else _font_regular)

	theme.set_font_size("font_size", "Label", FONT_SIZE_DEFAULT)
	theme.set_font_size("font_size", "Button", FONT_SIZE_DEFAULT)
	theme.set_font_size("font_size", "LineEdit", FONT_SIZE_DEFAULT)
	theme.set_font_size("font_size", "CheckButton", FONT_SIZE_DEFAULT)


func _build_label(p: PaletteResource) -> void:
	theme.set_color("font_color", "Label", p.accent_friendly)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.5))
	theme.set_constant("shadow_offset_x", "Label", 2)
	theme.set_constant("shadow_offset_y", "Label", 3)


func _build_button(p: PaletteResource) -> void:
	## Normal: slightly lifted fill so buttons read as distinct from background
	var normal := _flat_box(Color(p.fg_dark).lightened(0.12), BUTTON_CORNER_RADIUS, Color(p.accent_friendly, 0.25), BUTTON_BORDER_WIDTH)
	## Hover: full accent fill — bold, unmistakable
	var hover := _flat_box(p.accent_friendly, BUTTON_CORNER_RADIUS, Color(p.accent_friendly, 0.6), BUTTON_BORDER_WIDTH)
	## Pressed: accent tint — dimmed, feels like it sinks in
	var pressed := _flat_box(Color(p.accent_friendly, 0.2), BUTTON_CORNER_RADIUS, Color(p.accent_friendly, 0.4), BUTTON_BORDER_WIDTH)
	## Disabled: muted
	var disabled := _flat_box(Color(p.fg_dark, 0.5), BUTTON_CORNER_RADIUS, Color(p.bg_mid, 0.1), BUTTON_BORDER_WIDTH)
	## Focus: loot-tinted fill
	var focus := _flat_box(Color(p.accent_loot, 0.08), BUTTON_CORNER_RADIUS, Color(p.accent_loot, 0.4), BUTTON_BORDER_WIDTH)

	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", disabled)
	theme.set_stylebox("focus", "Button", focus)

	theme.set_color("font_color", "Button", p.accent_friendly)
	theme.set_color("font_hover_color", "Button", p.fg_dark)
	theme.set_color("font_pressed_color", "Button", p.bg_light)
	theme.set_color("font_disabled_color", "Button", Color(p.bg_mid, 0.4))
	theme.set_color("font_focus_color", "Button", p.accent_loot)


func _build_panel(p: PaletteResource) -> void:
	## Panels: lifted fill + visible accent border for structure
	var panel_box := StyleBoxFlat.new()
	panel_box.bg_color = Color(p.fg_dark).lightened(0.06)
	panel_box.bg_color.a = 0.97
	panel_box.set_corner_radius_all(PANEL_CORNER_RADIUS)
	panel_box.border_color = Color(p.accent_friendly, 0.3)
	panel_box.set_border_width_all(2)
	panel_box.set_content_margin_all(24)
	theme.set_stylebox("panel", "PanelContainer", panel_box)
	theme.set_stylebox("panel", "Panel", panel_box)


func _build_progress_bar(p: PaletteResource) -> void:
	var bg := _flat_box(Color(p.fg_dark, 0.7), 1)
	bg.set_content_margin_all(0)
	var fill := _flat_box(p.accent_friendly, 1)
	fill.set_content_margin_all(0)
	theme.set_stylebox("background", "ProgressBar", bg)
	theme.set_stylebox("fill", "ProgressBar", fill)


func _build_check_button(p: PaletteResource) -> void:
	theme.set_color("font_color", "CheckButton", p.accent_friendly)
	theme.set_color("font_hover_color", "CheckButton", p.bg_light)
	theme.set_color("font_pressed_color", "CheckButton", p.accent_loot)
	## Hide the default checkbox background box — just show text + check icon
	var empty := StyleBoxEmpty.new()
	theme.set_stylebox("normal", "CheckButton", empty)
	theme.set_stylebox("hover", "CheckButton", empty)
	theme.set_stylebox("pressed", "CheckButton", empty)
	theme.set_stylebox("focus", "CheckButton", empty)


func _build_slider(p: PaletteResource) -> void:
	var slider_bg := _flat_box(Color(p.fg_dark, 0.7), 1)
	slider_bg.set_content_margin_all(4)
	var grabber_area := _flat_box(p.accent_friendly, 1)
	grabber_area.set_content_margin_all(4)
	var grabber_hl := _flat_box(p.bg_light, 1)
	grabber_hl.set_content_margin_all(4)
	theme.set_stylebox("slider", "HSlider", slider_bg)
	theme.set_stylebox("grabber_area", "HSlider", grabber_area)
	theme.set_stylebox("grabber_area_highlight", "HSlider", grabber_hl)


func _build_line_edit(p: PaletteResource) -> void:
	var normal := _flat_box(Color(p.fg_dark, 0.9), 1, Color(p.accent_friendly, 0.15), BUTTON_BORDER_WIDTH)
	var focus := _flat_box(Color(p.accent_friendly, 0.08), 1, Color(p.accent_friendly, 0.3), BUTTON_BORDER_WIDTH)
	theme.set_stylebox("normal", "LineEdit", normal)
	theme.set_stylebox("focus", "LineEdit", focus)
	theme.set_color("font_color", "LineEdit", p.accent_friendly)
	theme.set_color("caret_color", "LineEdit", p.accent_friendly)


func _build_separator(p: PaletteResource) -> void:
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(p.accent_friendly, 0.25)
	sep_style.set_content_margin_all(0)
	sep_style.content_margin_top = 1
	sep_style.content_margin_bottom = 1
	theme.set_stylebox("separator", "HSeparator", sep_style)
	theme.set_stylebox("separator", "VSeparator", sep_style)
	theme.set_constant("separation", "HSeparator", 16)
	theme.set_constant("separation", "VSeparator", 16)


func _build_scroll_container(p: PaletteResource) -> void:
	var grabber := _flat_box(Color(p.accent_friendly, 0.3), 1)
	grabber.set_content_margin_all(4)
	var grabber_hl := _flat_box(Color(p.accent_friendly, 0.5), 1)
	grabber_hl.set_content_margin_all(4)
	var grabber_pressed := _flat_box(Color(p.accent_friendly, 0.7), 1)
	grabber_pressed.set_content_margin_all(4)
	var scroll_bg := _flat_box(Color(p.fg_dark, 0.2), 1)
	scroll_bg.set_content_margin_all(4)
	theme.set_stylebox("scroll", "VScrollBar", scroll_bg)
	theme.set_stylebox("grabber", "VScrollBar", grabber)
	theme.set_stylebox("grabber_highlight", "VScrollBar", grabber_hl)
	theme.set_stylebox("grabber_pressed", "VScrollBar", grabber_pressed)


## ── Helpers ─────────────────────────────────────────────────────────────────

func _flat_box(bg_color: Color, corner_radius: int, border_color: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg_color
	box.set_corner_radius_all(corner_radius)
	if border_width > 0:
		box.border_color = border_color
		box.set_border_width_all(border_width)
	box.set_content_margin_all(16)
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
	_apply_to_canvas_layers()
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is Control and node.get_parent() is CanvasLayer:
		if not node.theme:
			node.theme = theme


func _apply_to_canvas_layers() -> void:
	var stack: Array[Node] = [get_tree().root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is CanvasLayer:
			for child in node.get_children():
				if child is Control and not child.theme:
					child.theme = theme
		for child in node.get_children():
			stack.append(child)
