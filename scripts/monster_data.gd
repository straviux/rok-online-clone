class_name MonsterData
extends Resource
## Data for one monster type. Balancing lives here, not in monster.gd:
## edit a .tres file in data/ to change a monster without touching code.

@export var monster_name: String = "Monster"
@export var max_hp: int = 30
@export var attack_damage: int = 5
@export var speed: float = 60.0
@export var xp: int = 10
@export var aggro_range: float = 120.0
@export var attack_range: float = 45.0
@export var attack_cooldown: float = 1.0
@export var leash_range: float = 400.0
@export var color: Color = Color(0.3, 0.9, 0.4, 1)
@export var gold_drop: int = 3
@export var respawn_time: float = 5.0
