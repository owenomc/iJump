extends Node

const SAVE_PATH_TEMPLATE := "user://save_slot_{0}.save"

var save_data := {
	"player_position": Vector3.ZERO,
	"settings": {
		"fullscreen": 0,
		"vsync": 0,
		"max_fps": 0
	}
}

func save(slot: int):
	var file = FileAccess.open(SAVE_PATH_TEMPLATE.format([slot]), FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("Saved to slot %d" % slot)
	else:
		print("Failed to save slot %d" % slot)

func load(slot: int) -> bool:
	var path = SAVE_PATH_TEMPLATE.format([slot])
	if not FileAccess.file_exists(path):
		print("No save file in slot %d" % slot)
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		save_data = file.get_var()
		file.close()
		print("Loaded slot %d" % slot)
		return true
	return false
