extends CharacterBody2D
## Phase 1 player: WASD / arrow-key movement, camera follows.
##
## Movement reads keys directly (instead of an Input Map) so this scaffold
## runs without any extra project setup. Later phases can move these to
## named Input Map actions without changing how the player feels.

@export var speed: float = 220.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	# Placeholder art: a plain coloured box until real sprites arrive.
	# Only generated when no texture has been assigned in the editor.
	if sprite.texture == null:
		var image := Image.create(32, 48, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.35, 0.65, 1.0))
		sprite.texture = ImageTexture.create_from_image(image)


func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0

	velocity = direction.normalized() * speed
	move_and_slide()

	if velocity.x < 0.0:
		sprite.flip_h = true
	elif velocity.x > 0.0:
		sprite.flip_h = false
