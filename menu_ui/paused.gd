extends Control

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true

func _on_button_main_pressed() -> void:
	$button_sound.play()
	await _delayed_scene_change("res://menu_ui/main.tscn")

func _on_button_back_pressed():
	$button_sound.play()
	await _delayed_scene_change("res://levels/Map/Map.tscn")

func _on_button_settings_pressed() -> void:
	$button_sound.play()
	await _delayed_scene_change("res://menu_ui/settings.tscn")

func _delayed_scene_change(scene_path: String) -> void:
	var timer := Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	add_child(timer)
	timer.start()
	await timer.timeout

	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().change_scene_to_file(scene_path)
