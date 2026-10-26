extends CanvasLayer
## Phase 5 dialogue panel: opened by pressing E near the Elder.
## It shows the first quest in the chain that is not yet done:
## an available quest can be accepted here, an active quest shows
## its progress, and a finished chain shows a completion message.
## Esc (handled centrally in hud.gd, frontmost panel only) or the
## Close button closes the panel.

var _current_quest_id: String = ""

@onready var name_label: Label = $Panel/NameLabel
@onready var text_label: Label = $Panel/TextLabel
@onready var accept_button: Button = $Panel/AcceptButton


func _ready() -> void:
	($Panel as TextureRect).texture = UISprites.get_texture("dialog_box")
	add_to_group("dialogue_panel")
	visible = false
	name_label.text = "Elder"
	accept_button.pressed.connect(_on_accept_pressed)
	($Panel/CloseButton as Button).pressed.connect(_on_close_pressed)


func _on_close_pressed() -> void:
	visible = false


func _on_accept_pressed() -> void:
	if _current_quest_id != "":
		GameManager.accept_quest(_current_quest_id)
	refresh()


func refresh() -> void:
	_current_quest_id = ""
	accept_button.visible = false
	for quest_id: String in GameManager.quest_order:
		var quest: Dictionary = GameManager.quests[quest_id]
		if quest["state"] == "done":
			continue
		var data: QuestData = quest["data"]
		if quest["state"] == "available":
			_current_quest_id = quest_id
			text_label.text = data.description + "\n\nAccept this quest?"
			accept_button.visible = true
			accept_button.text = "Accept"
		elif quest["state"] == "active":
			text_label.text = data.description + "\n\nProgress: %s: %d/%d" % [
				data.target_label,
				quest["progress"],
				data.amount,
			]
		else:
			text_label.text = "Come back later, adventurer."
		return
	text_label.text = "You have completed every quest. The town is safe, thanks to you."
