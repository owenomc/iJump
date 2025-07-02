extends CharacterBody3D

# === CONFIGURABLE STATS ===
@export var walk_speed := 3.0
@export var run_speed := 6.0
@export var jump_velocity := 10.0
@export var gravity := 15.0
@export var mouse_sensitivity := 0.001
@export var max_jump_charge_time := 0.8
@export var mantle_height := 1.0
@export var mantle_duration := .6

# === JUMP AUDIO ===
@onready var jump_sound = $AudioStreamPlayer3D

# === CAMERA SETTINGS ===
@onready var camera_fps := $Camera3Dfps
var is_first_person := true

# === CHARACTER VISUALS & ANIMATIONS ===
@onready var mesh := $Skeleton_Rogue
@onready var anim_player := $Skeleton_Rogue/AnimationPlayer

# === UI ===
var jump_charge_bar: ProgressBar

# === MANTLING ===
@onready var mantle_ray := $MantleRay
@onready var mantle_check_above := $MantleCheckAbove
var mantle_cooldown := 0.5
var mantle_cooldown_timer := 0.0
var is_mantling := false

# === INTERNAL STATE ===
var yaw := 0.0
var pitch := 0.0
const PITCH_MIN := deg_to_rad(-50)
const PITCH_MAX := deg_to_rad(50)

var jump_charge := 0.0
var is_charging_jump := false

# Clumsy wobble
var wobble_strength := 0.25
var wobble_speed := 1.5
var move_dir_smoothed := Vector3.ZERO
var move_dir_inertia := Vector3.ZERO

# Bed interaction
var near_bed := false
var nearby_bed_node = null

# === Flashlight ===
@onready var flashlight_spot = $Flashlight/SpotLight3D
@onready var flashlight_omni = $Flashlight/OmniLight3D

# === Ice Pick ===
@onready var camera = $Camera3Dfps
@onready var pickaxe1 = preload("res://assets/gameObjects/picks/picks.tscn").instantiate()
@onready var pickaxe2 = preload("res://assets/gameObjects/picks/picks.tscn").instantiate()
var is_swinging_1 := false
var is_swinging_2 := false

func swing_pickaxe(pickaxe: Node3D, index: int) -> void:
	if (index == 1 and is_swinging_1) or (index == 2 and is_swinging_2):
		return  # Prevent double-swing

	if index == 1:
		is_swinging_1 = true
	else:
		is_swinging_2 = true

	var start_pos = pickaxe.position
	var down_pos = start_pos + Vector3(0, -0.5, 0)

	pickaxe.position = down_pos
	await get_tree().create_timer(0.1).timeout
	pickaxe.position = start_pos

	if index == 1:
		is_swinging_1 = false
	else:
		is_swinging_2 = false

func _ready():

	# Use Mouse Captured
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Added pickaxes
	camera.add_child(pickaxe1)
	camera.add_child(pickaxe2)

	# Position pickaxes
	pickaxe1.position = Vector3(-1, -0.5, -1)
	pickaxe2.position = Vector3(1, -0.5, -1)

	# Flip them to face forward (Y-axis)
	pickaxe1.rotation_degrees.y = 180
	pickaxe2.rotation_degrees.y = 180

	# Tilt them inward slightly (Z-axis)
	pickaxe1.rotation_degrees.z = 15    # tilt right hand inward
	pickaxe2.rotation_degrees.z = -15   # tilt left hand inward

	# Updates Jump UI
	jump_charge_bar = get_node_or_null("PlayerUI/JumpChargeBar")
	if jump_charge_bar == null:
		print("JumpChargeBar not found")

func _input(event):
	if event.is_action_pressed("flashlight_toggle"):
		flashlight_spot.visible = not flashlight_spot.visible
		flashlight_omni.visible = not flashlight_omni.visible

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, PITCH_MIN, PITCH_MAX)
		if yaw > PI: yaw -= TAU
		elif yaw < -PI: yaw += TAU

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func get_input_vector() -> Vector2:
	var x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	return Vector2(x, y)

func get_look_vector() -> Vector2:
	var x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	var y = Input.get_action_strength("look_up") - Input.get_action_strength("look_down")
	return Vector2(x, y)

func _physics_process(delta: float) -> void:
	# === INPUT VECTORS ===
	var move_input := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_up") - Input.get_action_strength("move_down")
	)
	var look_input := Vector2(
		Input.get_action_strength("look_right") - Input.get_action_strength("look_left"),
		Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	)

	# === ROTATION ===
	var controller_look_speed := 5  # Tweak this for faster response
	if look_input.length() > 0.01:
		yaw -= look_input.x * controller_look_speed * delta
		pitch = clamp(pitch - look_input.y * controller_look_speed * delta, PITCH_MIN, PITCH_MAX)

	# Update camera orientation
	if is_first_person:
		camera_fps.rotation.x = pitch
		rotation.y = yaw

	# === MOVEMENT ===
	var move_dir := Vector3.ZERO
	if move_input.length() > 0.1:
		var cam_basis = camera_fps.global_transform.basis
		var forward = -cam_basis.z.normalized()
		var right = cam_basis.x.normalized()
		move_dir = (right * move_input.x + forward * move_input.y).normalized()

		# Apply wobble and smoothing
		var time = Time.get_ticks_msec() / 1000.0
		var wobble = Vector3(
			sin(time * wobble_speed) * wobble_strength,
			0,
			cos(time * wobble_speed) * wobble_strength
		)
		var combined = move_dir.lerp(wobble.normalized(), 0.2).normalized()
		move_dir_inertia = move_dir_inertia.lerp(combined, 0.08)
		move_dir_smoothed = move_dir_smoothed.lerp(move_dir_inertia, 0.1)

		# Face movement direction
		if move_dir_smoothed.length() > 0.1:
			var target_rot = atan2(move_dir_smoothed.x, move_dir_smoothed.z)
			mesh.rotation.y = lerp_angle(mesh.rotation.y, target_rot, 0.1)
	else:
		move_dir_inertia = move_dir_inertia.lerp(Vector3.ZERO, 0.1)
		move_dir_smoothed = move_dir_smoothed.lerp(Vector3.ZERO, 0.1)

	var current_speed = run_speed if Input.is_action_pressed("run") else walk_speed
	velocity.x = move_dir_smoothed.x * current_speed
	velocity.z = move_dir_smoothed.z * current_speed

	# === JUMPING ===
	handle_jump_logic(delta)

	# === MANTLING ===
	# Decrement cooldown timer if active
	if mantle_cooldown_timer > 0.0:
		mantle_cooldown_timer -= delta

	# Mantle input check
	if Input.is_action_pressed("jump") and not is_on_floor():
		if mantle_cooldown_timer <= 0.0 and mantle_ray.is_colliding() and not mantle_check_above.is_colliding():
			start_mantle()
	
	# === MOVE & ANIMATE ===
	move_and_slide()
	handle_animation()
	update_jump_ui()

# Example handle_movement_with_input from earlier:
func handle_movement_with_input(input_vec: Vector2, delta: float):
	var move_dir = Vector3.ZERO
	if input_vec.length() > 0:
		var cam_basis = (camera_fps).global_transform.basis
		var forward = -cam_basis.z.normalized()
		var right = cam_basis.x.normalized()
		move_dir = (right * input_vec.x + forward * input_vec.y).normalized()

		# Wobble effect etc, unchanged
		var time = Time.get_ticks_msec() / 1000.0
		var wobble = Vector3(
			sin(time * wobble_speed) * wobble_strength,
			0,
			cos(time * wobble_speed) * wobble_strength
		)
		var combined_dir = move_dir.lerp(wobble.normalized(), 0.2).normalized()
		move_dir_inertia = move_dir_inertia.lerp(combined_dir, 0.08)
		move_dir_smoothed = move_dir_smoothed.lerp(move_dir_inertia, 0.1)

		if move_dir_smoothed.length() > 0.1:
			var target_rot = atan2(move_dir_smoothed.x, move_dir_smoothed.z)
			mesh.rotation.y = lerp_angle(mesh.rotation.y, target_rot, 0.1)
	else:
		move_dir_inertia = move_dir_inertia.lerp(Vector3.ZERO, 0.1)
		move_dir_smoothed = move_dir_smoothed.lerp(Vector3.ZERO, 0.1)

	var speed = run_speed if Input.is_action_pressed("run") else walk_speed
	velocity.x = move_dir_smoothed.x * speed
	velocity.z = move_dir_smoothed.z * speed

	# Mantle
	if Input.is_action_pressed("jump") and not is_on_floor():
		if mantle_cooldown_timer <= 0.0 and mantle_ray.is_colliding() and not mantle_check_above.is_colliding():
			start_mantle()

	handle_movement(delta)
	handle_jump_logic(delta)
	handle_animation()

	move_and_slide()
	update_jump_ui()

func handle_movement(_delta):
	var input_vec = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("forward") - Input.get_action_strength("backward")
	)

	var move_dir = Vector3.ZERO
	if input_vec.length() > 0:
		var cam_basis = (camera_fps).global_transform.basis
		var forward = -cam_basis.z.normalized()
		var right = cam_basis.x.normalized()
		move_dir = (right * input_vec.x + forward * input_vec.y).normalized()

		var time = Time.get_ticks_msec() / 1000.0
		var wobble = Vector3(
			sin(time * wobble_speed) * wobble_strength,
			0,
			cos(time * wobble_speed) * wobble_strength
		)
		var combined_dir = move_dir.lerp(wobble.normalized(), 0.2).normalized()
		move_dir_inertia = move_dir_inertia.lerp(combined_dir, 0.08)
		move_dir_smoothed = move_dir_smoothed.lerp(move_dir_inertia, 0.1)

		if move_dir_smoothed.length() > 0.1:
			var target_rot = atan2(move_dir_smoothed.x, move_dir_smoothed.z)
			mesh.rotation.y = lerp_angle(mesh.rotation.y, target_rot, 0.1)
	else:
		move_dir_inertia = move_dir_inertia.lerp(Vector3.ZERO, 0.1)
		move_dir_smoothed = move_dir_smoothed.lerp(Vector3.ZERO, 0.1)

	var speed = run_speed if Input.is_action_pressed("run") else walk_speed
	velocity.x = move_dir_smoothed.x * speed
	velocity.z = move_dir_smoothed.z * speed

	# Try to mantle by holding jump
	if Input.is_action_pressed("jump") and not is_on_floor():
		if mantle_ray.is_colliding() and not mantle_check_above.is_colliding():
			start_mantle()
			swing_pickaxe(pickaxe1, 1)
			swing_pickaxe(pickaxe2, 2)

func handle_jump_logic(delta):
	if is_on_floor():
		if Input.is_action_pressed("jump"):
			is_charging_jump = true
			jump_charge = min(jump_charge + delta, max_jump_charge_time)
		elif is_charging_jump:
			jump_sound.play()
			swing_pickaxe(pickaxe1, 1)
			swing_pickaxe(pickaxe2, 2)
			var ratio = jump_charge / max_jump_charge_time
			velocity.y = jump_velocity * ratio
			is_charging_jump = false
			jump_charge = 0.0
	else:
		is_charging_jump = false
		jump_charge = 0.0
		velocity.y -= gravity * delta

func start_mantle():
	is_mantling = true
	play_anim("Cheer")
	jump_sound.play()
	velocity.y = jump_velocity * 1.2  # Mantle jump impulse
	mantle_cooldown_timer = mantle_cooldown  # Start cooldown timer

func handle_animation():
	if is_mantling:
		return
	if is_on_floor():
		if move_dir_smoothed.length() > 0.1:
			if Input.is_action_pressed("run"):
				play_anim("Running_A")
			else:
				play_anim("Walking_A")
		else:
			play_anim("Idle")
	else:
		play_anim("Jump_Full_Long")

func play_anim(anim_name: String) -> void:
	if not anim_player.is_playing() or anim_player.current_animation != anim_name:
		anim_player.play(anim_name)

func update_jump_ui():
	jump_charge_bar.value = jump_charge
