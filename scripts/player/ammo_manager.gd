class_name AmmoManager
extends RefCounted
## Manages ammo types, reserves, magazine state, and type switching.
## Owned by Weapon. Will integrate with RunManager.carried_ammo in Phase 2.

## ── Signals ──────────────────────────────────────────────────────────────────

signal ammo_type_changed(ammo_type: AmmoType)

## ── State ────────────────────────────────────────────────────────────────────

var available_types: Array[AmmoType] = []
var current_index: int = 0
var magazine: int = 5       ## Rounds currently in magazine
var reserve: int = 20       ## Reserve rounds for the active ammo type
var reserves: Dictionary = {}  ## { "standard": 20, "armor_piercing": 5, ... }
var magazine_size: int = 5  ## Max magazine capacity (set by weapon)


## ── Init ─────────────────────────────────────────────────────────────────────

func load_types(mag_size: int) -> void:
	magazine_size = mag_size

	if available_types.is_empty():
		var ammo_paths := [
			"res://data/ammo/standard.tres",
			"res://data/ammo/armor_piercing.tres",
			"res://data/ammo/high_damage.tres",
			"res://data/ammo/shock.tres",
			"res://data/ammo/golden.tres",
		]
		for path in ammo_paths:
			var res := load(path)
			if res is AmmoType:
				available_types.append(res)

	## TEST: remove when ammo economy is implemented
	# Initialize reserves — give some of each for testing
	# (In production, this comes from RunManager.carried_ammo)
	if reserves.is_empty():
		for ammo in available_types:
			reserves[ammo.ammo_id] = 20

	# Set initial magazine ammo to current type
	if available_types.size() > 0:
		current_index = 0
		reserve = reserves.get(get_current_type().ammo_id, 0)


## ── Queries ─────────────────────────────────────────────────────────────────

func get_current_type() -> AmmoType:
	if available_types.is_empty():
		return null
	return available_types[current_index]


func can_reload() -> bool:
	return magazine < magazine_size and reserve > 0


func has_ammo() -> bool:
	return magazine > 0


## ── Magazine operations ─────────────────────────────────────────────────────

func consume_round() -> void:
	## Call when a shot is fired. Decrements magazine.
	magazine -= 1


func do_reload() -> void:
	## Fill magazine from reserve. Call when reload timer finishes.
	var needed := magazine_size - magazine
	var available := mini(needed, reserve)
	magazine += available
	reserve -= available
	# Sync back to reserves dict
	var current_type := get_current_type()
	if current_type:
		reserves[current_type.ammo_id] = reserve


## ── Type switching ──────────────────────────────────────────────────────────

func cycle_type(direction: int = 1) -> void:
	## Cycle to next/previous ammo type.
	if available_types.size() <= 1:
		return
	var new_index := (current_index + direction) % available_types.size()
	if new_index < 0:
		new_index += available_types.size()
	_switch_to_index(new_index)


func select_type(index: int) -> void:
	## Switch directly to ammo type by index (0-4 for keys 1-5).
	if index < 0 or index >= available_types.size():
		return
	if index == current_index:
		return
	_switch_to_index(index)


func _switch_to_index(new_index: int) -> void:
	# Return magazine rounds to old ammo reserve
	var current := get_current_type()
	if current:
		reserves[current.ammo_id] = reserve + magazine

	# Switch
	current_index = new_index
	magazine = 0  # Must reload with new ammo type

	# Load new reserve
	var new_type := get_current_type()
	reserve = reserves.get(new_type.ammo_id, 0)

	ammo_type_changed.emit(new_type)


## ── Bullet configuration ────────────────────────────────────────────────────

func configure_bullet(bullet: Bullet, base_muzzle_velocity: float, base_gravity: float) -> void:
	## Apply current ammo type properties to a bullet instance.
	var ammo := get_current_type()
	if ammo:
		bullet.damage = ammo.damage
		bullet.muzzle_velocity = base_muzzle_velocity * ammo.velocity_multiplier
		bullet.bullet_gravity = base_gravity * ammo.gravity_multiplier
		bullet.penetration = ammo.penetration
		bullet.is_shock = ammo.is_shock
		bullet.stun_duration = ammo.stun_duration
		bullet.tracer_color = ammo.tracer_color
		bullet.tracer_emission = ammo.tracer_emission
		bullet.ammo_type = ammo
	else:
		bullet.muzzle_velocity = base_muzzle_velocity
		bullet.bullet_gravity = base_gravity
