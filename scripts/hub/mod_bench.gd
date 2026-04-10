extends Interactable
## Armory station — opens mod equip/browse UI.

signal mod_requested


func interact(player: CharacterBody3D) -> void:
	mod_requested.emit()


func get_interact_prompt() -> String:
	return "[E] Armory"
