class_name OpportunityData
extends Resource
## A dynamic in-run event. Kill targets within a time window for XP and army unlock.
## Each opportunity is paired 1:1 with an army upgrade.

@export var id: String = ""
@export var name: String = ""
@export var paired_army_upgrade_id: String = ""
@export var phase_range: Vector2i = Vector2i(1, 20)  ## Min/max phase this can appear
@export var duration: float = 60.0  ## Seconds to complete (0 = instant/one-shot)
@export var description: String = ""
@export var xp_reward: int = 100
