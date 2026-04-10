class_name WarriorBase
extends CharacterBody3D
## Base class for all medieval warriors (friendly and hostile).
## Uses NavigationAgent3D for pathfinding. State machine driven by CombatManager pairing.

## ── Enums ────────────────────────────────────────────────────────────────────

enum Faction { FRIENDLY, HOSTILE }
enum State { ADVANCING, PATROL, FOCUSING, ATTACKING, IDLE, DEAD }

## ── Exports ──────────────────────────────────────────────────────────────────

@export var faction: Faction = Faction.HOSTILE
@export var max_hp: int = 100
@export var armor: int = 0           ## Flat damage reduction on body shots
@export var move_speed: float = 3.5
@export var castle_damage: int = 10  ## Damage dealt to castle on arrival (hostile only)
@export var base_score: int = 20     ## Score awarded to player for killing this warrior
@export var hit_chance: float = 0.6  ## Probability of landing a melee hit
@export var melee_damage: int = 25   ## Damage per melee hit to opponent
@export var attack_interval: float = 0.8  ## Seconds between attack rolls
@export var min_phase: int = 1       ## Earliest phase this type can spawn

## ── Headshot ────────────────────────────────────────────────────────────────

@export var headshot_y_offset: float = 1.6  ## Head height relative to origin
@export var headshot_radius: float = 0.25   ## Radius of head hitbox

## ── Patrol ──────────────────────────────────────────────────────────────────

const PATROL_RADIUS: float = 15.0
const PATROL_WAIT_MIN: float = 1.0
const PATROL_WAIT_MAX: float = 3.0

## ── State ────────────────────────────────────────────────────────────────────

var state: State = State.ADVANCING
var hp: int = 100
var advance_target: Vector3 = Vector3.ZERO  ## Set by spawner
var paired_target: Node3D = null
var _attack_timer: float = 0.0
var _idle_timer: float = 0.0
var _patrol_wait_timer: float = 0.0
var _patrol_center: Vector3 = Vector3.ZERO

## ── Nodes ────────────────────────────────────────────────────────────────────

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D


## ── Lifecycle ───────────────────────────────────────────────────────────────

func _ready() -> void:
	hp = max_hp
	_patrol_center = advance_target

	# Add to faction group for CombatManager lookup.
	if faction == Faction.FRIENDLY:
		add_to_group("warrior_friendly")
	else:
		add_to_group("warrior_hostile")
	add_to_group("warrior")

	# Navigation setup
	nav_agent.path_desired_distance = 1.5
	nav_agent.target_desired_distance = 1.5
	nav_agent.max_speed = move_speed

	# Apply army upgrade bonuses to friendlies.
	if faction == Faction.FRIENDLY:
		_apply_army_upgrades()

	_set_nav_target(advance_target)


func _physics_process(delta: float) -> void:
	match state:
		State.ADVANCING:
			_process_advancing(delta)
		State.PATROL:
			_process_patrol(delta)
		State.FOCUSING:
			_process_focusing(delta)
		State.ATTACKING:
			_process_attacking(delta)
		State.IDLE:
			_process_idle(delta)
		State.DEAD:
			pass


## ── State: ADVANCING ────────────────────────────────────────────────────────

func _process_advancing(delta: float) -> void:
	_move_along_nav(delta)

	if nav_agent.is_navigation_finished():
		if faction == Faction.HOSTILE:
			_arrive_at_castle()
		else:
			_patrol_center = global_position
			_pick_patrol_point()
			_set_state(State.PATROL)


## ── State: PATROL (friendly only) ──────────────────────────────────────────

func _process_patrol(delta: float) -> void:
	if _patrol_wait_timer > 0.0:
		_patrol_wait_timer -= delta
		return

	_move_along_nav(delta)

	if nav_agent.is_navigation_finished():
		_patrol_wait_timer = randf_range(PATROL_WAIT_MIN, PATROL_WAIT_MAX)
		_pick_patrol_point()


func _pick_patrol_point() -> void:
	var offset := Vector3(
		randf_range(-PATROL_RADIUS, PATROL_RADIUS),
		0.0,
		randf_range(-PATROL_RADIUS, PATROL_RADIUS),
	)
	_set_nav_target(_patrol_center + offset)


## ── State: FOCUSING ─────────────────────────────────────────────────────────

func _process_focusing(delta: float) -> void:
	if not _is_target_valid():
		_on_target_lost()
		return

	# Move toward paired target.
	_set_nav_target(paired_target.global_position)
	_move_along_nav(delta)

	# Close enough to start fighting.
	var dist := global_position.distance_to(paired_target.global_position)
	if dist < 2.5:
		_attack_timer = attack_interval
		_set_state(State.ATTACKING)


## ── State: ATTACKING ────────────────────────────────────────────────────────

func _process_attacking(delta: float) -> void:
	if not _is_target_valid():
		_on_target_lost()
		return

	# Face opponent.
	var dir := (paired_target.global_position - global_position).normalized()
	if dir.length_squared() > 0.001:
		var look_pos := global_position + Vector3(dir.x, 0.0, dir.z)
		look_at(look_pos, Vector3.UP)

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = attack_interval
		_roll_attack()


func _roll_attack() -> void:
	if randf() < hit_chance and _is_target_valid():
		paired_target.take_melee_damage(melee_damage)


## ── State: IDLE ─────────────────────────────────────────────────────────────

func _process_idle(delta: float) -> void:
	_idle_timer -= delta
	if _idle_timer <= 0.0:
		if faction == Faction.FRIENDLY:
			_patrol_center = global_position
			_pick_patrol_point()
			_set_state(State.PATROL)
		else:
			_set_nav_target(advance_target)
			_set_state(State.ADVANCING)


## ── Pairing (called by CombatManager) ──────────────────────────────────────

func is_pairable() -> bool:
	if state == State.DEAD:
		return false
	if paired_target != null:
		return false
	return state in [State.ADVANCING, State.PATROL, State.IDLE]


func set_paired_target(target: Node3D) -> void:
	paired_target = target
	if target:
		_set_state(State.FOCUSING)


func _on_target_lost() -> void:
	paired_target = null
	_idle_timer = randf_range(0.3, 0.8)
	_set_state(State.IDLE)


func _is_target_valid() -> bool:
	return is_instance_valid(paired_target) and paired_target.state != State.DEAD


## ── Castle arrival (hostile) ────────────────────────────────────────────────

func _arrive_at_castle() -> void:
	RunManager.castle_take_damage(castle_damage)
	_die(false)


## ── Damage ──────────────────────────────────────────────────────────────────

func take_melee_damage(amount: int) -> void:
	## Damage from another warrior's melee attack. Armor applies.
	var final_damage := maxi(amount - armor, 1)
	hp -= final_damage
	if hp <= 0:
		_die(false)


func on_bullet_hit(bullet: Node, collision: KinematicCollision3D) -> void:
	## Called by player's bullet. Headshot bypasses armor.
	RunManager.record_shot_hit()
	var hit_pos := collision.get_position()
	var headshot := _check_headshot(hit_pos)
	var damage: int = bullet.damage

	if not headshot:
		damage = maxi(damage - armor, 1)

	hp -= damage
	if hp <= 0:
		_die_from_player(headshot)


func _check_headshot(hit_pos: Vector3) -> bool:
	var head_pos := global_position + Vector3.UP * headshot_y_offset
	return hit_pos.distance_to(head_pos) <= headshot_radius


## ── Death ───────────────────────────────────────────────────────────────────

func _die_from_player(headshot: bool) -> void:
	## Killed by the player's bullet.
	if faction == Faction.HOSTILE:
		RunManager.record_kill_with_score(self, headshot, base_score)
	else:
		RunManager.record_friendly_kill(Scoring.FRIENDLY_KILL_PENALTY)
	_die(true)


func _die(from_player: bool) -> void:
	_set_state(State.DEAD)

	# Notify paired target that this warrior is gone.
	if paired_target and is_instance_valid(paired_target):
		if paired_target.paired_target == self:
			paired_target._on_target_lost()

	paired_target = null

	# Remove from groups so CombatManager stops considering us.
	if is_in_group("warrior_friendly"):
		remove_from_group("warrior_friendly")
	if is_in_group("warrior_hostile"):
		remove_from_group("warrior_hostile")
	remove_from_group("warrior")

	# TODO: Play death animation, then queue_free after delay.
	# For now, just remove after a short delay.
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(queue_free)


## ── Navigation helpers ──────────────────────────────────────────────────────

func _set_nav_target(target: Vector3) -> void:
	nav_agent.target_position = target


func _move_along_nav(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		return

	var next_pos := nav_agent.get_next_path_position()
	var dir := (next_pos - global_position).normalized()
	dir.y = 0.0

	velocity = dir * move_speed
	velocity.y -= 9.8 * delta  # Gravity

	if dir.length_squared() > 0.001:
		var look_pos := global_position + dir
		look_at(look_pos, Vector3.UP)

	move_and_slide()


## ── Army upgrades (friendly only) ──────────────────────────────────────────

func _apply_army_upgrades() -> void:
	if SaveManager.is_army_upgrade_unlocked("champion_kill"):
		var upgrade := ArmyUpgradeRegistry.get_upgrade("champion_kill")
		if upgrade:
			max_hp = int(max_hp * (1.0 + upgrade.effect_value))
			hp = max_hp

	if SaveManager.is_army_upgrade_unlocked("battle_training"):
		var upgrade := ArmyUpgradeRegistry.get_upgrade("battle_training")
		if upgrade:
			melee_damage = int(melee_damage * (1.0 + upgrade.effect_value))
			hit_chance = minf(hit_chance * (1.0 + upgrade.effect_value), 0.95)


## ── State helpers ───────────────────────────────────────────────────────────

func _set_state(new_state: State) -> void:
	state = new_state
