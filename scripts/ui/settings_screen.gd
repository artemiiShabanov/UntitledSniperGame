extends PanelContainer
## Reusable settings screen — used in both main menu and pause menu.

signal closed

@onready var sensitivity_slider: HSlider = $VBox/SensitivityRow/Slider
@onready var sensitivity_label: Label = $VBox/SensitivityRow/Value
@onready var master_slider: HSlider = $VBox/MasterRow/Slider
@onready var master_label: Label = $VBox/MasterRow/Value
@onready var fullscreen_check: CheckButton = $VBox/FullscreenRow/CheckButton
@onready var vsync_check: CheckButton = $VBox/VsyncRow/CheckButton
@onready var back_btn: Button = $VBox/BackButton


func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	master_slider.value_changed.connect(_on_master_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)


func open() -> void:
	# Load current values
	sensitivity_slider.value = SettingsManager.mouse_sensitivity * 1000.0  # 0.001-0.005 → 1-5
	sensitivity_label.text = "%.1f" % (SettingsManager.mouse_sensitivity * 1000.0)
	master_slider.value = SettingsManager.master_volume * 100.0
	master_label.text = "%d%%" % int(SettingsManager.master_volume * 100.0)
	fullscreen_check.button_pressed = SettingsManager.fullscreen
	vsync_check.button_pressed = SettingsManager.vsync
	visible = true


func _on_sensitivity_changed(value: float) -> void:
	SettingsManager.mouse_sensitivity = value / 1000.0
	sensitivity_label.text = "%.1f" % value


func _on_master_changed(value: float) -> void:
	SettingsManager.master_volume = value / 100.0
	master_label.text = "%d%%" % int(value)
	SettingsManager.apply_all()


func _on_fullscreen_toggled(pressed: bool) -> void:
	SettingsManager.fullscreen = pressed
	SettingsManager.apply_all()


func _on_vsync_toggled(pressed: bool) -> void:
	SettingsManager.vsync = pressed
	SettingsManager.apply_all()


func _on_back() -> void:
	SettingsManager.save_settings()
	visible = false
	closed.emit()
