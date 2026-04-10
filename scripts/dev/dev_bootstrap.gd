extends Node
## Dev Bootstrap — creates dev tools when running in debug mode.
## Register as autoload: DevBootstrap.

func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	# Dev HUD (F3 toggle).
	var hud := CanvasLayer.new()
	hud.set_script(load("res://scripts/dev/dev_hud.gd"))
	hud.name = "DevHUD"
	add_child(hud)

	# Dev Console (backtick toggle).
	var console := CanvasLayer.new()
	console.set_script(load("res://scripts/dev/dev_console.gd"))
	console.name = "DevConsole"
	add_child(console)
