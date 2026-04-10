extends Node
## Dev Bootstrap — creates dev tools when running in debug mode.
## Register as autoload: DevBootstrap.

func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	# Dev HUD (F3 toggle).
	var hud_script := load("res://scripts/dev/dev_hud.gd")
	var hud := Node.new()
	hud.set_script(hud_script)
	hud.name = "DevHUD"
	add_child(hud)

	# Dev Console (backtick toggle).
	var console_script := load("res://scripts/dev/dev_console.gd")
	var console := Node.new()
	console.set_script(console_script)
	console.name = "DevConsole"
	add_child(console)
