class_name AmmoType
extends Resource
## Defines properties for a single ammo type.
## Saved as .tres files in res://data/ammo/.

@export var ammo_name: String = "Standard"
@export var ammo_id: String = "standard"  ## Unique key for save/inventory

@export_group("Ballistics")
@export var damage: float = 100.0
@export var velocity_multiplier: float = 1.0  ## Multiplied with weapon muzzle_velocity
@export var gravity_multiplier: float = 1.0   ## Multiplied with weapon bullet_gravity
@export var penetration: bool = false          ## Ignores enemy armor

@export_group("Non-Lethal")
@export var is_shock: bool = false       ## Non-lethal stun round
@export var stun_duration: float = 4.0   ## Seconds target is stunned

@export_group("Visuals")
@export var tracer_color: Color = Color(1.0, 1.0, 1.0)  ## Bullet trail color
@export var tracer_emission: float = 2.0  ## Emission energy for glow

@export_group("Economy")
@export var cost_per_round: int = 1       ## Credits to buy one round
@export var unlock_level: int = 0         ## Progression gate (0 = always available)
