extends Node3D

@onready var sleep_prompt: Label = $PromptVBox/PromptLabel
@onready var spawn_point = $SpawnPoint
@export var sleep_ui_scene := preload("res://assets/gameObjects/bed/sleep.tscn")

var player_in_range: bool = false
var player_ref: Node = null

func _ready():
	# Connect signals from Area3D to detect player proximity
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)

	# Hide the sleep prompt initially
	sleep_prompt.visible = false

func _process(delta):
	# Check if the player is in range and pressed the E key
	if player_in_range and Input.is_action_just_pressed("interact"):
		sleep_here()

func sleep_here():
	print("Sleeping... spawn set here.")
	PlayerManager.set_spawn(spawn_point.global_position)

	var sleep_ui = sleep_ui_scene.instantiate()
	get_tree().current_scene.add_child(sleep_ui)

func _on_body_entered(body):
	if body.name == "Player":
		sleep_prompt.text = "Press [E] to Sleep"
		sleep_prompt.visible = true
		player_in_range = true
		player_ref = body
		body._on_bed_area_entered(self)

func _on_body_exited(body):
	if body.name == "Player":
		sleep_prompt.visible = false
		player_in_range = false
		player_ref = null
		body._on_bed_area_exited(self)
