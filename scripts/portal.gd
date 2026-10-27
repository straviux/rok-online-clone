extends Area2D
## A doorway between two maps.
##
## Set target_scene_path and spawn_position in the Inspector for each
## portal instance. When the player walks into the area, GameManager
## switches scenes and the destination world places the player at
## spawn_position (see world.gd).

@export var target_scene_path: String = ""
@export var spawn_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not target_scene_path.is_empty():
		SFX.play("portal")
		GameManager.travel_to(target_scene_path, spawn_position)
