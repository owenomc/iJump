extends Control

@onready var fullscreen_dropdown = $Control/MarginContainer/VBoxContainer/HBoxContainer4/CHANGER/FullscreenDropdown
@onready var vsync_dropdown = $Control/MarginContainer/VBoxContainer/HBoxContainer4/CHANGER/VSyncDropdown
@onready var max_fps_dropdown = $Control/MarginContainer/VBoxContainer/HBoxContainer4/CHANGER/MaxFPSDropdown
@onready var audio_volume_slider = $Control/MarginContainer/VBoxContainer/HBoxContainer4/CHANGER/AudioVolumeSlider

var config := ConfigFile.new()
const CONFIG_PATH := "user://settings.cfg"

var fps_limits := [60, 120, 144, 240, 360]

func _ready():

	fullscreen_dropdown.clear()
	fullscreen_dropdown.add_item("ON")
	fullscreen_dropdown.add_item("OFF")

	vsync_dropdown.clear()
	vsync_dropdown.add_item("ON")
	vsync_dropdown.add_item("OFF")

	max_fps_dropdown.clear()
	for fps in fps_limits:
		max_fps_dropdown.add_item(str(fps))

	load_settings()

func load_settings():
	if config.load(CONFIG_PATH) == OK:
		var full_index = config.get_value("video", "fullscreen", 0)
		var vsync_index = config.get_value("video", "vsync", 0)
		var fps_index = config.get_value("video", "max_fps", 0)
		var volume = config.get_value("audio", "music_volume", 100)

		fullscreen_dropdown.select(full_index)
		vsync_dropdown.select(vsync_index)
		max_fps_dropdown.select(fps_index)
		audio_volume_slider.value = volume

		apply_fullscreen_setting(full_index)
		apply_vsync_setting(vsync_index)
		apply_frame_cap_setting(fps_index)
		apply_music_volume(volume)

func save_setting(section: String, key: String, value):
	config.set_value(section, key, value)
	config.save(CONFIG_PATH)

# --- Dropdown signal handlers ---
func _on_fullscreen_dropdown_item_selected(index: int) -> void:
	save_setting("video", "fullscreen", index)
	$button_sound.play()

func _on_v_sync_dropdown_item_selected(index: int) -> void:
	save_setting("video", "vsync", index)
	apply_vsync_setting(index)
	$button_sound.play()

func _on_max_fps_dropdown_item_selected(index: int) -> void:
	save_setting("video", "max_fps", index)
	apply_frame_cap_setting(index)
	$button_sound.play()

# --- Music volume slider handler ---
func _on_music_volume_slider_value_changed(value: float) -> void:
	save_setting("audio", "music_volume", value)
	apply_music_volume(value)

# --- Apply Settings ---
func apply_fullscreen_setting(index: int):
	if index == 0:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

func apply_vsync_setting(index: int):
	var vsync_mode = DisplayServer.VSYNC_ENABLED if index == 0 else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(vsync_mode)

func apply_frame_cap_setting(index: int):
	if index >= 0 and index < fps_limits.size():
		Engine.max_fps = fps_limits[index]
	else:
		Engine.max_fps = 0 # Unlimited fallback

func apply_music_volume(value: float):
	var volume_db = linear_to_db(value / 100.0)
	AudioManager.background_audio.volume_db = volume_db

# --- Reset ---
func _on_reset_button_pressed() -> void:
	fullscreen_dropdown.select(0)
	vsync_dropdown.select(0)
	max_fps_dropdown.select(0)
	audio_volume_slider.value = 100
	_on_apply_button_pressed()

# --- Back ---
func _on_back_button_pressed() -> void:
	$button_sound.play()
	await _play_delay()
	get_tree().change_scene_to_file("res://menu_ui/menu_manager.tscn")

# --- Apply button logic ---
func _on_apply_button_pressed() -> void:
	$button_sound.play()

	var full_index = fullscreen_dropdown.get_selected_id()
	var vsync_index = vsync_dropdown.get_selected_id()
	var fps_index = max_fps_dropdown.get_selected_id()
	var volume = audio_volume_slider.value

	save_setting("video", "fullscreen", full_index)
	save_setting("video", "vsync", vsync_index)
	save_setting("video", "max_fps", fps_index)
	save_setting("audio", "music_volume", volume)

	apply_fullscreen_setting(full_index)
	apply_vsync_setting(vsync_index)
	apply_frame_cap_setting(fps_index)
	apply_music_volume(volume)

	await _play_delay()

# --- Button delay helper ---
func _play_delay() -> void:
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	add_child(timer)
	timer.start()
	await timer.timeout
