extends Node

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(_delta):
	if Input.is_action_just_pressed("menu"):
		get_tree().change_scene_to_file("res://menu_ui/menu_manager.tscn")

func _on_button_main_pressed() -> void:
	$button_sound.play()
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	add_child(timer)
	timer.start()
	await timer.timeout
	get_tree().change_scene_to_file('res://menu_ui/main.tscn')

func _on_button_back_pressed():
	$button_sound.play()
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	add_child(timer)
	timer.start()
	await timer.timeout
	get_tree().change_scene_to_file('res://levels/Map/Map.tscn')

func _on_button_settings_pressed() -> void:
	$button_sound.play()
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	add_child(timer)
	timer.start()
	await timer.timeout
	get_tree().change_scene_to_file('res://menu_ui/settings.tscn')
