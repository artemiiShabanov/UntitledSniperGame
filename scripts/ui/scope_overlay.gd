extends Control
## Draws a simple scope overlay — dark vignette ring with crosshairs.
## Shown when the player is scoped in, hidden otherwise.

@export var ring_color: Color = Color(0, 0, 0, 0.85)
@export var crosshair_color: Color = Color(0, 0, 0, 0.6)
@export var crosshair_thickness: float = 1.0
@export var scope_radius_ratio: float = 0.45  ## Fraction of screen height


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _draw() -> void:
	var center := size / 2.0
	var radius := size.y * scope_radius_ratio

	# Draw black rectangles around the scope circle (letterbox effect)
	# Top
	draw_rect(Rect2(0, 0, size.x, center.y - radius), ring_color)
	# Bottom
	draw_rect(Rect2(0, center.y + radius, size.x, center.y - radius + 1), ring_color)
	# Left
	draw_rect(Rect2(0, center.y - radius, center.x - radius, radius * 2), ring_color)
	# Right
	draw_rect(Rect2(center.x + radius, center.y - radius, center.x - radius + 1, radius * 2), ring_color)

	# Draw corner arcs to complete the circle mask
	# We approximate by drawing a thick ring
	var segments := 64
	for i in range(segments):
		var angle_start := TAU * i / segments
		var angle_end := TAU * (i + 1) / segments
		var p1 := center + Vector2(cos(angle_start), sin(angle_start)) * radius
		var p2 := center + Vector2(cos(angle_end), sin(angle_end)) * radius
		# Draw triangles from edge of circle to edge of screen
		var far1 := center + Vector2(cos(angle_start), sin(angle_start)) * size.length()
		var far2 := center + Vector2(cos(angle_end), sin(angle_end)) * size.length()
		draw_colored_polygon(PackedVector2Array([p1, p2, far2, far1]), ring_color)

	# Scope crosshairs (thin lines through center)
	draw_line(Vector2(center.x, center.y - radius), Vector2(center.x, center.y + radius), crosshair_color, crosshair_thickness)
	draw_line(Vector2(center.x - radius, center.y), Vector2(center.x + radius, center.y), crosshair_color, crosshair_thickness)

	# Small circle at center
	draw_arc(center, 2.0, 0, TAU, 32, crosshair_color, crosshair_thickness)
