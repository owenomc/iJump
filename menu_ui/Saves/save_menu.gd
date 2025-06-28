extends Control

@onready var slot_labels := [
	$VBoxContainer/HBoxContainer/Label,
	$VBoxContainer/HBoxContainer2/Label,
	$VBoxContainer/HBoxContainer3/Label,
]

func _ready():
	update_slot_labels()

func update_slot_labels():
	for i in range(3):
		var slot = i + 1
		if FileAccess.file_exists("user://save_slot_%d.save" % slot):
			var file = FileAccess.open("user://save_slot_%d.save" % slot, FileAccess.READ)
			var data = file.get_var()
			var pos: Vector3 = data.get("player_position", Vector3.ZERO)
			slot_labels[i].text = "Slot %d: (%.1f, %.1f, %.1f)" % [slot, pos.x, pos.y, pos.z]
		else:
			slot_labels[i].text = "Slot %d: Empty" % slot

# === SLOT BUTTONS ===
func _on_slot_1_load_pressed(): load_slot(1)
func _on_slot_2_load_pressed(): load_slot(2)
func _on_slot_3_load_pressed(): load_slot(3)

func load_slot(slot: int):
	if SaveManager.load(slot):
		# Store the loaded slot in a global variable
		Global.current_save_slot = slot
		get_tree().change_scene_to_file("res://levels/Map/Map.tscn")
	else:
		print("Load failed for slot %d" % slot)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://menu_ui/main.tscn")
