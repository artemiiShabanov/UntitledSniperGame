class_name PaletteResource
extends Resource
## Defines a single color palette that themes the entire game.
## To create a new palette: duplicate an existing .tres, tweak colors, add to
## PaletteManager.palettes array.

@export var palette_name: StringName = &"Unnamed"

## ── World base (grayscale spectrum) ─────────────────────────────────────────
@export_group("World Base")
@export var bg_light: Color = Color(0.85, 0.85, 0.85)   ## Sky, distant geometry
@export var bg_mid: Color = Color(0.55, 0.55, 0.55)     ## Buildings, terrain, large surfaces
@export var fg_dark: Color = Color(0.15, 0.15, 0.15)    ## Non-interactive props, shadows

## ── Accent colors ───────────────────────────────────────────────────────────
@export_group("Accents")
@export var accent_hostile: Color = Color(0.9, 0.25, 0.2)   ## Enemies, destructible targets
@export var accent_loot: Color = Color(0.95, 0.75, 0.2)     ## Pickups, ammo, credit rewards
@export var accent_friendly: Color = Color(0.2, 0.7, 0.8)   ## NPCs, interactables, HUD, extraction

## ── State colors ────────────────────────────────────────────────────────────
@export_group("State")
@export var danger: Color = Color(1.0, 0.15, 0.15)      ## Damage flash, penalty, alert
@export var reward: Color = Color(1.0, 0.85, 0.3)       ## Credits, XP gains, success

## ── Extend here ─────────────────────────────────────────────────────────────
## Add any custom palette slots below. Reference them in your shaders/scripts
## via PaletteManager.current.your_slot_name.
##
## Example:
##   @export var scope_reticle: Color = Color(0.0, 1.0, 0.0)
##   @export var tracer: Color = Color(1.0, 0.6, 0.0)
##   @export var fog_tint: Color = Color(0.5, 0.5, 0.6)
