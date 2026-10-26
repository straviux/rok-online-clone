extends Node2D
## Phase 4 NPC: a shopkeeper or a storage keeper in town.
## Phase 5 adds a quest NPC (the Elder): same E interaction, but it
## opens the dialogue panel instead of a shop/storage panel.
## Walk up to one and press E to open its panel; press E again (or Esc,
## or the panel's Close button) to close it. The panel type and the
## NPC's colour/name come from npc_type, set on the scene instance.

@export var npc_type: String = "shop"

var player_near: bool = false

@onready var color_rect: ColorRect = $Body/ColorRect
@onready var name_label: Label = $NameLabel
@onready var prompt_label: Label = $PromptLabel
@onready var interact_area: Area2D = $InteractArea


func _ready() -> void:
	if npc_type == "storage":
		name_label.text = "Storage"
		color_rect.color = Color(0.2, 0.8, 0.9, 1)
	elif npc_type == "quest":
		name_label.text = "Elder"
		color_rect.color = Color(1.0, 0.85, 0.2, 1)
	else:
		name_label.text = "Shop"
		color_rect.color = Color(0.6, 0.3, 0.9, 1)
	prompt_label.visible = false
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_near = true
		prompt_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_near = false
		prompt_label.visible = false


func _input(event: InputEvent) -> void:
	if not player_near:
		return
	if event is InputEventKey:
		if event.keycode == KEY_E and event.pressed and not event.echo:
			var group_name: String = "shop_panel"
			if npc_type == "storage":
				group_name = "storage_panel"
			elif npc_type == "quest":
				group_name = "dialogue_panel"
			var panel: Node = get_tree().get_first_node_in_group(group_name)
			if panel != null:
				panel.visible = not panel.visible
				if panel.visible and panel.has_method("refresh"):
					panel.refresh()
