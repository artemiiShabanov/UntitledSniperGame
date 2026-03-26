extends Control
## Skill Shop panel — browse and unlock player skills with XP.

signal shop_closed

@onready var xp_label: Label = $VBox/XPLabel
@onready var item_list: VBoxContainer = $VBox/ScrollContainer/ItemList
@onready var close_btn: Button = $VBox/CloseButton


func _ready() -> void:
	close_btn.pressed.connect(func(): shop_closed.emit())
	AudioManager.wire_button(close_btn, &"menu_cancel")


func open() -> void:
	visible = true
	_refresh()


func _refresh() -> void:
	_update_xp_label()
	_rebuild_skill_list()


func _update_xp_label() -> void:
	xp_label.text = "XP: %d" % SaveManager.get_xp()


func _rebuild_skill_list() -> void:
	for child in item_list.get_children():
		child.queue_free()

	var skills := SkillRegistry.get_all_skills()
	for skill in skills:
		var row := _build_skill_row(skill)
		item_list.add_child(row)


func _build_skill_row(skill: PlayerSkill) -> PanelContainer:
	var panel := PanelContainer.new()
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var owned: bool = SaveManager.has_skill(skill.id)

	# Left: info
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = skill.skill_name
	if owned:
		name_label.text += "  [UNLOCKED]"
		name_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	info_vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = skill.description
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	desc_label.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(desc_label)

	hbox.add_child(info_vbox)

	# Right: buy button
	if not owned:
		var buy_btn := Button.new()
		buy_btn.text = "%d XP" % skill.cost
		buy_btn.custom_minimum_size = Vector2(80, 0)
		buy_btn.disabled = SaveManager.get_xp() < skill.cost
		buy_btn.pressed.connect(_on_buy.bind(skill))
		AudioManager.wire_button(buy_btn, &"menu_confirm")
		hbox.add_child(buy_btn)

	return panel


func _on_buy(skill: PlayerSkill) -> void:
	if SaveManager.purchase_skill(skill.id, skill.cost):
		AudioManager.play_sfx_2d(&"menu_confirm")
		_refresh()
