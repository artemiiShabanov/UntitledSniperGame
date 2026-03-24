extends Interactable
## Skill Board station — opens skill unlock UI.

signal skill_requested


func interact(player: CharacterBody3D) -> void:
	skill_requested.emit()


func get_interact_prompt() -> String:
	return "[E] Skill Board"
