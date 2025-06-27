extends Control

@onready var timer = $Timer

func _ready():
	timer.start(2.0)

func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://loadingScreens/SplashGameTitle.tscn")
