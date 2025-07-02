extends Node

var debug_ui_scene = preload("res://managers/debug_UI.tscn")
var debug_ui_instance: Control

var gpu_label: Label
var cpu_label: Label
var fps_label: Label
var scene_label: Label

var visible_ui = false

func _ready():
	debug_ui_instance = debug_ui_scene.instantiate()
	add_child(debug_ui_instance)

	# Get nodes FROM the instance, not from self
	scene_label = debug_ui_instance.get_node("ColorRect/VBoxContainer/SceneName")
	cpu_label = debug_ui_instance.get_node("ColorRect2/VBoxContainer/Processor")
	gpu_label = debug_ui_instance.get_node("ColorRect2/VBoxContainer/GraphicsCard")
	fps_label = debug_ui_instance.get_node("ColorRect2/VBoxContainer/Frames")

	debug_ui_instance.visible = visible_ui

func _process(_delta):
	update_debug_ui_labels()

func _input(event):
	if event.is_action_pressed("ui_debug_toggle"):
		print("Toggled F1")
		visible_ui = not visible_ui
		debug_ui_instance.visible = visible_ui

func update_debug_ui_labels():
	scene_label.text = "Current Scene: " + get_tree().current_scene.name
	cpu_label.text = "CPU: " + OS.get_processor_name()
	gpu_label.text = "GPU: " + RenderingServer.get_rendering_device().get_device_name()
	fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
