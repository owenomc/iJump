extends Node

@onready var background_audio := AudioStreamPlayer.new()
var audio_stream: AudioStream = preload("res://assets/music/Mixkit/mixkit-classical-6-713.mp3")

func _ready():
	background_audio.stream = audio_stream
	background_audio.bus = "Master"
	add_child(background_audio)
	background_audio.play()

func toggle_audio(on: bool):
	if on:
		print("Audio On")
		if not background_audio.is_playing():
			background_audio.play()
	else:
		print("Audio Off")
		if background_audio.is_playing():
			background_audio.stop()

func _on_background_music_finished():
	print("Background Audio Off")
	background_audio.play()
