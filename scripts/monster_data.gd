class_name MonsterData
extends Resource
## Data for one monster type. Balancing lives here, not in monster.gd:
## edit a .tres file in data/ to change a monster without touching code.

@export var monster_name: String = "Monster"
# Stable id used by quests ("slime", "wolf", "boss", ...), separate
# from the display name.
@export var monster_id: String = ""
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
# Phase 4 loot: one possible item drop, rolled on death.
# Empty id = no item drop. Item ids match data/items/*.tres.
@export var drop_item_id: String = ""
@export var drop_chance: float = 0.0
# A second possible drop (Phase 5: mushrooms also drop herbs).
@export var drop_item_id2: String = ""
@export var drop_chance2: float = 0.0
# Phase 5 boss special: every special_cooldown seconds, if the player
# is within special_range, the boss deals special_damage (a roar).
# Zero damage/cooldown = no special attack.
@export var special_damage: int = 0
@export var special_cooldown: float = 0.0
@export var special_range: float = 0.0
