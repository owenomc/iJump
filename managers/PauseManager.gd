extends Node

@onready var pause_menu_scene = preload("res://menu_ui/paused.tscn")
var pause_menu_instance: Control = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	if get_tree().current_scene.scene_file_path == "res://menu_ui/main.tscn":
		return  # Don't allow pause in main menu
	if event.is_action_pressed("paused"):
		toggle_pause()

func toggle_pause() -> void:
	if get_tree().paused:
		resume_game()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		pause_game()

func pause_game() -> void:
	if not pause_menu_instance:
		pause_menu_instance = pause_menu_scene.instantiate()
		get_tree().root.add_child(pause_menu_instance)
	get_tree().paused = true

func resume_game() -> void:
	get_tree().paused = false
	if pause_menu_instance:
		pause_menu_instance.queue_free()
		pause_menu_instance = null
