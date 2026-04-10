class_name CastleWall
extends Area3D
## Castle wall trigger zone. Placed along the castle perimeter.
## When a hostile warrior enters, it deals castle_damage and dies.
## Warrior's _arrive_at_castle() already handles this, but this is a safety net
## for warriors that reach the wall through non-nav means (bombardiers, edge cases).

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is WarriorBase and body.faction == WarriorBase.Faction.HOSTILE:
		if body.state != WarriorBase.State.DEAD:
			RunManager.castle_take_damage(body.castle_damage)
			body._die(false)
