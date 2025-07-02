extends Control

func _on_button_3_pressed() -> void:
	$button_sound.play()
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	add_child(timer)
	timer.start()
	await timer.timeout
	print("Back Pressed")
	get_tree().change_scene_to_file("res://menu_ui/main.tscn")
