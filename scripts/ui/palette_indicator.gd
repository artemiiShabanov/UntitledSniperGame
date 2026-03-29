extends HBoxContainer
## Small HUD widget showing the current palette's accent colors.
## Visible in both hub and in-run. Auto-updates on palette swap.

const SWATCH_SIZE := Vector2(12, 12)
const SLOTS: Array[StringName] = [
	&"accent_hostile", &"accent_loot", &"accent_friendly",
	&"danger", &"reward",
]

var _swatches: Array[ColorRect] = []
var _name_label: Label


func _ready() -> void:
	add_theme_constant_override("separation", 3)

	# Palette name label
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 16)
	_name_label.add_theme_color_override("font_color", PaletteManager.get_color(&"bg_light"))
	add_child(_name_label)

	# Color swatches
	for slot in SLOTS:
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = SWATCH_SIZE
		swatch.color = PaletteManager.get_color(slot)
		add_child(swatch)
		_swatches.append(swatch)

	_update_display()
	PaletteManager.palette_changed.connect(_on_palette_changed)


func _on_palette_changed(_palette: PaletteResource) -> void:
	_update_display()


func _update_display() -> void:
	if PaletteManager.current:
		_name_label.text = String(PaletteManager.current.palette_name)
		_name_label.add_theme_color_override("font_color", PaletteManager.get_color(&"bg_light"))
	for i in range(mini(_swatches.size(), SLOTS.size())):
		_swatches[i].color = PaletteManager.get_color(SLOTS[i])
