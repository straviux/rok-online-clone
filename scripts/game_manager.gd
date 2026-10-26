extends Node
## Autoloaded game state (Phase 1: only map travel).
##
## Autoloads persist across scene changes, so a portal can store where the
## player should appear in the next map, change the scene, and the new
## world's script (world.gd) can pick that spawn point up in _ready().

var spawn_position: Vector2 = Vector2.ZERO
var has_spawn_position: bool = false


func travel_to(scene_path: String, spawn: Vector2) -> void:
	if scene_path.is_empty():
		return
	spawn_position = spawn
	has_spawn_position = true
	get_tree().change_scene_to_file(scene_path)
