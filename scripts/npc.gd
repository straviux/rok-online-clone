extends Node2D
## NameLabel (in npc.tscn) is centered and sits just above the head:
## offsets -58..-38 on an 80px box, horizontal_alignment = CENTER.
## The old -70..-50 left-aligned label floated a tile above the head
## and short names started 40px left of center.
## Phase 4 NPC: a shopkeeper or a storage keeper in town.
## Phase 5 adds a quest NPC (the Elder): same E interaction, but it
## opens the dialogue panel instead of a shop/storage panel.
## Walk up to one and press E to open its panel; press E again (or Esc,
## or the panel's Close button) to close it. The panel type and the
## NPC's colour/name come from npc_type, set on the scene instance.

@export var npc_type: String = "shop"
# Villagers (SetC characters): set these on the scene instance and
# npc_type = "villager". E then shows the greeting floating above
# them instead of opening any panel.
@export var display_name: String = ""
@export var chibi_frame: String = ""
@export var greeting: String = ""

var player_near: bool = false

var _damage_number_scene: PackedScene = preload("res://scenes/ui/damage_number.tscn")

@onready var sprite: Sprite2D = $Body/Sprite2D
@onready var name_label: Label = $NameLabel
@onready var prompt_label: Label = $PromptLabel
@onready var interact_area: Area2D = $InteractArea


func _ready() -> void:
	# Chibi standing frames (finalbossblues set, via chibi_sprites.gd).
	# Frames are 32x64; offset -8 keeps the feet at the bottom of
	# the 32x48 collision box.
	sprite.offset = Vector2(0, -8)
	if chibi_frame != "":
		if display_name != "":
			name_label.text = display_name
		sprite.texture = ChibiSprites.frame_texture(chibi_frame)
	elif npc_type == "storage":
		name_label.text = "Storage"
		sprite.texture = ChibiSprites.frame_texture("storage_keeper_stand")
	elif npc_type == "quest":
		name_label.text = "Elder"
		sprite.texture = ChibiSprites.frame_texture("elder_stand")
	else:
		name_label.text = "Shop"
		sprite.texture = ChibiSprites.frame_texture("shopkeeper_stand")
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
			if npc_type == "villager":
				if greeting != "":
					var number: Node = _damage_number_scene.instantiate()
					number.position = global_position + Vector2(0, -60)
					get_tree().current_scene.add_child(number)
					number.setup_damage(greeting, Color(1, 1, 1, 1))
				return
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
