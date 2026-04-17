class_name WarriorSpawner
extends Node
## Spawns both friendly and hostile warriors during a run.
## Added as a child of the level scene. Reads spawn points from level markers.
##
## Hostile warriors spawn from "hostile_spawn_points" group markers.
## Friendly warriors spawn from "friendly_spawn_points" group markers.
## Hostile advance targets come from "castle_wall_points" group markers.
## Friendly advance targets come from "frontline_points" group markers.

## ── Spawn pool entry ────────────────────────────────────────────────────────

class WarriorPoolEntry:
	var scene: PackedScene
	var min_phase: int
	var weight: float
	var hostile_only: bool

	func _init(p_scene: PackedScene, p_min_phase: int, p_weight: float, p_hostile_only: bool = false) -> void:
		scene = p_scene
		min_phase = p_min_phase
		weight = p_weight
		hostile_only = p_hostile_only

## ── Exports ──────────────────────────────────────────────────────────────────

@export var base_hostile_interval: float = 4.0   ## Seconds between hostile spawns at phase 1
@export var base_friendly_interval: float = 5.0  ## Seconds between friendly spawns at phase 1
@export var min_spawn_interval: float = 1.0      ## Fastest spawn rate at high phases

## ── State ────────────────────────────────────────────────────────────────────

var _hostile_timer: float = 0.0
var _friendly_timer: float = 0.0
var _hostile_spawns: Array[Node3D] = []
var _friendly_spawns: Array[Node3D] = []
var _castle_wall_points: Array[Node3D] = []
var _frontline_points: Array[Node3D] = []
var _pool: Array[WarriorPoolEntry] = []
var _active: bool = false


func _ready() -> void:
	_build_pool()
	RunManager.run_started.connect(_on_run_started)
	RunManager.run_completed.connect(func(_s: bool) -> void: _active = false)


func _on_run_started() -> void:
	_hostile_spawns = _get_markers("hostile_spawn_points")
	_friendly_spawns = _get_markers("friendly_spawn_points")
	_castle_wall_points = _get_markers("castle_wall_points")
	_frontline_points = _get_markers("frontline_points")
	_hostile_timer = 1.0  # Short delay before first spawn
	_friendly_timer = 2.0
	_active = true


func _physics_process(delta: float) -> void:
	if not _active:
		return

	var phase := RunManager.threat_phase

	_hostile_timer -= delta
	if _hostile_timer <= 0.0:
		_hostile_timer = _get_hostile_interval(phase)
		_spawn_hostile(phase)

	_friendly_timer -= delta
	if _friendly_timer <= 0.0:
		_friendly_timer = _get_friendly_interval(phase)
		_spawn_friendly(phase)


## ── Spawning ────────────────────────────────────────────────────────────────

func _spawn_hostile(phase: int) -> void:
	if _hostile_spawns.is_empty() or _castle_wall_points.is_empty():
		return

	var entry := _pick_from_pool(phase, false)
	if not entry:
		return

	var warrior: WarriorBase = entry.scene.instantiate()
	var spawn := _hostile_spawns.pick_random() as Node3D
	var target := _castle_wall_points.pick_random() as Node3D

	warrior.faction = WarriorBase.Faction.HOSTILE
	warrior.advance_target = target.global_position
	_spawn_into_level(warrior)
	warrior.global_position = spawn.global_position


func _spawn_into_level(warrior: WarriorBase) -> void:
	# Add warrior as a child of the level scene (spawner's parent) so it's
	# cleaned up on scene change instead of persisting on SceneTree root.
	var parent := get_parent()
	if parent:
		parent.add_child(warrior)
	else:
		get_tree().root.add_child(warrior)


func _spawn_friendly(phase: int) -> void:
	if _friendly_spawns.is_empty() or _frontline_points.is_empty():
		return

	var entry := _pick_from_pool(phase, true)
	if not entry:
		return

	var warrior: WarriorBase = entry.scene.instantiate()
	var spawn := _friendly_spawns.pick_random() as Node3D
	var target := _frontline_points.pick_random() as Node3D

	warrior.faction = WarriorBase.Faction.FRIENDLY
	warrior.advance_target = target.global_position
	_spawn_into_level(warrior)
	warrior.global_position = spawn.global_position


## ── Pool ────────────────────────────────────────────────────────────────────

func _build_pool() -> void:
	_pool = [
		# Melee
		WarriorPoolEntry.new(preload("res://scenes/warrior/warrior_swordsman.tscn"), 1, 10.0),
		WarriorPoolEntry.new(preload("res://scenes/warrior/warrior_big_guy.tscn"), 6, 4.0),
		WarriorPoolEntry.new(preload("res://scenes/warrior/warrior_knight.tscn"), 10, 2.0),
		WarriorPoolEntry.new(preload("res://scenes/warrior/warrior_bombardier.tscn"), 6, 3.0, true),
		# Ranged (hostile only)
		WarriorPoolEntry.new(preload("res://scenes/warrior/warrior_archer.tscn"), 4, 5.0, true),
		WarriorPoolEntry.new(preload("res://scenes/warrior/warrior_heavy_archer.tscn"), 7, 3.0, true),
		WarriorPoolEntry.new(preload("res://scenes/warrior/warrior_crossbowman.tscn"), 9, 2.0, true),
		WarriorPoolEntry.new(preload("res://scenes/warrior/warrior_bird_trainer.tscn"), 11, 1.5, true),
	]


func _pick_from_pool(phase: int, friendly: bool) -> WarriorPoolEntry:
	## Picks a weighted random entry eligible for the current phase and faction.
	var eligible: Array[WarriorPoolEntry] = []
	var total_weight := 0.0
	for entry in _pool:
		if entry.min_phase > phase:
			continue
		if friendly and entry.hostile_only:
			continue
		eligible.append(entry)
		total_weight += entry.weight

	if eligible.is_empty():
		return null

	var roll := randf() * total_weight
	var cumulative := 0.0
	for entry in eligible:
		cumulative += entry.weight
		if roll <= cumulative:
			return entry
	return eligible.back()


## ── Spawn rate scaling ──────────────────────────────────────────────────────

func _get_hostile_interval(phase: int) -> float:
	## Hostile spawn rate escalates with phase. Faster at higher phases.
	var t := float(phase - 1) / float(RunManager.THREAT_PHASE_MAX - 1)
	return maxf(lerpf(base_hostile_interval, min_spawn_interval, t), min_spawn_interval)


func _get_friendly_interval(phase: int) -> float:
	var interval := maxf(lerpf(base_friendly_interval, min_spawn_interval * 1.5, float(phase - 1) / 19.0), min_spawn_interval * 1.5)
	# Apply Faster Muster army upgrade.
	if SaveManager.is_army_upgrade_unlocked("faster_muster"):
		var upgrade := ArmyUpgradeRegistry.get_upgrade("faster_muster")
		if upgrade:
			interval *= (1.0 - upgrade.effect_value)
	return interval


## ── Helpers ─────────────────────────────────────────────────────────────────

func _get_markers(group_name: String) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for node in get_tree().get_nodes_in_group(group_name):
		if node is Node3D:
			result.append(node)
	return result
