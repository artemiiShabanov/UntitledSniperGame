extends VBoxContainer
## Displays kill notifications with distance and bonus info.
## Each entry fades out after a few seconds.

const DISPLAY_DURATION: float = 4.0
const FADE_DURATION: float = 1.0

var _entries: Array[Dictionary] = []  ## [{label: Label, timer: float}]


func _ready() -> void:
	RunManager.enemy_killed_with_info.connect(_on_enemy_killed)
	RunManager.npc_killed_with_info.connect(_on_npc_killed)
	RunManager.target_destroyed_with_info.connect(_on_target_destroyed)


func _process(delta: float) -> void:
	var i := _entries.size() - 1
	while i >= 0:
		var entry: Dictionary = _entries[i]
		entry.timer -= delta
		var label: Label = entry.label

		if entry.timer <= 0.0:
			label.queue_free()
			_entries.remove_at(i)
		elif entry.timer < FADE_DURATION:
			label.modulate.a = entry.timer / FADE_DURATION
		i -= 1


func _on_enemy_killed(info: Dictionary) -> void:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# Build the kill text
	var text := ""
	var dist_m := int(info.distance)

	# Distance
	text += "%dm" % dist_m

	# Multiplier info
	var parts: PackedStringArray = []
	if info.headshot:
		parts.append("HEADSHOT")
	if info.distance_multiplier > 1.0:
		parts.append("x%.1f RANGE" % info.distance_multiplier)
	if parts.size() > 0:
		text += " | " + " | ".join(parts)

	# Credits earned
	text += " | +$%d" % info.final_credits

	label.text = text

	# Color based on multiplier
	if info.total_multiplier >= 3.0:
		label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))  # Gold
	elif info.total_multiplier >= 2.0:
		label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))  # Orange
	elif info.headshot:
		label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))  # Red
	else:
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))  # White

	add_child(label)
	_entries.append({"label": label, "timer": DISPLAY_DURATION})


func _on_npc_killed(info: Dictionary) -> void:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.text = "CIVILIAN KILLED | -$%d" % info.penalty
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))  # Bright red
	add_child(label)
	_entries.append({"label": label, "timer": DISPLAY_DURATION})


func _on_target_destroyed(info: Dictionary) -> void:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.text = "TARGET DESTROYED | +$%d" % info.credits
	label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))  # Warm yellow
	add_child(label)
	_entries.append({"label": label, "timer": DISPLAY_DURATION})
