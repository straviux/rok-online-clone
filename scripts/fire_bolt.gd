extends Area2D
## Phase 3 Fire Bolt projectile: flies toward its target, tracking it
## as it moves. If the target dies or becomes invalid first, it fizzles.

@export var speed: float = 450.0

var target: Node = null
var damage: int = 15


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target) or target.dead:
		queue_free()
		return
	var to_target: Vector2 = target.global_position - global_position
	if to_target.length() < 20.0:
		target.take_damage(damage)
		queue_free()
		return
	position += to_target.normalized() * speed * delta
