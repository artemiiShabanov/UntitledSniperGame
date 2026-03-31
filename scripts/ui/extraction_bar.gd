extends Control
## Extraction progress bar — shows while player holds E in extraction zone.
## Hides when not extracting.

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label


func _ready() -> void:
	visible = false
	RunManager.extraction_started.connect(_on_extraction_started)
	RunManager.extraction_cancelled.connect(_on_extraction_cancelled)
	RunManager.extraction_progress_updated.connect(_on_progress_updated)
	RunManager.run_completed.connect(_on_run_completed)
	PaletteManager.palette_changed.connect(func(_p: PaletteResource) -> void: _refresh_color())


func _refresh_color() -> void:
	label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY))


func _on_extraction_started() -> void:
	visible = true
	progress_bar.value = 0.0
	label.text = "EXTRACTING..."
	_refresh_color()


func _on_extraction_cancelled() -> void:
	visible = false
	progress_bar.value = 0.0


func _on_progress_updated(progress: float) -> void:
	progress_bar.value = progress * 100.0


func _on_run_completed(_success: bool) -> void:
	visible = false
