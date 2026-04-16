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
var _focusing_timer: float = 0.0
var _focusing_last_dist: float = 999.0
const FOCUSING_STUCK_TIME: float = 3.0  ## Seconds without closing distance before breaking pair

## ── Movement ────────────────────────────────────────────────────────────────

var _move_target: Vector3 = Vector3.ZERO

## ── Debug visuals ───────────────────────────────────────────────────────────

var _debug_state_sphere: MeshInstance3D
var _debug_hp_bar_bg: MeshInstance3D
var _debug_hp_bar_fill: MeshInstance3D

const STATE_COLORS := {
	State.ADVANCING: Color(0.2, 0.6, 1.0),   # Blue
	State.PATROL: Color(0.3, 0.9, 0.3),       # Green
	State.FOCUSING: Color(1.0, 0.8, 0.0),     # Yellow
	State.ATTACKING: Color(1.0, 0.2, 0.0),    # Red
	State.IDLE: Color(0.6, 0.6, 0.6),         # Gray
	State.DEAD: Color(0.1, 0.1, 0.1),         # Dark
}

const FACTION_COLORS := {
	Faction.FRIENDLY: Color(0.15, 0.55, 0.9),  # Blue
	Faction.HOSTILE: Color(0.85, 0.15, 0.15),   # Red
}


## ── Lifecycle ───────────────────────────────────────────────────────────────

func _ready() -> void:
	# Floating mode gives proper wall sliding without floor snap issues.
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	wall_min_slide_angle = 0.0  # Slide along any wall angle.
	hp = max_hp
	_patrol_center = advance_target

	# Add to faction group for CombatManager lookup.
	if faction == Faction.FRIENDLY:
		add_to_group("warrior_friendly")
	else:
		add_to_group("warrior_hostile")
	add_to_group("warrior")

	# Set initial move target.
	_move_target = advance_target

	# Apply army upgrade bonuses to friendlies.
	if faction == Faction.FRIENDLY:
		_apply_army_upgrades()

	# Color body mesh by faction.
	_apply_faction_color()

	# Debug visuals (only in debug builds).
	if OS.is_debug_build():
		_create_debug_visuals()


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

	var dist_to_target := global_position.distance_to(advance_target)
	if dist_to_target < 2.0:
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

	var dist := global_position.distance_to(_move_target)
	if dist < 2.0:
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
		return

	# Stuck detection — if not closing distance, break the pair.
	if dist < _focusing_last_dist - 0.3:
		_focusing_last_dist = dist
		_focusing_timer = 0.0
	else:
		_focusing_timer += delta
		if _focusing_timer >= FOCUSING_STUCK_TIME:
			_on_target_lost()
			if is_instance_valid(paired_target) and paired_target.has_method("_on_target_lost"):
				paired_target._on_target_lost()


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
		_focusing_timer = 0.0
		_focusing_last_dist = global_position.distance_to(target.global_position)
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
	_update_debug_hp_bar()
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
	_update_debug_hp_bar()
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


## ── Movement helpers ────────────────────────────────────────────────────────

func _set_nav_target(target: Vector3) -> void:
	_move_target = target


func _move_along_nav(delta: float) -> void:
	var to_target := _move_target - global_position
	to_target.y = 0.0

	if to_target.length_squared() < 2.0 * 2.0:
		velocity.x = 0.0
		velocity.z = 0.0
		velocity.y -= 9.8 * delta
		move_and_slide()
		return

	var desired_dir := to_target.normalized()

	# Gravity — separate step so it doesn't eat horizontal motion.
	move_and_collide(Vector3(0, -9.8 * delta * delta, 0))

	# Horizontal movement.
	var motion := Vector3(desired_dir.x, 0, desired_dir.z) * move_speed * delta

	var col := move_and_collide(motion)
	if col:
		var normal := col.get_normal()
		normal.y = 0.0
		if normal.length_squared() > 0.001:
			normal = normal.normalized()
			var slide_dir := (desired_dir - normal * desired_dir.dot(normal))
			slide_dir.y = 0.0
			if slide_dir.length_squared() > 0.001:
				slide_dir = slide_dir.normalized()
			else:
				slide_dir = Vector3(-normal.z, 0, normal.x)
				if to_target.dot(slide_dir) < 0:
					slide_dir = -slide_dir
			move_and_collide(slide_dir * move_speed * delta)

	# Face movement direction.
	if desired_dir.length_squared() > 0.001:
		look_at(global_position + Vector3(desired_dir.x, 0, desired_dir.z), Vector3.UP)


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


## ── Faction coloring ────────────────────────────────────────────────────────

func _apply_faction_color() -> void:
	var color: Color = FACTION_COLORS.get(faction, Color.WHITE)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	# Find the body mesh (direct child named "Body" per scene convention).
	var body := get_node_or_null("Body")
	if body is MeshInstance3D:
		body.material_override = mat


## ── Debug visuals ───────────────────────────────────────────────────────────

func _create_debug_visuals() -> void:
	# State sphere — floating above head, color = current state.
	_debug_state_sphere = MeshInstance3D.new()
	_debug_state_sphere.name = "DebugStateSphere"
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	_debug_state_sphere.mesh = sphere
	_debug_state_sphere.position = Vector3(0, headshot_y_offset + 0.6, 0)
	add_child(_debug_state_sphere)
	_update_debug_sphere()

	# HP bar — background (dark) + fill (green→red).
	var bar_y := headshot_y_offset + 0.3
	var bar_width := 1.0
	var bar_height := 0.08

	_debug_hp_bar_bg = MeshInstance3D.new()
	_debug_hp_bar_bg.name = "DebugHPBarBG"
	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(bar_width, bar_height)
	_debug_hp_bar_bg.mesh = bg_mesh
	_debug_hp_bar_bg.position = Vector3(0, bar_y, 0)
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.15, 0.15, 0.15, 0.8)
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bg_mat.no_depth_test = true
	_debug_hp_bar_bg.material_override = bg_mat
	add_child(_debug_hp_bar_bg)

	_debug_hp_bar_fill = MeshInstance3D.new()
	_debug_hp_bar_fill.name = "DebugHPBarFill"
	var fill_mesh := QuadMesh.new()
	fill_mesh.size = Vector2(bar_width, bar_height)
	_debug_hp_bar_fill.mesh = fill_mesh
	_debug_hp_bar_fill.position = Vector3(0, bar_y, 0)
	var fill_mat := StandardMaterial3D.new()
	fill_mat.albedo_color = FACTION_COLORS.get(faction, Color.WHITE)
	fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fill_mat.no_depth_test = true
	_debug_hp_bar_fill.material_override = fill_mat
	add_child(_debug_hp_bar_fill)


func _update_debug_sphere() -> void:
	if not _debug_state_sphere:
		return
	var color: Color = STATE_COLORS.get(state, Color.WHITE)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_debug_state_sphere.material_override = mat


func _update_debug_hp_bar() -> void:
	if not _debug_hp_bar_fill or not is_instance_valid(_debug_hp_bar_fill):
		return
	var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	var bar_width := 1.0

	# Resize the fill mesh directly instead of scaling the node.
	var fill_mesh := _debug_hp_bar_fill.mesh as QuadMesh
	fill_mesh.size.x = bar_width * ratio

	# Shift left so the bar shrinks from the right edge.
	var bar_y := _debug_hp_bar_bg.position.y
	_debug_hp_bar_fill.position = Vector3(-(bar_width * (1.0 - ratio)) * 0.5, bar_y, 0)


## ── State helpers ───────────────────────────────────────────────────────────

func _set_state(new_state: State) -> void:
	state = new_state
	_update_debug_sphere()
