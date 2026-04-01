extends CanvasLayer
## Full-screen loading overlay. Shown during scene transitions.
## Autoloaded — persists across scene changes.

@onready var panel: ColorRect = $Panel
@onready var label: Label = $Panel/Label

var _tween: Tween


func _ready() -> void:
	layer = 100  # Above everything
	panel.visible = false
	panel.modulate.a = 0.0


## Show the loading screen with a fade-in, call the callback, then fade out.
func transition(callable: Callable) -> void:
	show_loading()
	await get_tree().create_timer(0.3).timeout  # Let fade-in finish
	callable.call()
	await get_tree().tree_changed
	# Give the new scene a frame to initialize
	await get_tree().process_frame
	await get_tree().process_frame
	hide_loading()


func show_loading() -> void:
	panel.visible = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(panel, "modulate:a", 1.0, 0.25)


func hide_loading() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(panel, "modulate:a", 0.0, 0.4)
	_tween.tween_callback(func() -> void: panel.visible = false)
