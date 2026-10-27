extends Control
## Phase 6 title screen: the game's front door, and the new main scene.
## No login, no account: New Game starts fresh in town, Continue
## restores the manual save (or the autosave if that is all there is),
## Quit closes the game. Continue is disabled when no save exists at
## all, so it can never lead to a dead end.

@onready var new_game_button: Button = $Menu/NewGameButton
@onready var continue_button: Button = $Menu/ContinueButton
@onready var quit_button: Button = $Menu/QuitButton
@onready var message_label: Label = $Menu/MessageLabel


func _ready() -> void:
	# Coming here from the pause menu must never leave the game paused.
	get_tree().paused = false
	continue_button.disabled = not GameManager.has_save("manual") and not GameManager.has_save("autosave")
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_new_game_pressed() -> void:
	SFX.play("ui_click")
	GameManager.start_new_game()


func _on_continue_pressed() -> void:
	SFX.play("ui_click")
	var slot: String = "manual" if GameManager.has_save("manual") else "autosave"
	var error: String = GameManager.load_game(slot)
	if error != "":
		# The load changed nothing (it validates before applying),
		# so the player can try again or start a new game instead.
		message_label.text = error
		continue_button.disabled = not GameManager.has_save("manual") and not GameManager.has_save("autosave")


func _on_quit_pressed() -> void:
	SFX.play("ui_click")
	get_tree().quit()
