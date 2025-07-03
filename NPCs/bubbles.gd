extends Node3D

# === NPC VISUALS & ANIMATIONS ===
@onready var mesh := $Skeleton_Minion
@onready var anim_player := $Skeleton_Minion/AnimationPlayer

func _ready():
	anim_player.play("Sit_Floor_Idle")
