extends Node3D

@onready var paused_menu := $UI/PausedMenu

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false
	paused_menu.visible = false

func _unhandled_input(event):
	if event.is_action_pressed("menu"):
		_toggle_pause_menu()

func _toggle_pause_menu():
	var pausing: bool = !paused_menu.visible
	paused_menu.visible = pausing
	get_tree().paused = pausing
	_update_mouse_mode(pausing)

func _update_mouse_mode(paused: bool):
	if paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
