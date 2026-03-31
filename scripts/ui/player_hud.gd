extends CanvasLayer
## Thin HUD coordinator — routes signals and player calls to sub-components.
## Each visual element (crosshair, lives, weapon state, etc.) is a self-contained script.

## ── Node references ──────────────────────────────────────────────────────────

@onready var crosshair: Control = $Crosshair
@onready var scope_overlay: Control = $ScopeOverlay
@onready var weapon_state: Label = $WeaponState        ## weapon_state_display.gd
@onready var lives_label: Label = $LivesLabel           ## lives_display.gd
@onready var hit_flash: ColorRect = $HitFlash           ## hit_flash.gd
@onready var breath_meter: Control = $BreathMeter       ## breath_meter.gd
@onready var run_timer_label: Label = $RunTimer         ## run_timer_display.gd
@onready var threat_phase_label: Label = $ThreatPhase   ## threat_display.gd
@onready var interact_prompt: Label = $InteractPrompt


func _ready() -> void:
	RunManager.run_started.connect(_on_run_started)
	RunManager.run_completed.connect(_on_run_completed)
	RunManager.life_lost.connect(_on_life_lost)
	_update_hud_visibility()


## ── Public API (called by Player) ───────────────────────────────────────────

func update_breath(ratio: float, exhausted: bool, scoped: bool) -> void:
	breath_meter.update_breath(ratio, exhausted, scoped)


func update_scope_visuals(scoped: bool) -> void:
	var in_run := RunManager.game_state != RunManager.GameState.HUB
	crosshair.visible = in_run and not scoped
	scope_overlay.visible = in_run and scoped
	if scoped and in_run:
		scope_overlay.queue_redraw()


func update_weapon_display(wpn: Node3D) -> void:
	weapon_state.update(wpn)


func update_interact_prompt(text: String) -> void:
	interact_prompt.text = text
	interact_prompt.visible = true


func hide_interact_prompt() -> void:
	interact_prompt.visible = false


func flash_hit() -> void:
	hit_flash.flash()


## ── RunManager signal callbacks ─────────────────────────────────────────────

func _on_life_lost(_lives_remaining: int) -> void:
	flash_hit()


func _on_run_started() -> void:
	_update_hud_visibility()


func _on_run_completed(_success: bool) -> void:
	pass  # Sub-components handle their own visibility via direct signal connections


## ── Visibility ──────────────────────────────────────────────────────────────

func _update_hud_visibility() -> void:
	## Hide run-specific HUD elements when in hub.
	var in_run := RunManager.game_state != RunManager.GameState.HUB
	crosshair.visible = in_run and not scope_overlay.visible
	weapon_state.visible = in_run
	lives_label.visible = in_run
	run_timer_label.visible = in_run
	threat_phase_label.visible = in_run
	breath_meter.visible = false  # Shown dynamically by update_breath
