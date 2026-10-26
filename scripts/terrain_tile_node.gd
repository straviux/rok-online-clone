extends Sprite2D
## A Sprite2D that draws one TerrainSprites tile by name (bush, rock,
## flower, fence, mushroom, stump, stepping stone). Used for world
## decor and for rocks (which keep their StaticBody collision).

@export var tile_name: String = ""


func _ready() -> void:
	if tile_name != "":
		texture = TerrainSprites.get_texture(tile_name)
