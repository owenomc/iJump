extends Node

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Check for F11 key press to toggle fullscreen
	if Input.is_action_just_pressed("toggle_fullscreen"):
		toggle_fullscreen()
	else:
		pass

func toggle_fullscreen():
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
