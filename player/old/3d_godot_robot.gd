extends CharacterBody3D

@export var walk_speed := 4.0
@export var run_speed := 8.0
@export var jump_velocity := 10.0
@export var gravity := 30.0
@export var mouse_sensitivity := 0.003

@onready var mesh := $Skeleton_Rogue
@onready var spring_arm := $SpringArm3D
@onready var camera := $SpringArm3D/Camera3D
@onready var anim_player: AnimationPlayer = $Skeleton_Rogue/AnimationPlayer

var yaw := 0.0
var pitch := 0.0
const PITCH_MIN := deg_to_rad(-40)
const PITCH_MAX := deg_to_rad(60)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, PITCH_MIN, PITCH_MAX)

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# Rotate the camera around the player
	spring_arm.rotation = Vector3(pitch, yaw, 0)

	# Convert input to camera-relative movement
	var input_vec = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("forward") - Input.get_action_strength("backward")
	)

	var move_dir = Vector3.ZERO
	if input_vec.length() > 0:
		var cam_basis = spring_arm.global_transform.basis
		var forward = -cam_basis.z.normalized()
		var right = cam_basis.x.normalized()
		move_dir = (right * input_vec.x + forward * input_vec.y).normalized()

		# Smoothly rotate mesh to movement direction
		var target_rot = atan2(move_dir.x, move_dir.z)
		mesh.rotation.y = lerp_angle(mesh.rotation.y, target_rot, 0.2)

	var speed = run_speed if Input.is_action_pressed("run") else walk_speed
	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed

	# Jumping and gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	move_and_slide()

	# Animation logic: always play "Run" when moving, else "Idle" or "Jump"
	if is_on_floor():
		if move_dir.length() > 0:
			play_anim("Running_A")
		else:
			play_anim("Idle")
	else:
		play_anim("Jump_Idle")

func play_anim(anim_name: String) -> void:
	if not anim_player.is_playing() or anim_player.current_animation != anim_name:
		anim_player.play(anim_name)
