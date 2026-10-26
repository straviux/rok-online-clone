# A Sprite2D that draws a Laphkal building by name (see building_sprites.gd).
# Used for town houses: the building image is taller than the 220x160
# collision box, so the sprite is shifted up until its bottom lines up
# with the bottom of the collision box (roof overhangs upward, as it
# should in a top-down view).
extends Sprite2D

@export var building_name: String = ""

func _ready() -> void:
	if building_name != "":
		texture = BuildingSprites.get_texture(building_name)
		if texture != null:
			offset = Vector2(0, -(texture.get_size().y - 160.0) / 2.0)
