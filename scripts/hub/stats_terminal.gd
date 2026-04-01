extends Interactable
## Stats Terminal station — opens player stats screen.

signal stats_requested


func interact(_player: CharacterBody3D) -> void:
	stats_requested.emit()


func get_interact_prompt() -> String:
	return "[E] Stats Terminal"
