extends Interactable
## Ammo Crate station — opens ammo loadout UI.

signal loadout_requested


func interact(player: CharacterBody3D) -> void:
	loadout_requested.emit()


func get_interact_prompt() -> String:
	return "[E] Ammo Crate"
