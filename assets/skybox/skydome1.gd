extends Node3D

@export var rotation_speed: float = 0.05  # Adjust speed if needed

func _process(delta: float) -> void:
	rotate_y(rotation_speed * delta)
