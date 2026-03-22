extends Control
## Full-screen overlay shown after a run ends (success or failure).
## Displays stats, credits, XP, then waits for player input to return to hub.

@onready var title_label: Label = $Panel/VBox/Title
@onready var stats_grid: GridContainer = $Panel/VBox/StatsGrid
@onready var credits_label: Label = $Panel/VBox/CreditsRow/CreditsValue
@onready var xp_label: Label = $Panel/VBox/XPRow/XPValue
@onready var continue_label: Label = $Panel/VBox/ContinuePrompt

var _active: bool = false


func _ready() -> void:
	visible = false
	RunManager.run_completed.connect(_on_run_completed)


func _on_run_completed(success: bool) -> void:
	_populate(success)
	visible = true
	# Short delay before accepting input to prevent accidental skip
	await get_tree().create_timer(1.0).timeout
	_active = true


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("shoot"):
		_active = false
		visible = false
		RunManager.go_to_hub()


func _populate(success: bool) -> void:
	var stats: Dictionary = RunManager.run_stats

	# Title
	if success:
		title_label.text = "EXTRACTION SUCCESSFUL"
		title_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	else:
		title_label.text = "MISSION FAILED"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))

	# Clear previous stat rows
	for child in stats_grid.get_children():
		child.queue_free()

	# Build stat rows
	var kills: int = stats.get("kills", 0)
	var headshots: int = stats.get("headshots", 0)
	var shots_fired: int = stats.get("shots_fired", 0)
	var shots_hit: int = stats.get("shots_hit", 0)
	var time_survived: float = stats.get("time_survived", 0.0)
	var longest_kill: float = stats.get("longest_kill_distance", 0.0)

	var accuracy := 0.0
	if shots_fired > 0:
		accuracy = (float(shots_hit) / float(shots_fired)) * 100.0

	_add_stat_row("Enemies Eliminated", str(kills))
	_add_stat_row("Headshots", str(headshots))
	_add_stat_row("Shots Fired", str(shots_fired))
	_add_stat_row("Accuracy", "%.0f%%" % accuracy)
	_add_stat_row("Time Survived", "%d:%02d" % [int(time_survived) / 60, int(time_survived) % 60])
	if longest_kill > 0.0:
		_add_stat_row("Longest Kill", "%.0fm" % longest_kill)

	# Credits
	var credits_earned: int = stats.get("credits_earned", 0)
	if success:
		credits_label.text = "+$%d" % credits_earned
		credits_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	else:
		credits_label.text = "$0 (lost)"
		credits_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

	# XP (always kept)
	var xp_earned: int = stats.get("xp_earned", 0)
	xp_label.text = "+%d XP" % xp_earned
	xp_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))

	# Continue prompt
	continue_label.text = "Press E to continue"


func _add_stat_row(label_text: String, value_text: String) -> void:
	var name_label := Label.new()
	name_label.text = label_text
	name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	stats_grid.add_child(name_label)

	var value_label := Label.new()
	value_label.text = value_text
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	stats_grid.add_child(value_label)
