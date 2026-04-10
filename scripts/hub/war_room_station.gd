extends Interactable
## War Room station — opens army upgrade display.

signal war_room_requested


func interact(player: CharacterBody3D) -> void:
	war_room_requested.emit()


func get_interact_prompt() -> String:
	return "[E] War Room"
