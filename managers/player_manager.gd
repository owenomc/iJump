extends Node

# Holds the current player node instance
var current_player: Node = null

# Holds the saved spawn position (set when player sleeps)
var current_spawn_position: Vector3 = Vector3.ZERO

# Register the current player instance
func set_current_player(player_node: Node) -> void:
	current_player = player_node
	print("Current player set:", current_player)

# Update spawn position (called when player sleeps on bed)
func set_spawn(pos: Vector3) -> void:
	current_spawn_position = pos
	print("Spawn set to:", current_spawn_position)

# Teleport current player to the saved spawn position
func teleport_to_spawn():
	if current_player != null:
		if current_spawn_position != Vector3.ZERO:
			current_player.global_position = current_spawn_position
			print("Teleported player to spawn:", current_spawn_position)
		else:
			current_player.global_position = Vector3.ZERO
			print("Teleported player to origin (spawn not set)")
	else:
		print("No current player to teleport")
