extends Control
## Full-screen overlay shown after a run ends (success or failure).
## Stats reveal one-by-one with a stagger, score/XP count up, and a rating is shown.

@onready var title_label: Label = $Panel/VBox/Title
@onready var stats_grid: GridContainer = $Panel/VBox/StatsGrid
@onready var credits_label: Label = $Panel/VBox/CreditsRow/CreditsValue
@onready var xp_label: Label = $Panel/VBox/XPRow/XPValue
@onready var continue_label: Label = $Panel/VBox/ContinuePrompt

var _active: bool = false
var _bold_font: Font = null
var _rating_icons: Dictionary = {}

## Reveal animation state
var _reveal_queue: Array[Dictionary] = []
var _reveal_timer: float = 0.0
var _reveal_index: int = 0
const REVEAL_INTERVAL: float = 0.12

## Counter animation state
var _counting: bool = false
var _count_timer: float = 0.0
var _score_target: int = 0
var _score_current: float = 0.0
var _xp_target: int = 0
var _xp_current: float = 0.0
const COUNT_DURATION: float = 1.2

## Continue prompt pulse
var _prompt_visible: bool = false
var _prompt_pulse_time: float = 0.0


func _ready() -> void:
	visible = false
	_bold_font = PaletteTheme.bold_font
	for r in ["S", "A", "B", "C", "D"]:
		var path := "res://assets/icons/ratings/rating_%s.png" % r
		if ResourceLoader.exists(path):
			_rating_icons[r] = load(path)
	RunManager.run_completed.connect(_on_run_completed)


func _on_run_completed(success: bool) -> void:
	_populate(success)
	visible = true
	await get_tree().create_timer(1.0).timeout
	_active = true


func _process(delta: float) -> void:
	if not visible:
		return

	# Staggered stat reveal
	if _reveal_index < _reveal_queue.size():
		_reveal_timer += delta
		while _reveal_timer >= REVEAL_INTERVAL and _reveal_index < _reveal_queue.size():
			_reveal_timer -= REVEAL_INTERVAL
			var entry: Dictionary = _reveal_queue[_reveal_index]
			entry["name"].visible = true
			entry["value"].visible = true
			AudioManager.play_sfx_2d_varied(&"scope_zoom", 0.3, -12.0)
			_reveal_index += 1

		if _reveal_index >= _reveal_queue.size() and not _counting:
			_counting = true
			_count_timer = 0.0

	# Counter animation for score/XP
	if _counting and _count_timer < COUNT_DURATION:
		_count_timer += delta
		var t := minf(_count_timer / COUNT_DURATION, 1.0)
		t = 1.0 - (1.0 - t) * (1.0 - t)

		_score_current = t * _score_target
		_xp_current = t * _xp_target

		if _score_target > 0:
			credits_label.text = "+%d" % int(_score_current)
		if _xp_target > 0:
			xp_label.text = "+%d XP" % int(_xp_current)

		if _count_timer >= COUNT_DURATION:
			if _score_target > 0:
				credits_label.text = "+%d" % _score_target
			if _xp_target > 0:
				xp_label.text = "+%d XP" % _xp_target
				AudioManager.play_sfx_2d(&"xp_gain")
			_prompt_visible = true
			_prompt_pulse_time = 0.0

	# Pulsing continue prompt
	if _prompt_visible:
		_prompt_pulse_time += delta
		var alpha := 0.5 + 0.5 * sin(_prompt_pulse_time * 3.0)
		continue_label.modulate.a = alpha
		continue_label.visible = true


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("shoot") or event.is_action_pressed("ui_accept"):
		_active = false
		visible = false
		RunManager.go_to_hub()


func _populate(success: bool) -> void:
	var stats: Dictionary = RunManager.run_stats.to_dict()

	_reveal_queue.clear()
	_reveal_index = 0
	_reveal_timer = 0.0
	_counting = false
	_count_timer = 0.0
	_prompt_visible = false
	continue_label.visible = false
	continue_label.modulate.a = 0.0

	# Title
	if _bold_font:
		title_label.add_theme_font_override("font", _bold_font)
	title_label.add_theme_font_size_override("font_size", 48)
	if success:
		title_label.text = "EXTRACTION SUCCESSFUL"
		title_label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_REWARD))
	else:
		title_label.text = "CASTLE FALLEN" if RunManager.castle_hp <= 0 else "FALLEN IN BATTLE"
		title_label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_DANGER))

	UIUtils.clear_children(stats_grid)

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
	_add_stat_row("Headshots", str(headshots), _headshot_color(headshots, kills))
	_add_stat_row("Shots Fired", str(shots_fired))
	_add_stat_row("Accuracy", "%.0f%%" % accuracy, _accuracy_color(accuracy))
	_add_stat_row("Time Survived", FormatUtils.format_time(time_survived))
	_add_stat_row("Phase Reached", str(RunManager.threat_phase))
	if longest_kill > 0.0:
		_add_stat_row("Longest Kill", "%.0fm" % longest_kill, PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT))

	var targets_destroyed: int = stats.get("targets_destroyed", 0)
	if targets_destroyed > 0:
		_add_stat_row("Targets Destroyed", str(targets_destroyed))

	var friendly_kills: int = stats.get("friendly_kills", 0)
	if friendly_kills > 0:
		_add_stat_row("Friendly Kills", str(friendly_kills), PaletteManager.get_color(PaletteManager.SLOT_DANGER))

	var opps: int = stats.get("opportunities_completed", 0)
	if opps > 0:
		_add_stat_row("Opportunities", str(opps), PaletteManager.get_color(PaletteManager.SLOT_REWARD))

	if not success:
		_add_stat_row("Equipped Mods", "LOST", PaletteManager.get_color(PaletteManager.SLOT_DANGER))

	# Rating
	var rating := _calculate_rating(stats, success)
	_add_stat_row("", "")
	_add_rating_row(rating)

	# Score — count-up animation
	var score_earned: int = stats.get("score_earned", 0)
	if success:
		_score_target = score_earned
		credits_label.text = "+0"
		credits_label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_REWARD))
	else:
		_score_target = 0
		credits_label.text = "0 (lost)"
		credits_label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_DANGER))
	if _bold_font:
		credits_label.add_theme_font_override("font", _bold_font)

	# XP
	var xp_earned: int = stats.get("xp_earned", 0)
	_xp_target = xp_earned
	xp_label.text = "+0 XP"
	xp_label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY))
	if _bold_font:
		xp_label.add_theme_font_override("font", _bold_font)

	continue_label.text = "Press E to continue"


func _add_stat_row(label_text: String, value_text: String, value_color: Color = Color.TRANSPARENT) -> void:
	var name_label := Label.new()
	name_label.text = label_text
	name_label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_BG_LIGHT))
	name_label.visible = false
	stats_grid.add_child(name_label)

	var value_label := Label.new()
	value_label.text = value_text
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if value_color != Color.TRANSPARENT:
		value_label.add_theme_color_override("font_color", value_color)
	else:
		value_label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY))
	if _bold_font:
		value_label.add_theme_font_override("font", _bold_font)
	value_label.visible = false
	stats_grid.add_child(value_label)

	_reveal_queue.append({ "name": name_label, "value": value_label })


func _add_rating_row(rating: String) -> void:
	var spacer := Label.new()
	spacer.text = "RATING"
	spacer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	spacer.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_BG_LIGHT))
	spacer.visible = false
	stats_grid.add_child(spacer)

	var rating_container := HBoxContainer.new()
	rating_container.alignment = BoxContainer.ALIGNMENT_END
	rating_container.add_theme_constant_override("separation", 12)
	rating_container.visible = false

	if _rating_icons.has(rating):
		var icon := TextureRect.new()
		icon.texture = _rating_icons[rating]
		icon.custom_minimum_size = Vector2(64, 64)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rating_container.add_child(icon)

	var rating_label := Label.new()
	rating_label.text = rating
	rating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rating_label.add_theme_font_size_override("font_size", 48)
	if _bold_font:
		rating_label.add_theme_font_override("font", _bold_font)
	rating_label.add_theme_color_override("font_color", _rating_color(rating))
	rating_container.add_child(rating_label)

	stats_grid.add_child(rating_container)
	_reveal_queue.append({ "name": spacer, "value": rating_container })


## ── Rating calculation ──────────────────────────────────────────────────────

func _calculate_rating(stats: Dictionary, success: bool) -> String:
	if not success:
		return "D"

	var score: float = 0.0
	var kills: int = stats.get("kills", 0)
	score += minf(kills * 5.0, 30.0)

	var shots_fired: int = stats.get("shots_fired", 0)
	var shots_hit: int = stats.get("shots_hit", 0)
	if shots_fired > 0:
		score += (float(shots_hit) / float(shots_fired)) * 30.0

	var headshots: int = stats.get("headshots", 0)
	score += minf(headshots * 5.0, 20.0)

	var time_survived: float = stats.get("time_survived", 0.0)
	score += minf(time_survived / 60.0, 10.0)

	var opps: int = stats.get("opportunities_completed", 0)
	score += opps * 10.0

	var friendly_kills: int = stats.get("friendly_kills", 0)
	score -= friendly_kills * 10.0

	score = maxf(score, 0.0)

	if score >= 90.0:
		return "S"
	elif score >= 70.0:
		return "A"
	elif score >= 50.0:
		return "B"
	elif score >= 30.0:
		return "C"
	else:
		return "D"


func _rating_color(rating: String) -> Color:
	match rating:
		"S": return PaletteManager.get_color(PaletteManager.SLOT_REWARD)
		"A": return PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT)
		"B": return PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY)
		"C": return PaletteManager.get_color(PaletteManager.SLOT_BG_LIGHT)
		_: return PaletteManager.get_color(PaletteManager.SLOT_DANGER)


func _accuracy_color(accuracy: float) -> Color:
	if accuracy >= 80.0:
		return PaletteManager.get_color(PaletteManager.SLOT_REWARD)
	elif accuracy >= 50.0:
		return PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT)
	elif accuracy >= 25.0:
		return PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY)
	else:
		return PaletteManager.get_color(PaletteManager.SLOT_BG_LIGHT)


func _headshot_color(headshots: int, kills: int) -> Color:
	if kills == 0:
		return PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY)
	var ratio := float(headshots) / float(kills)
	if ratio >= 0.5:
		return PaletteManager.get_color(PaletteManager.SLOT_REWARD)
	elif headshots >= 3:
		return PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT)
	else:
		return PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY)
