extends CanvasLayer
## Dev console — toggle with backtick. Provides buttons for testing game systems.

var _panel: PanelContainer
var _visible: bool = false
var _god_mode: bool = false

# Warrior scenes for spawning.
var _warrior_scenes: Dictionary = {}


func _ready() -> void:
	layer = 101
	_build_ui()
	visible = false

	_warrior_scenes = {
		"swordsman": preload("res://scenes/warrior/warrior_swordsman.tscn"),
		"big_guy": preload("res://scenes/warrior/warrior_big_guy.tscn"),
		"knight": preload("res://scenes/warrior/warrior_knight.tscn"),
		"bombardier": preload("res://scenes/warrior/warrior_bombardier.tscn"),
		"archer": preload("res://scenes/warrior/warrior_archer.tscn"),
		"heavy_archer": preload("res://scenes/warrior/warrior_heavy_archer.tscn"),
		"crossbowman": preload("res://scenes/warrior/warrior_crossbowman.tscn"),
		"bird_trainer": preload("res://scenes/warrior/warrior_bird_trainer.tscn"),
	}


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_QUOTELEFT:
		_visible = not _visible
		visible = _visible
		if _visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	_panel.offset_left = 10
	_panel.offset_top = 40
	_panel.offset_right = 500
	_panel.offset_bottom = -10
	add_child(_panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(470, 700)
	_panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	var title := Label.new()
	title.text = "DEV CONSOLE"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# ── Warrior spawning ──
	_add_section(vbox, "MELEE WARRIORS")
	_add_btn(vbox, "Hostile Swordsman", _spawn_warrior.bind("swordsman", WarriorBase.Faction.HOSTILE))
	_add_btn(vbox, "Friendly Swordsman", _spawn_warrior.bind("swordsman", WarriorBase.Faction.FRIENDLY))
	_add_btn(vbox, "Hostile Big Guy", _spawn_warrior.bind("big_guy", WarriorBase.Faction.HOSTILE))
	_add_btn(vbox, "Friendly Big Guy", _spawn_warrior.bind("big_guy", WarriorBase.Faction.FRIENDLY))
	_add_btn(vbox, "Hostile Knight", _spawn_warrior.bind("knight", WarriorBase.Faction.HOSTILE))
	_add_btn(vbox, "Friendly Knight", _spawn_warrior.bind("knight", WarriorBase.Faction.FRIENDLY))
	_add_btn(vbox, "Hostile Bombardier", _spawn_warrior.bind("bombardier", WarriorBase.Faction.HOSTILE))

	_add_section(vbox, "RANGED WARRIORS (hostile only)")
	_add_btn(vbox, "Archer", _spawn_warrior.bind("archer", WarriorBase.Faction.HOSTILE))
	_add_btn(vbox, "Heavy Archer", _spawn_warrior.bind("heavy_archer", WarriorBase.Faction.HOSTILE))
	_add_btn(vbox, "Crossbowman", _spawn_warrior.bind("crossbowman", WarriorBase.Faction.HOSTILE))
	_add_btn(vbox, "Bird Trainer", _spawn_warrior.bind("bird_trainer", WarriorBase.Faction.HOSTILE))

	_add_section(vbox, "")
	_add_btn(vbox, "Kill All Warriors", _kill_all_warriors)

	vbox.add_child(HSeparator.new())

	# ── Phase & Castle ──
	_add_section(vbox, "PHASE & CASTLE")
	_add_btn(vbox, "Phase +1", _adjust_phase.bind(1))
	_add_btn(vbox, "Phase +5", _adjust_phase.bind(5))
	_add_btn(vbox, "Castle HP -20", _adjust_castle_hp.bind(-20))
	_add_btn(vbox, "Castle HP +50", _adjust_castle_hp.bind(50))
	_add_btn(vbox, "Castle HP = 1", _set_castle_hp.bind(1))

	vbox.add_child(HSeparator.new())

	# ── Extraction & Opportunity ──
	_add_section(vbox, "EVENTS")
	_add_btn(vbox, "Open Extraction (15s)", _open_extraction.bind(15.0))
	_add_btn(vbox, "Trigger Random Opportunity", _trigger_opportunity)

	vbox.add_child(HSeparator.new())

	# ── Score & Progression ──
	_add_section(vbox, "PROGRESSION")
	_add_btn(vbox, "Add 500 Score", func(): RunManager.add_run_score(500))
	_add_btn(vbox, "Add 500 XP", func(): RunManager.add_run_xp(500))
	_add_btn(vbox, "Add 1000 XP (save)", _add_xp_to_save.bind(1000))
	_add_btn(vbox, "Give Random Mod", _give_random_mod)

	vbox.add_child(HSeparator.new())

	# ── Utility ──
	_add_section(vbox, "UTILITY")
	_add_btn(vbox, "Toggle God Mode", _toggle_god_mode)
	_add_btn(vbox, "Full Heal", _full_heal)
	_add_btn(vbox, "Refill Bullets", _refill_bullets)


func _add_section(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	parent.add_child(label)


func _add_btn(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 32)
	btn.pressed.connect(callback)
	parent.add_child(btn)


## ── Commands ──────────────────────────────────────────────────────────────

func _spawn_warrior(type: String, faction: WarriorBase.Faction) -> void:
	if not _warrior_scenes.has(type):
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return

	var warrior: WarriorBase = _warrior_scenes[type].instantiate()
	warrior.faction = faction
	var player_pos: Vector3 = players[0].global_position
	var forward: Vector3 = -players[0].global_transform.basis.z
	var spawn_pos := player_pos + forward * 20.0
	spawn_pos.y = 0.0
	warrior.advance_target = player_pos  # Walk toward player
	get_tree().root.add_child(warrior)
	warrior.global_position = spawn_pos


func _kill_all_warriors() -> void:
	for w in get_tree().get_nodes_in_group("warrior"):
		w.queue_free()


func _adjust_phase(delta: int) -> void:
	var new_phase := clampi(RunManager.threat_phase + delta, 1, RunManager.THREAT_PHASE_MAX)
	# Must set run_elapsed too, otherwise _update_threat_phase() overwrites next frame.
	RunManager.run_elapsed = (new_phase - 1) * RunManager.PHASE_DURATION
	RunManager.threat_phase = new_phase
	RunManager.threat_phase_changed.emit(new_phase)


func _adjust_castle_hp(delta: int) -> void:
	RunManager.castle_hp = clampi(RunManager.castle_hp + delta, 0, RunManager.castle_max_hp)
	RunManager.castle_hp_changed.emit(RunManager.castle_hp, RunManager.castle_max_hp)
	if RunManager.castle_hp <= 0:
		RunManager.castle_destroyed.emit()


func _set_castle_hp(value: int) -> void:
	RunManager.castle_hp = clampi(value, 0, RunManager.castle_max_hp)
	RunManager.castle_hp_changed.emit(RunManager.castle_hp, RunManager.castle_max_hp)


func _open_extraction(duration: float) -> void:
	RunManager.extraction_window_open = true
	RunManager.extraction_window_timer = duration
	RunManager.extraction_window_opened.emit(duration)


func _trigger_opportunity() -> void:
	var runners := get_tree().get_nodes_in_group("opportunity_runner")
	if runners.is_empty():
		return
	var runner: OpportunityRunner = runners[0]
	var eligible := OpportunityRegistry.get_eligible(RunManager.threat_phase)
	if eligible.is_empty():
		eligible = OpportunityRegistry.get_all()
	if not eligible.is_empty():
		runner._start_opportunity(eligible.pick_random())


func _add_xp_to_save(amount: int) -> void:
	SaveManager.add_xp(amount)
	SaveManager.save()


func _give_random_mod() -> void:
	var slot: int = randi() % 5
	var rarity: int = randi() % 4
	var mod: RifleMod = ModRegistry.generate(slot, rarity)
	if SaveManager.add_mod_to_inventory(mod):
		RunManager.announce_event("DEV: Got %s %s mod" % [RifleMod.RARITY_NAMES[rarity], RifleMod.SLOT_NAMES[slot]])
	else:
		RunManager.announce_event("DEV: Inventory full for slot")


func _toggle_god_mode() -> void:
	_god_mode = not _god_mode
	RunManager.set_meta("god_mode", _god_mode)
	RunManager.announce_event("God mode: %s" % ("ON" if _god_mode else "OFF"))


func _full_heal() -> void:
	RunManager.lives = RunManager.max_lives
	RunManager.castle_hp = RunManager.castle_max_hp
	RunManager.castle_hp_changed.emit(RunManager.castle_hp, RunManager.castle_max_hp)


func _refill_bullets() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var weapon = players[0].get_node_or_null("Head/Camera3D/Weapon")
	if weapon and "bullets_remaining" in weapon:
		weapon.bullets_remaining = 999
		if weapon.has_signal("bullets_changed"):
			weapon.bullets_changed.emit(999)
