extends Node3D

@onready var player: Node3D = $Player
@onready var reset_zone: Area3D = $ResetZone

func _on_reset_zone_body_entered(body: Node3D) -> void:
	if body == player:
		player.global_position = Vector3(2, 0, -3)
		player.velocity = Vector3.ZERO  # Ensure 'velocity' exists in Player
