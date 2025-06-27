extends Area3D

# Preload the Player scene to instantiate on respawn
var player_scene = preload("res://player/player.tscn")

func _ready():
	# Connect the body_entered signal to the handler
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	var current_player = PlayerManager.current_player
	
	# Only act if the body entering is the currently active player
	if body == current_player:
		print("Player entered reset zone, deleting old player")

		# Delete the old player node
		body.queue_free()

		# Instantiate a new player from scene
		var new_player = player_scene.instantiate()
		var root = get_tree().get_current_scene()
		root.add_child(new_player)

		# Register the new player instance in PlayerManager
		PlayerManager.set_current_player(new_player)

		# Teleport new player to saved spawn position or origin using respawn()
		var spawn_pos = PlayerManager.current_spawn_position
		if spawn_pos != Vector3.ZERO and new_player.has_method("respawn"):
			new_player.respawn(spawn_pos)
		else:
			# Fallback if no spawn or no respawn method
			new_player.global_position = Vector3.ZERO
