extends Label
## Shows "EXTRACTION OPEN" with countdown when an extraction window is active.
## Listens to RunManager extraction window signals directly.

var _time_remaining: float = 0.0
var _window_open: bool = false


func _ready() -> void:
	RunManager.extraction_window_opened.connect(_on_window_opened)
	RunManager.extraction_window_closed.connect(_on_window_closed)
	RunManager.run_completed.connect(func(_s: bool) -> void: _hide())
	visible = false


func _process(_delta: float) -> void:
	if not _window_open:
		return
	_time_remaining = RunManager.extraction_window_timer
	if _time_remaining > 0.0:
		text = "EXTRACTION OPEN — %.0fs" % _time_remaining
	else:
		_hide()


func _on_window_opened(duration: float) -> void:
	_window_open = true
	_time_remaining = duration
	text = "EXTRACTION OPEN — %.0fs" % duration
	var accent := PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT)
	add_theme_color_override("font_color", accent)
	visible = true


func _on_window_closed() -> void:
	_hide()


func _hide() -> void:
	_window_open = false
	visible = false
