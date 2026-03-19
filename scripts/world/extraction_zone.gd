class_name ExtractionZone
extends Area3D
## Walk into this zone to begin extraction. Leave to cancel.
## Requires a CollisionShape3D child defining the trigger volume.

@export var zone_size: Vector3 = Vector3(4, 3, 4)

@onready var mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Green pulsing placeholder visual
	if mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.1, 0.8, 0.2, 0.3)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material_override = mat


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):  # It's the player
		RunManager.begin_extraction()


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		RunManager.cancel_extraction()
