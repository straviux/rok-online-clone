extends Node
## Phase 6 sound-effect placeholders.
##
## There are deliberately NO audio files in the repo (the GitHub snapshot
## tool rejects binary files, and every sprite is code for the same
## reason). So this autoload is a named-hook system, not a player:
## gameplay code calls SFX.play("hit") and friends, and when real
## sounds arrive, they drop in here — one place — by giving each event
## an AudioStreamPlayer fed by a real file, without touching call sites.
##
## Valid event names (anything else is ignored, so a typo never crashes):
## "hit" (a monster takes damage), "player_hurt" (the player takes
## damage), "pickup" (gold or an item collected), "ui_click" (a title
## or pause button), "portal" (walking through a portal), "boss_roar"
## (the Dungeon Guardian's roar special).
## Volume is a plain 0-100 number, shared with the pause menu's slider
## and saved to user://settings.cfg alongside the fullscreen setting
## (applied here at startup, since this autoload runs before the title).

const SETTINGS_PATH: String = "user://settings.cfg"
const KNOWN_EVENTS: Array = ["hit", "player_hurt", "pickup", "ui_click", "portal", "boss_roar"]

var volume_percent: int = 80
var last_played: String = ""


func _ready() -> void:
	_load_settings()


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	var volume: Variant = cfg.get_value("settings", "volume", 80)
	if typeof(volume) == TYPE_INT:
		volume_percent = clampi(volume, 0, 100)
	var fullscreen: Variant = cfg.get_value("settings", "fullscreen", false)
	if typeof(fullscreen) == TYPE_BOOL and fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func save_settings(fullscreen: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "volume", volume_percent)
	cfg.set_value("settings", "fullscreen", fullscreen)
	cfg.save(SETTINGS_PATH)


func set_volume(percent: int) -> void:
	volume_percent = clampi(percent, 0, 100)
	save_settings(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)


func play(event_name: String) -> void:
	# Placeholder: record the event so a future sound pass can see
	# what fired, but play nothing. Real sounds hook in here.
	if event_name not in KNOWN_EVENTS:
		return
	last_played = event_name
