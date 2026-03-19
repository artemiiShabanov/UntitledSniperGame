class_name Interactable
extends Node3D
## Base class for anything the player can interact with.
## Extend this and override interact() and get_interact_prompt().


## Called when the player presses the interact key while looking at this.
func interact(player: CharacterBody3D) -> void:
	pass


## Text shown on the HUD when the player looks at this.
func get_interact_prompt() -> String:
	return "[E] Interact"
