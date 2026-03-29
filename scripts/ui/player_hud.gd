extends CanvasLayer
## Manages all in-run HUD display updates.
## Connects to RunManager signals and receives calls from Player for weapon/interaction state.

## ── Node references ──────────────────────────────────────────────────────────

@onready var crosshair: Control = $Crosshair
@onready var scope_overlay: Control = $ScopeOverlay
@onready var weapon_state_label: Label = $WeaponState
@onready var lives_label: Label = $LivesLabel
@onready var hit_flash: ColorRect = $HitFlash
@onready var breath_meter: Control = $BreathMeter
@onready var run_timer_label: Label = $RunTimer
@onready var threat_phase_label: Label = $ThreatPhase
@onready var interact_prompt: Label = $InteractPrompt

## ── State ────────────────────────────────────────────────────────────────────

var hit_flash_alpha: float = 0.0
const HIT_FLASH_FADE_SPEED: float = 3.0

## Heart icon textures
var _heart_full_tex: Texture2D
var _heart_empty_tex: Texture2D
var _heart_icons: Array[TextureRect] = []
var _heart_container: HBoxContainer = null


func _ready() -> void:
	RunManager.life_lost.connect(_on_life_lost)
	RunManager.run_started.connect(_on_run_started)
	RunManager.run_failed.connect(_on_run_failed)
	RunManager.run_completed.connect(_on_run_completed)
	RunManager.run_timer_updated.connect(_on_run_timer_updated)
	RunManager.threat_phase_changed.connect(_on_threat_phase_changed)
	PaletteManager.palette_changed.connect(_on_palette_changed)
	# Load heart icons
	_heart_full_tex = _try_load_tex("res://assets/icons/hud/heart_full.png")
	_heart_empty_tex = _try_load_tex("res://assets/icons/hud/heart_empty.png")
	_update_lives_display()
	run_timer_label.visible = false
	threat_phase_label.visible = false
	# Bold HUD elements
	var bold_font: Font = load("res://assets/fonts/JetBrainsMono-Bold.ttf")
	if bold_font:
		weapon_state_label.add_theme_font_override("font", bold_font)
		lives_label.add_theme_font_override("font", bold_font)
		run_timer_label.add_theme_font_override("font", bold_font)
		threat_phase_label.add_theme_font_override("font", bold_font)
	# Hide run-only elements when in hub
	_update_hud_visibility()


func _process(delta: float) -> void:
	# Fade hit flash
	if hit_flash_alpha > 0.0:
		hit_flash_alpha = maxf(hit_flash_alpha - HIT_FLASH_FADE_SPEED * delta, 0.0)
		hit_flash.color.a = hit_flash_alpha


## ── Public API (called by Player) ───────────────────────────────────────────

func update_breath(ratio: float, exhausted: bool, scoped: bool) -> void:
	breath_meter.update_breath(ratio, exhausted, scoped)


func update_scope_visuals(scoped: bool) -> void:
	var in_run := RunManager.game_state != RunManager.GameState.HUB
	crosshair.visible = in_run and not scoped
	scope_overlay.visible = in_run and scoped
	if scoped and in_run:
		scope_overlay.queue_redraw()


func update_weapon_display(weapon: Weapon) -> void:
	const STATE_NAMES := ["IDLE", "AIMING", "BOLT_CYCLING", "RELOADING", "INSPECTING"]
	var ammo := weapon.get_current_ammo_type()
	var ammo_name := ammo.ammo_name if ammo else "???"
	var state_idx := clampi(weapon.state, 0, STATE_NAMES.size() - 1)
	weapon_state_label.text = "%s | %s %d/%d | $%d" % [
		STATE_NAMES[state_idx],
		ammo_name,
		weapon.ammo_in_magazine,
		weapon.ammo_reserve,
		RunManager.get_run_credits(),
	]
	# Color the label to match ammo type
	if ammo:
		weapon_state_label.add_theme_color_override("font_color", ammo.tracer_color)
	else:
		weapon_state_label.remove_theme_color_override("font_color")

	# Update ammo icon in HUD (lazily created TextureRect next to weapon label)
	_update_ammo_icon(ammo)


var _ammo_icon_rect: TextureRect = null

func _update_ammo_icon(ammo: AmmoType) -> void:
	if not ammo or not ammo.icon:
		if _ammo_icon_rect:
			_ammo_icon_rect.visible = false
		return
	if not _ammo_icon_rect:
		_ammo_icon_rect = TextureRect.new()
		_ammo_icon_rect.custom_minimum_size = Vector2(28, 28)
		_ammo_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_ammo_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		# Position next to weapon state label (top-right)
		_ammo_icon_rect.anchors_preset = Control.PRESET_TOP_RIGHT
		_ammo_icon_rect.anchor_left = 1.0
		_ammo_icon_rect.anchor_right = 1.0
		_ammo_icon_rect.offset_left = -530.0
		_ammo_icon_rect.offset_top = 25.0
		_ammo_icon_rect.offset_right = -502.0
		_ammo_icon_rect.offset_bottom = 53.0
		add_child(_ammo_icon_rect)
	_ammo_icon_rect.texture = ammo.icon
	_ammo_icon_rect.visible = true


func update_interact_prompt(text: String) -> void:
	interact_prompt.text = text
	interact_prompt.visible = true


func hide_interact_prompt() -> void:
	interact_prompt.visible = false


func flash_hit() -> void:
	hit_flash_alpha = 0.4
	hit_flash.color = Color(PaletteManager.get_color(&"danger"), hit_flash_alpha)


## ── RunManager signal callbacks ─────────────────────────────────────────────

func _on_life_lost(_lives_remaining: int) -> void:
	_update_lives_display()
	flash_hit()


func _on_run_started() -> void:
	_update_hud_visibility()
	_update_lives_display()
	_update_threat_display()


func _on_run_failed() -> void:
	_update_lives_display()


func _on_run_completed(_success: bool) -> void:
	run_timer_label.visible = false
	threat_phase_label.visible = false


func _on_run_timer_updated(time_left: float) -> void:
	run_timer_label.visible = RunManager.game_state == RunManager.GameState.IN_RUN or \
		RunManager.game_state == RunManager.GameState.EXTRACTING
	run_timer_label.text = FormatUtils.format_time(time_left)
	if time_left <= 30.0:
		run_timer_label.add_theme_color_override("font_color", PaletteManager.get_color(&"danger"))
	else:
		run_timer_label.add_theme_color_override("font_color", PaletteManager.get_color(&"accent_friendly"))


func _on_threat_phase_changed(_phase: RunManager.ThreatPhase) -> void:
	_update_threat_display()


## ── Private display helpers ─────────────────────────────────────────────────

func _update_threat_display() -> void:
	var phase_name := RunManager.get_threat_phase_name()
	threat_phase_label.text = "THREAT: %s" % phase_name
	match RunManager.threat_phase:
		RunManager.ThreatPhase.EARLY:
			threat_phase_label.add_theme_color_override("font_color", PaletteManager.get_color(&"accent_friendly"))
		RunManager.ThreatPhase.MID:
			threat_phase_label.add_theme_color_override("font_color", PaletteManager.get_color(&"accent_loot"))
		RunManager.ThreatPhase.LATE:
			threat_phase_label.add_theme_color_override("font_color", PaletteManager.get_color(&"danger"))


func _on_palette_changed(_palette: PaletteResource) -> void:
	_update_lives_display()
	_update_threat_display()


func _update_hud_visibility() -> void:
	## Hide run-specific HUD elements when in hub.
	var in_run := RunManager.game_state != RunManager.GameState.HUB
	crosshair.visible = in_run and not scope_overlay.visible
	weapon_state_label.visible = in_run
	lives_label.visible = in_run
	run_timer_label.visible = in_run
	threat_phase_label.visible = in_run
	breath_meter.visible = false  # Shown dynamically by update_breath


static func _try_load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _update_lives_display() -> void:
	if _heart_full_tex and _heart_empty_tex:
		# Icon-based hearts
		lives_label.text = ""
		if not _heart_container:
			_heart_container = HBoxContainer.new()
			_heart_container.add_theme_constant_override("separation", 4)
			# Position next to lives_label
			lives_label.add_child(_heart_container)
		# Rebuild heart icons
		for icon in _heart_icons:
			icon.queue_free()
		_heart_icons.clear()
		var tint := PaletteManager.get_color(&"danger") if RunManager.lives <= 1 else PaletteManager.get_color(&"accent_friendly")
		for i in range(RunManager.max_lives):
			var icon := TextureRect.new()
			icon.custom_minimum_size = Vector2(28, 28)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			if i < RunManager.lives:
				icon.texture = _heart_full_tex
				icon.modulate = tint
			else:
				icon.texture = _heart_empty_tex
				icon.modulate = PaletteManager.get_color(&"bg_mid")
			_heart_container.add_child(icon)
			_heart_icons.append(icon)
	else:
		# Fallback: text hearts
		var hearts := ""
		for i in range(RunManager.max_lives):
			if i < RunManager.lives:
				hearts += "♥ "
			else:
				hearts += "♡ "
		lives_label.text = hearts.strip_edges()
		var color_slot := &"danger" if RunManager.lives <= 1 else &"accent_friendly"
		lives_label.add_theme_color_override("font_color", PaletteManager.get_color(color_slot))
