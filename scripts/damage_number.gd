extends Label
## Floating damage number: rises, fades out, then frees itself.
## Call setup_damage() right after adding it to the current scene.

var _base_color: Color = Color.WHITE
var _life: float = 0.8


func _ready() -> void:
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func setup_damage(text_value: String, color_value: Color) -> void:
	text = text_value
	_base_color = color_value
	modulate = color_value
	_life = 0.8


func _process(delta: float) -> void:
	_life -= delta
	position.y -= 40.0 * delta
	if _life > 0.0:
		modulate = Color(_base_color.r, _base_color.g, _base_color.b, _life / 0.8)
	else:
		queue_free()
