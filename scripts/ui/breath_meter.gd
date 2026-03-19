extends Control
## Breath meter — shows remaining hold-breath time as a horizontal bar.
## Only visible when scoped.

@export var bar_width: float = 120.0
@export var bar_height: float = 6.0
@export var bar_color: Color = Color(0.7, 0.85, 1.0, 0.8)
@export var bar_bg_color: Color = Color(0.2, 0.2, 0.2, 0.5)
@export var exhausted_color: Color = Color(1.0, 0.3, 0.3, 0.8)
@export var bar_offset_y: float = 40.0  ## Pixels below center

var breath_ratio: float = 1.0
var is_exhausted: bool = false
var show_meter: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func update_breath(ratio: float, exhausted: bool, scoped: bool) -> void:
	breath_ratio = ratio
	is_exhausted = exhausted
	show_meter = scoped
	visible = show_meter
	if show_meter:
		queue_redraw()


func _draw() -> void:
	if not show_meter:
		return

	var center := size / 2.0
	var bar_pos := Vector2(center.x - bar_width / 2.0, center.y + bar_offset_y)

	# Background
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), bar_bg_color)

	# Fill
	var fill_color := exhausted_color if is_exhausted else bar_color
	var fill_width := bar_width * breath_ratio
	draw_rect(Rect2(bar_pos, Vector2(fill_width, bar_height)), fill_color)

	# Border
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(1, 1, 1, 0.3), false, 1.0)
