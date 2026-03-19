extends Interactable
## Deploy Board station — opens level select UI.

signal deploy_requested


func interact(player: CharacterBody3D) -> void:
	deploy_requested.emit()


func get_interact_prompt() -> String:
	return "[E] Mission Board"
