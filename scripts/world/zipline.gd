extends Interactable

## Zipline tuning
@export var speed: float = 8.0
@export var detach_upward_boost: float = 3.0
@export var hang_offset_y: float = -0.5  ## How far below the line the player hangs
@export var attach_radius: float = 3.0  ## Max distance from the line to attach

## Endpoints (local to this node)
@export var point_a: Vector3 = Vector3.ZERO
@export var point_b: Vector3 = Vector3(10, 0, 0)

## Internal
var line_length: float = 0.0
var line_direction: Vector3 = Vector3.ZERO

@onready var rope_mesh: MeshInstance3D = $RopeMesh


func _ready() -> void:
	add_to_group("zipline")
	_update_geometry()


func _update_geometry() -> void:
	var diff := point_b - point_a
	line_length = diff.length()
	line_direction = diff.normalized() if line_length > 0.01 else Vector3.RIGHT

	# Rope mesh: cylinder aligned along the line
	var midpoint := (point_a + point_b) / 2.0
	rope_mesh.position = midpoint

	# Scale cylinder height to match line length (default cylinder height = 1)
	var cyl_mesh: CylinderMesh = rope_mesh.mesh
	cyl_mesh.height = line_length

	# Rotate cylinder to align with the line direction
	# Default cylinder is along Y axis; we need to rotate it to face along diff
	rope_mesh.rotation = Vector3.ZERO
	if line_length > 0.01:
		# Build a basis where Y points along the line direction
		var up := line_direction
		var arbitrary := Vector3.RIGHT if absf(up.dot(Vector3.RIGHT)) < 0.99 else Vector3.FORWARD
		var right := up.cross(arbitrary).normalized()
		var forward := right.cross(up).normalized()
		rope_mesh.basis = Basis(right, up, forward)


func get_position_on_line(progress: float) -> Vector3:
	return global_transform * point_a.lerp(point_b, progress) + Vector3(0, hang_offset_y, 0)


## Returns the closest progress (0→1) on the line to a world position,
## and the distance from that point to the position.
func get_closest_point(world_pos: Vector3) -> Dictionary:
	var a_world: Vector3 = global_transform * point_a
	var b_world: Vector3 = global_transform * point_b
	var ab := b_world - a_world
	# Project world_pos onto the line segment, clamped to [0, 1]
	var t := clampf(ab.dot(world_pos - a_world) / ab.length_squared(), 0.0, 1.0)
	var closest := a_world + ab * t
	var dist := world_pos.distance_to(closest)
	return { "progress": t, "distance": dist }


## ── Interactable overrides ────────────────────────────────────────────────────

func interact(player: CharacterBody3D) -> void:
	# Player handles the actual attach logic
	var result := get_closest_point(player.global_position)
	if result.distance <= attach_radius:
		player._attach_to_zipline(self, result.progress)


func get_interact_prompt() -> String:
	return "[E] Zipline"


## Returns the natural ride direction: downhill (toward lower endpoint).
## If flat, defaults to A→B (+1).
func get_gravity_direction() -> float:
	var a_world: Vector3 = global_transform * point_a
	var b_world: Vector3 = global_transform * point_b
	if b_world.y < a_world.y - 0.1:
		return 1.0  # A is higher, ride A→B (downhill)
	elif a_world.y < b_world.y - 0.1:
		return -1.0  # B is higher, ride B→A (downhill)
	return 1.0  # Flat, default A→B
