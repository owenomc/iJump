extends Control

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_button_1_pressed() -> void:
	$button_sound.play()
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	add_child(timer)
	timer.start()
	await timer.timeout
	get_tree().change_scene_to_file("res://menu_ui/Saves/SaveMenu.tscn")

func _on_button_2_pressed() -> void:
	$button_sound.play()
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	add_child(timer)
	timer.start()
	await timer.timeout
	get_tree().change_scene_to_file("res://menu_ui/settings.tscn")

func _on_button_3_pressed() -> void:
	$button_sound.play()
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	add_child(timer)
	timer.start()
	await timer.timeout
	get_tree().quit()
