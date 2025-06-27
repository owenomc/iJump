extends Node3D

@onready var sleep_prompt: Label = $PromptVBox/PromptLabel
@onready var spawn_point = $SpawnPoint
@export var sleep_ui_scene := preload("res://player/sleep.tscn")

func sleep_here():
	print("Sleeping... spawn set here.")
	PlayerManager.set_spawn(spawn_point.global_position)

	var sleep_ui = sleep_ui_scene.instantiate()
	get_tree().current_scene.add_child(sleep_ui)

func _ready():
	# Connect signals from Area3D to detect player proximity
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)

	# Hide the sleep prompt initially
	sleep_prompt.visible = false

func _on_body_entered(body):
	# Show prompt and notify player when player enters bed area
	if body.name == "Player":
		sleep_prompt.text = "Press [E] to Sleep"
		sleep_prompt.visible = true
		body._on_bed_area_entered(self)

func _on_body_exited(body):
	# Hide prompt and notify player when player leaves bed area
	if body.name == "Player":
		sleep_prompt.visible = false
		body._on_bed_area_exited(self)
