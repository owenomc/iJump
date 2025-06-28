extends Area3D

#Player
@onready var player := $Player
# Holds the saved spawn position (set when player sleeps)
var current_spawn_position: Vector3 = Vector3.ZERO
# Bed interaction
var near_bed := false
var nearby_bed_node = null

func _ready():
	# Connect the body_entered signal to the handler
	connect("body_entered", Callable(self, "_on_body_entered"))

# Teleport player to the saved spawn position
func teleport_to_spawn():
	if player != null:
		if current_spawn_position != Vector3.ZERO:
			player.global_position = current_spawn_position
		else:
			player.global_position = Vector3.ZERO
			print("Teleported player to origin (spawn not set)")
	else:
		print("no player to teleport")

func _on_bed_area_entered(_bed):
	near_bed = true
	nearby_bed_node = _bed

func _on_bed_area_exited(_bed):
	near_bed = false
	nearby_bed_node = null

# Update spawn position (called when player sleeps on bed)
func set_spawn(pos: Vector3) -> void:
	current_spawn_position = pos
	print("Spawn set to:", current_spawn_position)
