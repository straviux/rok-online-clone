extends Area2D
## Phase 2 drop: a gold pickup left by a dead monster.
## Walk over it to collect it into GameManager.gold (shown in the HUD).

@export var amount: int = 3


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		GameManager.gold += amount
		queue_free()
