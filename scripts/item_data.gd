class_name ItemData
extends Resource
## Data for one item. Equipment bonuses are applied by player.gd in
## recalculate_derived(); consumable healing is applied when used.
## item_type values (also stored as ints in .tres files):
## 0 weapon, 1 armor, 2 headgear, 3 accessory, 4 consumable, 5 misc.

enum ItemType { WEAPON, ARMOR, HEADGEAR, ACCESSORY, CONSUMABLE, MISC }

@export var item_id: String = ""
@export var item_name: String = "Item"
@export var description: String = ""
@export var item_type: ItemType = ItemType.MISC
@export var price: int = 0
@export var stackable: bool = false
@export var color: Color = Color(1, 1, 1, 1)
@export var attack_bonus: int = 0
@export var defence_bonus: int = 0
@export var hp_bonus: int = 0
@export var sp_bonus: int = 0
@export var heal_hp: int = 0
@export var heal_sp: int = 0


func slot_name() -> String:
	match item_type:
		ItemType.WEAPON:
			return "weapon"
		ItemType.ARMOR:
			return "armor"
		ItemType.HEADGEAR:
			return "headgear"
		ItemType.ACCESSORY:
			return "accessory"
	return ""
