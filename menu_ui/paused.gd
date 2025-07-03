extends Control

func _on_button_main_pressed() -> void:
	get_tree().change_scene_to_file("res://menu_ui/main.tscn")

func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	queue_free()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
