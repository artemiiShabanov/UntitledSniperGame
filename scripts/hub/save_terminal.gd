extends Interactable
## Save Terminal station — saves the game.

signal save_completed


func interact(player: CharacterBody3D) -> void:
	SaveManager.save()
	save_completed.emit()


func get_interact_prompt() -> String:
	return "[E] Save Game"
