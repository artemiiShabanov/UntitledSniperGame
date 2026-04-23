class_name PaletteResource
extends Resource
## Defines a single color palette. Holds the 8 semantic gameplay-signal colors
## that change per palette unlock. Grayscale is NOT stored here — those 4
## structural tones are constants on VoxelSourcePalette (and mirrored on
## PaletteManager for convenience). Palette swaps only retune the signals.
##
## ── Naming convention ───────────────────────────────────────────────────────
## Unsuffixed name = punctuated / bright variant (active state, small areas).
## `_muted` suffix  = ambient / resting variant (large areas, background).
##
##   good         = friendly punctuated  (kill confirm, friendly trim, plume)
##   good_muted   = friendly ambient     (friendly faction body, ambient UI)
##   bad          = hostile punctuated   (damage flash, low-HP warning)
##   bad_muted    = hostile ambient      (enemy faction body)
##   accent       = attention punctuated (extraction active, victory, muzzle flash)
##   accent_muted = attention ambient    (XP label, pickup, resting loot)
##   filler       = material punctuated  (hay, warm highlight)
##   filler_muted = material ambient     (wood, leather, cloth, skin)
##
## Rule: grayscale carries form; palette carries meaning.

@export var palette_name: StringName = &"Unnamed"

@export_group("Good")
@export var good: Color = Color(0.4, 0.95, 1.0)
@export var good_muted: Color = Color(0.2, 0.7, 0.8)

@export_group("Bad")
@export var bad: Color = Color(1.0, 0.15, 0.15)
@export var bad_muted: Color = Color(0.9, 0.25, 0.2)

@export_group("Accent")
@export var accent: Color = Color(1.0, 0.85, 0.3)
@export var accent_muted: Color = Color(0.95, 0.75, 0.2)

@export_group("Filler")
@export var filler: Color = Color(0.92, 0.82, 0.6)
@export var filler_muted: Color = Color(0.5, 0.36, 0.22)
