extends Node3D

@onready var player: Node3D = $Player
@onready var reset_zone: Area3D = $ResetZone

func _on_reset_zone_body_entered(body: Node3D) -> void:
	if body == player:
		player.global_position = Vector3(2, 0, -3)
		player.velocity = Vector3.ZERO  # Ensure 'velocity' exists in Player

@onready var timer_label: Label = $Player/PlayerUI/TimerLabel
@onready var game_timer: Timer = $Player/GameTimer

var elapsed_time := 0.0

func _ready():
	game_timer.wait_time = 1.0
	game_timer.timeout.connect(_on_timer_timeout)
	game_timer.start()

func _on_timer_timeout():
	elapsed_time += 1.0
	var minutes = int(elapsed_time / 60)
	var seconds = int(elapsed_time) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
