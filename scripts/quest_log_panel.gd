extends CanvasLayer
## Phase 5 quest log: press Q to open/close. One row per quest, in
## chain order, showing its state and objective progress, for
## example "Slimes: 3/5". Esc (handled centrally in hud.gd,
## frontmost panel only) or the Close button closes the panel.

@onready var quest_box: VBoxContainer = $Panel/QuestBox


func _ready() -> void:
	add_to_group("quest_log_panel")
	visible = false
	($Panel/CloseButton as Button).pressed.connect(_on_close_pressed)


func _on_close_pressed() -> void:
	visible = false


func _input(event: InputEvent) -> void:
	# Esc is handled centrally in hud.gd (frontmost panel only), so
	# this panel must not close itself on Esc too.
	if event is InputEventKey:
		if event.keycode == KEY_Q and event.pressed and not event.echo:
			visible = not visible
			if visible:
				refresh()


func refresh() -> void:
	for child: Node in quest_box.get_children():
		quest_box.remove_child(child)
		child.free()
	for quest_id: String in GameManager.quest_order:
		var quest: Dictionary = GameManager.quests[quest_id]
		var data: QuestData = quest["data"]
		var status_text: String = ""
		match quest["state"]:
			"available":
				status_text = "Available — talk to the Elder in town"
			"active":
				status_text = "%s: %d/%d" % [data.target_label, quest["progress"], data.amount]
			"done":
				status_text = "Complete"
			_:
				status_text = "Locked — finish the earlier quest first"
		var label := Label.new()
		label.text = "%s\n  %s — %s" % [data.quest_name, data.description, status_text]
		quest_box.add_child(label)
