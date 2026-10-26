class_name QuestData
extends Resource
## Data for one quest. Quests are given in chain order (see
## GameManager.quest_order): completing one unlocks the next.
## objective_type: "talk", "kill", "collect", or "boss" (a kill of a
## single boss monster). target_id is a monster id, an item id, or
## an NPC id, depending on the objective. target_label is the plain
## wording shown in the quest log, for example "Slimes".

@export var quest_id: String = ""
@export var quest_name: String = "Quest"
@export var description: String = ""
@export var objective_type: String = "kill"
@export var target_id: String = ""
@export var target_label: String = ""
@export var amount: int = 1
@export var reward_xp: int = 0
@export var reward_gold: int = 0
@export var reward_item_id: String = ""
