class_name VoxelSourcePalette
extends RefCounted
## The 6 canonical source colors used in MagicaVoxel authoring.
## Every voxel model must paint with ONLY these colors — nothing else.
##
## ── Grayscale (permanent, never change at runtime) ─────────────────────────
## These 4 grays carry the FORM of the world. They're constant across every
## palette unlock — a palette swap only re-colors the gameplay signals (good /
## bad / accent / filler), never the structural grays.
##
## ── Primary / Secondary (markers, rewritten by the shader) ─────────────────
## PRIMARY and SECONDARY are intentionally ugly magenta placeholders. The voxel
## shader detects these source colors per vertex and replaces them with the
## appropriate palette slot colors based on the mesh's VoxelMeshType:
##   mesh_type = GOOD   → PRIMARY → good,   SECONDARY → good_muted
##   mesh_type = BAD    → PRIMARY → bad,    SECONDARY → bad_muted
##   mesh_type = ACCENT → PRIMARY → accent, SECONDARY → accent_muted
##   mesh_type = FILLER → PRIMARY → filler, SECONDARY → filler_muted
##
## If you see magenta in-game, an artist painted with a color that isn't in
## this palette. Fix the .vox file.

## ── Grayscale constants ────────────────────────────────────────────────────
const GS_LIGHT     := Color(0.910, 0.910, 0.910)  # #E8E8E8 — sky, distant geo, bright highlights
const GS_MID_LIGHT := Color(0.565, 0.565, 0.565)  # #909090 — castle stone, armor highlights
const GS_MID_DARK  := Color(0.314, 0.314, 0.314)  # #505050 — rocks, ground, shadows
const GS_DARK      := Color(0.102, 0.102, 0.102)  # #1A1A1A — iron, deep shadows, rifle body

## ── Markers (rewritten by shader via mesh_type) ────────────────────────────
const PRIMARY   := Color(1.0, 0.0, 1.0)   # #FF00FF — punctuated (tabard trim, faction plume)
const SECONDARY := Color(0.5, 0.0, 0.5)   # #800080 — ambient (tabard bulk, enemy body tint)
