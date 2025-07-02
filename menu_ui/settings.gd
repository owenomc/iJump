extends Control

@onready var fullscreen_dropdown = $Control/MarginContainer/VBoxContainer/HBoxContainer4/CHANGER/FullscreenDropdown
@onready var vsync_dropdown = $Control/MarginContainer/VBoxContainer/HBoxContainer4/CHANGER/VSyncDropdown
@onready var max_fps_dropdown = $Control/MarginContainer/VBoxContainer/HBoxContainer4/CHANGER/MaxFPSDropdown

var current_save_slot := 1  # change as needed
var fps_limits := [60, 120, 144, 240, 360]

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	fullscreen_dropdown.clear()
	fullscreen_dropdown.add_item("ON")
	fullscreen_dropdown.add_item("OFF")

	vsync_dropdown.clear()
	vsync_dropdown.add_item("ON")
	vsync_dropdown.add_item("OFF")

	max_fps_dropdown.clear()
	for fps in fps_limits:
		max_fps_dropdown.add_item(str(fps))

# === Dropdown signal handlers ===

func _on_fullscreen_dropdown_item_selected(index: int) -> void:
	apply_fullscreen_setting(index)

func _on_v_sync_dropdown_item_selected(index: int) -> void:
	apply_vsync_setting(index)

func _on_max_fps_dropdown_item_selected(index: int) -> void:
	apply_frame_cap_setting(index)

# === Apply Settings ===

func apply_fullscreen_setting(index: int):
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if index == 0 else DisplayServer.WINDOW_MODE_WINDOWED)

func apply_vsync_setting(index: int):
	var vsync_mode = DisplayServer.VSYNC_ENABLED if index == 0 else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(vsync_mode)

func apply_frame_cap_setting(index: int):
	if index >= 0 and index < fps_limits.size():
		Engine.max_fps = fps_limits[index]
	else:
		Engine.max_fps = 0

# === Buttons ===

func _on_reset_button_pressed():
	fullscreen_dropdown.select(0)
	vsync_dropdown.select(1)
	max_fps_dropdown.select(1)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://menu_ui/main.tscn")
