extends Interactable
## Palette Station — opens color palette selection UI.

signal palette_requested


func interact(player: CharacterBody3D) -> void:
	palette_requested.emit()


func get_interact_prompt() -> String:
	return "[E] Color Palettes"
