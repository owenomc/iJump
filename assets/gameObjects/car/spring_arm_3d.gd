extends SpringArm3D

@export var camera_target: NodePath
@export var follow_speed := 5.0
@export var rotate_speed := 5.0
@export var camera_offset := Vector3(0, 3, -12)

@onready var target_node := get_node_or_null(camera_target)

func _process(delta):
	if target_node == null:
		return

	# Desired position behind the car
	var desired_position = target_node.global_transform.origin + target_node.global_transform.basis * camera_offset

	# Smooth position
	global_position = global_position.lerp(desired_position, delta * follow_speed)

	# Smooth rotation to look at the car
	var look_dir = target_node.global_transform.origin - global_position
	var target_transform = Transform3D().looking_at(look_dir, Vector3.UP)
	global_transform = global_transform.interpolate_with(target_transform, delta * rotate_speed)
