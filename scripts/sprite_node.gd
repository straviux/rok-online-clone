# A Sprite2D that draws a runtime-generated pixel-art sprite by name.
# Used for world objects (houses, trees, rocks) that have no other script:
# set sprite_name in the scene, and the texture is built on load.
extends Sprite2D

@export var sprite_name: String = ""

func _ready() -> void:
	if sprite_name != "":
		texture = SpriteData.get_texture(sprite_name)
