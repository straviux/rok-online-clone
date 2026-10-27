extends Control
## Phase 6 pause menu, opened by Esc from the HUD (hud.gd) when no
## other panel is open. The HUD's Esc handling stays single-purpose:
## panels first, pause menu second.
##
## Pausing needs care: while the tree is paused, only nodes with
## process_mode Always still receive input, so this menu sets itself
## to Always — that is what makes both its buttons clickable and its
## own Esc-to-resume work while everything else is frozen. Every exit
## path (Resume, Load, Quit to title) unpauses before changing
## anything, or the next scene would start frozen.

@onready var resume_button: Button = $Panel/Menu/ResumeButton
@onready var save_button: Button = $Panel/Menu/SaveButton
@onready var load_button: Button = $Panel/Menu/LoadButton
@onready var volume_slider: HSlider = $Panel/Menu/VolumeSlider
@onready var fullscreen_button: CheckButton = $Panel/Menu/FullscreenButton
@onready var quit_button: Button = $Panel/Menu/QuitButton
@onready var message_label: Label = $Panel/Menu/MessageLabel


func _ready() -> void:
	add_to_group("pause_menu")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_button.toggled.connect(_on_fullscreen_toggled)
	quit_button.pressed.connect(_on_quit_pressed)


func open() -> void:
	visible = true
	message_label.text = ""
	volume_slider.value = SFX.volume_percent
	fullscreen_button.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false


func _input(event: InputEvent) -> void:
	# Esc inside the pause menu resumes. This runs while paused
	# because of process_mode Always; the HUD's Esc cannot, since
	# the HUD is an ordinary pausable node.
	if visible and event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
			SFX.play("ui_click")
			close()


func _on_resume_pressed() -> void:
	SFX.play("ui_click")
	close()


func _on_save_pressed() -> void:
	SFX.play("ui_click")
	var error: String = GameManager.save_game("manual")
	message_label.text = "Game saved." if error == "" else error


func _on_load_pressed() -> void:
	SFX.play("ui_click")
	var slot: String = "manual" if GameManager.has_save("manual") else "autosave"
	if not GameManager.has_save(slot):
		message_label.text = "No save found."
		return
	# load_game unpauses before changing scenes (see game_manager.gd).
	var error: String = GameManager.load_game(slot)
	if error != "":
		message_label.text = error


func _on_volume_changed(value: float) -> void:
	SFX.set_volume(int(value))


func _on_fullscreen_toggled(pressed: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED)
	SFX.save_settings(pressed)


func _on_quit_pressed() -> void:
	SFX.play("ui_click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
