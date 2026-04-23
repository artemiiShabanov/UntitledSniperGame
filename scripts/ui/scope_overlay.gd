extends Control
## Draws scope overlay with different styles based on equipped scope.
## Shown when the player is scoped in, hidden otherwise.

enum Style { DEFAULT, RED_DOT, GRANDMA, CHEAP, TACTICAL }

@export var crosshair_thickness: float = 1.0
@export var scope_radius_ratio: float = 0.45  ## Fraction of screen height

var ring_color: Color
var crosshair_color: Color
var dot_color: Color
var style: Style = Style.DEFAULT


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	PaletteManager.palette_changed.connect(_on_palette_changed)
	_on_palette_changed(PaletteManager.current)


func set_style(new_style: int) -> void:
	style = new_style as Style
	if visible:
		queue_redraw()


func _on_palette_changed(_palette: PaletteResource) -> void:
	ring_color = Color(PaletteManager.GS_DARK, 0.9)
	crosshair_color = Color(PaletteManager.get_color(PaletteManager.SLOT_GOOD_MUTED), 0.5)
	dot_color = Color(PaletteManager.get_color(PaletteManager.SLOT_BAD), 0.9)
	if visible:
		queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var radius := size.y * scope_radius_ratio

	match style:
		Style.RED_DOT:
			_draw_red_dot(center, radius)
		Style.GRANDMA:
			_draw_grandma(center, radius)
		Style.CHEAP:
			_draw_cheap(center, radius)
		Style.TACTICAL:
			_draw_tactical(center, radius)
		_:
			_draw_default(center, radius)


## ── Shared helpers ──────────────────────────────────────────────────────────

func _draw_scope_mask(center: Vector2, radius: float) -> void:
	## Dark vignette ring around the scope circle.
	# Letterbox rectangles
	draw_rect(Rect2(0, 0, size.x, center.y - radius), ring_color)
	draw_rect(Rect2(0, center.y + radius, size.x, center.y - radius + 1), ring_color)
	draw_rect(Rect2(0, center.y - radius, center.x - radius, radius * 2), ring_color)
	draw_rect(Rect2(center.x + radius, center.y - radius, center.x - radius + 1, radius * 2), ring_color)

	# Corner arcs
	var segments := 64
	for i in range(segments):
		var angle_start := TAU * i / segments
		var angle_end := TAU * (i + 1) / segments
		var p1 := center + Vector2(cos(angle_start), sin(angle_start)) * radius
		var p2 := center + Vector2(cos(angle_end), sin(angle_end)) * radius
		var far1 := center + Vector2(cos(angle_start), sin(angle_start)) * size.length()
		var far2 := center + Vector2(cos(angle_end), sin(angle_end)) * size.length()
		draw_colored_polygon(PackedVector2Array([p1, p2, far2, far1]), ring_color)


func _draw_blur_ring(center: Vector2, radius: float, width: float, alpha: float) -> void:
	## Soft gradient ring inside the scope edge — fakes a blur effect.
	var steps := 8
	for i in range(steps):
		var t := float(i) / float(steps)
		var r := radius - width * (1.0 - t)
		var a := alpha * (1.0 - t)
		draw_arc(center, r, 0, TAU, 64, Color(ring_color, a), width / steps + 1.0)


## ── Scope styles ────────────────────────────────────────────────────────────

func _draw_default(center: Vector2, radius: float) -> void:
	## Standard crosshairs — thin lines through center with small center circle.
	_draw_scope_mask(center, radius)
	draw_line(Vector2(center.x, center.y - radius), Vector2(center.x, center.y + radius), crosshair_color, crosshair_thickness)
	draw_line(Vector2(center.x - radius, center.y), Vector2(center.x + radius, center.y), crosshair_color, crosshair_thickness)
	draw_arc(center, 2.0, 0, TAU, 32, crosshair_color, crosshair_thickness)


func _draw_red_dot(center: Vector2, _radius: float) -> void:
	## Minimal overlay — just a dot in the center, no scope mask.
	draw_circle(center, 3.0, dot_color)
	# Subtle outer ring
	draw_arc(center, 6.0, 0, TAU, 32, Color(dot_color, 0.3), 1.0)


func _draw_grandma(center: Vector2, radius: float) -> void:
	## Heavy vignette with thick blur ring — old, foggy optic.
	_draw_scope_mask(center, radius)
	_draw_blur_ring(center, radius, radius * 0.35, 0.6)
	# Thick, slightly faded crosshairs
	var faded := Color(crosshair_color, 0.3)
	draw_line(Vector2(center.x, center.y - radius * 0.6), Vector2(center.x, center.y + radius * 0.6), faded, 2.0)
	draw_line(Vector2(center.x - radius * 0.6, center.y), Vector2(center.x + radius * 0.6, center.y), faded, 2.0)


func _draw_cheap(center: Vector2, radius: float) -> void:
	## Off-center cross with uneven line weights — janky but functional.
	_draw_scope_mask(center, radius)
	var offset := Vector2(1.5, -1.0)  # Slightly off-center
	var c := center + offset
	# Vertical — thicker
	draw_line(Vector2(c.x, center.y - radius), Vector2(c.x, center.y + radius), crosshair_color, 1.5)
	# Horizontal — thinner
	draw_line(Vector2(center.x - radius, c.y), Vector2(center.x + radius, c.y), crosshair_color, 0.8)
	# Center dot — slightly large
	draw_circle(c, 2.5, Color(crosshair_color, 0.7))
	# Extra stadia lines (uneven spacing for cheap feel)
	for tick_y in [-0.15, -0.3, 0.16, 0.32]:
		var ty: float = center.y + radius * tick_y + offset.y
		draw_line(Vector2(c.x - 8, ty), Vector2(c.x + 8, ty), Color(crosshair_color, 0.4), 0.8)


func _draw_tactical(center: Vector2, radius: float) -> void:
	## Clean mil-dot cross with subtle edge blur.
	_draw_scope_mask(center, radius)
	_draw_blur_ring(center, radius, radius * 0.15, 0.4)
	# Clean crosshair lines with gap at center
	var gap := 12.0
	draw_line(Vector2(center.x, center.y - radius), Vector2(center.x, center.y - gap), crosshair_color, crosshair_thickness)
	draw_line(Vector2(center.x, center.y + gap), Vector2(center.x, center.y + radius), crosshair_color, crosshair_thickness)
	draw_line(Vector2(center.x - radius, center.y), Vector2(center.x - gap, center.y), crosshair_color, crosshair_thickness)
	draw_line(Vector2(center.x + gap, center.y), Vector2(center.x + radius, center.y), crosshair_color, crosshair_thickness)
	# Mil-dots along crosshairs
	var dot_spacing := radius * 0.12
	for i in range(1, 5):
		var d := dot_spacing * i + gap
		draw_circle(Vector2(center.x, center.y - d), 1.5, crosshair_color)
		draw_circle(Vector2(center.x, center.y + d), 1.5, crosshair_color)
		draw_circle(Vector2(center.x - d, center.y), 1.5, crosshair_color)
		draw_circle(Vector2(center.x + d, center.y), 1.5, crosshair_color)
	# Tiny center dot
	draw_circle(center, 1.0, crosshair_color)
