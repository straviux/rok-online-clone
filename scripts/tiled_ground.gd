extends Sprite2D
## Builds a ground texture at runtime by tiling 32x32 TerrainSprites
## tiles across the whole map area. tile_name2/3 are optional variants
## picked in a deterministic pattern, so the floor is not one flat
## repeating tile. Replaces the old flat-colour ground ColorRects.
## The sprite is centered, matching the old ground's -w/2..w/2 span.

@export var tile_name: String = "grass"
@export var tile_name2: String = ""
@export var tile_name3: String = ""
@export var ground_width: int = 1600
@export var ground_height: int = 900


func _ready() -> void:
	var tiles: Array[Image] = []
	for tile: String in [tile_name, tile_name2, tile_name3]:
		if tile != "":
			var img: Image = TerrainSprites.get_image(tile)
			if img != null:
				tiles.append(img)
	if tiles.is_empty():
		return
	var ground := Image.create(ground_width, ground_height, false, Image.FORMAT_RGBA8)
	var y: int = 0
	while y < ground_height:
		var x: int = 0
		while x < ground_width:
			var tile: Image = tiles[(x * 7 + y * 13) % tiles.size()]
			ground.blit_rect(tile, Rect2i(0, 0, 32, 32), Vector2i(x, y))
			x += 32
		y += 32
	texture = ImageTexture.create_from_image(ground)
