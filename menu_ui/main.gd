extends Control

func _on_button_1_pressed() -> void:
	$button_sound.play()
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	add_child(timer)
	timer.start()
	await timer.timeout
	get_tree().change_scene_to_file("res://levels/Map/Map.tscn")
func _on_button_1_focus_entered() -> void:
	pass
func _on_button_1_focus_exited() -> void:
	pass

func _on_button_2_pressed() -> void:
	$button_sound.play()
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	add_child(timer)
	timer.start()
	await timer.timeout
	get_tree().quit()
func _on_button_2_focus_entered() -> void:
	pass # Replace with function body.
func _on_button_2_focus_exited() -> void:
	pass # Replace with function body.
