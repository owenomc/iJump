extends CanvasLayer

@onready var rect := $FadeOverlay
@onready var label := $SleepLabel

func _ready():
	# Start with both transparent
	rect.modulate.a = 0
	label.modulate.a = 0

	# Fade in both
	var tween = create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, 1.5)
	tween.tween_property(label, "modulate:a", 1.0, 1.5)
	await tween.finished

	await get_tree().create_timer(1.0).timeout  # Simulate "sleep"

	# Fade out both
	tween = create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, .25)
	tween.tween_property(label, "modulate:a", 0.0, .25)
	await tween.finished

	queue_free()
