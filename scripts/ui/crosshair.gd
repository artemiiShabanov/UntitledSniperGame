extends Control
## Draws a centered crosshair on screen.
## Attach to a Control node that fills the viewport (anchors full-rect).

@export var color: Color = Color.WHITE
@export var length: float = 6.0   ## Half-length of each arm
@export var thickness: float = 2.0
@export var gap: float = 3.0      ## Empty space around center
@export var outline_color: Color = Color(0, 0, 0, 0.6)
@export var outline_width: float = 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchors_preset = Control.PRESET_FULL_RECT


func _draw() -> void:
	var center := size / 2.0

	# Four arms: up, down, left, right
	var arms: Array[Vector2] = [
		Vector2(0, -1),  # up
		Vector2(0, 1),   # down
		Vector2(-1, 0),  # left
		Vector2(1, 0),   # right
	]

	for dir in arms:
		var start := center + dir * gap
		var end := center + dir * (gap + length)

		# Outline
		if outline_width > 0.0:
			draw_line(start, end, outline_color, thickness + outline_width * 2.0, true)

		# Main line
		draw_line(start, end, color, thickness, true)

	# Center dot (optional, tiny)
	draw_circle(center, 1.0, color)
