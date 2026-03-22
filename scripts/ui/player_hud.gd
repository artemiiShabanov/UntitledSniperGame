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


func _ready() -> void:
	RunManager.life_lost.connect(_on_life_lost)
	RunManager.run_started.connect(_on_run_started)
	RunManager.run_failed.connect(_on_run_failed)
	RunManager.run_completed.connect(_on_run_completed)
	RunManager.run_timer_updated.connect(_on_run_timer_updated)
	RunManager.threat_phase_changed.connect(_on_threat_phase_changed)
	_update_lives_display()
	run_timer_label.visible = false
	threat_phase_label.visible = false


func _process(delta: float) -> void:
	# Fade hit flash
	if hit_flash_alpha > 0.0:
		hit_flash_alpha = maxf(hit_flash_alpha - HIT_FLASH_FADE_SPEED * delta, 0.0)
		hit_flash.color.a = hit_flash_alpha


## ── Public API (called by Player) ───────────────────────────────────────────

func update_breath(ratio: float, exhausted: bool, scoped: bool) -> void:
	breath_meter.update_breath(ratio, exhausted, scoped)


func update_scope_visuals(scoped: bool) -> void:
	crosshair.visible = not scoped
	scope_overlay.visible = scoped
	if scoped:
		scope_overlay.queue_redraw()


func update_weapon_display(weapon: Weapon) -> void:
	const STATE_NAMES := ["IDLE", "AIMING", "BOLT_CYCLING", "RELOADING", "INSPECTING"]
	var ammo := weapon.get_current_ammo_type()
	var ammo_name := ammo.ammo_name if ammo else "???"
	weapon_state_label.text = "%s | %s %d/%d | $%d" % [
		STATE_NAMES[weapon.state],
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


func update_interact_prompt(text: String) -> void:
	interact_prompt.text = text
	interact_prompt.visible = true


func hide_interact_prompt() -> void:
	interact_prompt.visible = false


func flash_hit() -> void:
	hit_flash_alpha = 0.4
	hit_flash.color = Color(1, 0, 0, hit_flash_alpha)


## ── RunManager signal callbacks ─────────────────────────────────────────────

func _on_life_lost(_lives_remaining: int) -> void:
	_update_lives_display()
	flash_hit()


func _on_run_started() -> void:
	run_timer_label.visible = true
	threat_phase_label.visible = true
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
	var minutes := int(time_left) / 60
	var seconds := int(time_left) % 60
	run_timer_label.text = "%d:%02d" % [minutes, seconds]
	# Turn red when under 30 seconds
	if time_left <= 30.0:
		run_timer_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	else:
		run_timer_label.remove_theme_color_override("font_color")


func _on_threat_phase_changed(_phase: RunManager.ThreatPhase) -> void:
	_update_threat_display()


## ── Private display helpers ─────────────────────────────────────────────────

func _update_threat_display() -> void:
	var phase_name := RunManager.get_threat_phase_name()
	threat_phase_label.text = "THREAT: %s" % phase_name
	match RunManager.threat_phase:
		RunManager.ThreatPhase.EARLY:
			threat_phase_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		RunManager.ThreatPhase.MID:
			threat_phase_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
		RunManager.ThreatPhase.LATE:
			threat_phase_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))


func _update_lives_display() -> void:
	var hearts := ""
	for i in range(RunManager.max_lives):
		if i < RunManager.lives:
			hearts += "♥ "
		else:
			hearts += "♡ "
	lives_label.text = hearts.strip_edges()
