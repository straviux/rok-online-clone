extends Node2D
## Shared script for town / field scenes.
##
## Each world scene contains its own Player instance (under the
## y-sorted Actors node) at a default spawn
## point. If GameManager is carrying a spawn position from a portal
## (travel_to), move the player there on load, then clear the flag so a
## fresh run from the editor still starts at the scene's default spawn.

@onready var player: CharacterBody2D = $Actors/Player


func _ready() -> void:
	if GameManager.has_spawn_position:
		player.position = GameManager.spawn_position
		GameManager.has_spawn_position = false
