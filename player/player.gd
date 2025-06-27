extends CharacterBody3D

@export var walk_speed := 4.0
@export var run_speed := 8.0
@export var jump_velocity := 15.0
@export var gravity := 30.0
@export var mouse_sensitivity := 0.003

@onready var mesh := $Skeleton_Rogue
@onready var spring_arm := $SpringArm3D
@onready var camera := $SpringArm3D/Camera3D
@onready var anim_player: AnimationPlayer = $Skeleton_Rogue/AnimationPlayer
var jump_charge_bar: ProgressBar
var nearby_bed_node = null

# Jump holding
@export var max_jump_charge_time := 0.8  # seconds to reach max jump power
var jump_charge := 0.0
var is_charging_jump := false

# Clumsiness settings
var wobble_strength := 0.25 # Reduced wobble amplitude for subtlety
var wobble_speed := 1.5 # Slower wobble for more natural feel

var move_dir_smoothed := Vector3.ZERO
var move_dir_inertia := Vector3.ZERO

var near_bed: bool = false
var yaw := 0.0
var pitch := 0.0
const PITCH_MIN := deg_to_rad(-40)
const PITCH_MAX := deg_to_rad(10)

func _ready():
	name = "Player"
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	PlayerManager.set_current_player(self)

	# === SpringArm3D proper config for Godot 4.4.1 ===
	spring_arm.spring_length = 4.0  # sets distance from player to camera
	spring_arm.margin = 0.25        # prevents clipping into geometry

	jump_charge_bar = get_node_or_null("PlayerUI/VBoxContainer/JumpChargeBar")
	if jump_charge_bar == null:
		print("⚠ JumpChargeBar not found — check your node path.")

func _on_bed_area_entered(_bed):
	near_bed = true
	nearby_bed_node = _bed

func _on_bed_area_exited(_bed):
	near_bed = false
	nearby_bed_node = null

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, PITCH_MIN, PITCH_MAX)

		# Normalize yaw between -PI and PI
		if yaw > PI:
			yaw -= TAU
		elif yaw < -PI:
			yaw += TAU

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventKey and event.pressed and event.keycode == KEY_E and near_bed and nearby_bed_node != null:
		nearby_bed_node.sleep_here()

func _physics_process(delta):
	# Rotate camera with clamped pitch and yaw
	spring_arm.rotation = Vector3(pitch, yaw, 0)

	# Input vector for movement
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

		# Subtle wobble effect added as an offset
		var time = Time.get_ticks_msec() / 1000.0
		var wobble = Vector3(
			sin(time * wobble_speed) * wobble_strength,
			0,
			cos(time * wobble_speed) * wobble_strength
		)

		# Combine input with wobble, but limit wobble influence to 20%
		var combined_dir = move_dir.lerp(wobble.normalized(), 0.2).normalized()

		# Smooth movement inertia, so changes aren't instant but smooth
		move_dir_inertia = move_dir_inertia.lerp(combined_dir, 0.08)

		# Smooth final move_dir_smoothed towards move_dir_inertia for extra softness
		move_dir_smoothed = move_dir_smoothed.lerp(move_dir_inertia, 0.1)

		# Rotate mesh slowly towards movement direction to simulate clumsiness
		if move_dir_smoothed.length() > 0.1:
			var target_rot = atan2(move_dir_smoothed.x, move_dir_smoothed.z)
			mesh.rotation.y = lerp_angle(mesh.rotation.y, target_rot, 0.1)
	else:
		# No input — slow down movement inertia to zero gradually
		move_dir_inertia = move_dir_inertia.lerp(Vector3.ZERO, 0.1)
		move_dir_smoothed = move_dir_smoothed.lerp(Vector3.ZERO, 0.1)

	# Set velocity based on smoothed direction and speed
	var speed = run_speed if Input.is_action_pressed("run") else walk_speed
	velocity.x = move_dir_smoothed.x * speed
	velocity.z = move_dir_smoothed.z * speed

	# Handle jump charging logic
	if is_on_floor():
		if Input.is_action_pressed("jump"):
			is_charging_jump = true
			jump_charge = min(jump_charge + delta, max_jump_charge_time)
		elif is_charging_jump:
			var charge_ratio = jump_charge / max_jump_charge_time
			velocity.y = jump_velocity * charge_ratio
			is_charging_jump = false
			jump_charge = 0.0
	else:
		is_charging_jump = false
		jump_charge = 0.0
		velocity.y -= gravity * delta

	move_and_slide()

	# Update jump UI
	if jump_charge_bar:
		jump_charge_bar.value = jump_charge
		jump_charge_bar.visible = is_charging_jump

	# Play animations
	if is_on_floor():
		if move_dir_smoothed.length() > 0.1:
			play_anim("Running_A")
		else:
			play_anim("Idle")
	else:
		play_anim("Jump_Idle")

func play_anim(anim_name: String) -> void:
	if not anim_player.is_playing() or anim_player.current_animation != anim_name:
		anim_player.play(anim_name)

# --- NEW respawn method to fix flipping on teleport ---
func respawn(new_position: Vector3) -> void:
	global_transform.origin = new_position

	# Reset velocity and movement inertia
	velocity = Vector3.ZERO
	move_dir_inertia = Vector3.ZERO
	move_dir_smoothed = Vector3.ZERO

	# Sync yaw and pitch with current camera rotation to avoid snapping
	var rot = spring_arm.rotation
	pitch = rot.x
	yaw = rot.y

	# Reset mesh rotation to match yaw
	mesh.rotation.y = yaw
