extends CharacterBody3D

# === CONFIGURABLE STATS ===
@export var walk_speed := 3.0
@export var run_speed := 6.0
@export var jump_velocity := 15.0
@export var gravity := 30
@export var mouse_sensitivity := 0.003
@export var max_jump_charge_time := 0.8
@export var mantle_height := 1.5
@export var mantle_duration := 1

# === CAMERA SETTINGS ===
@onready var spring_arm := $SpringArm3D
@onready var camera := $SpringArm3D/Camera3D
@onready var camera_fps := $Camera3Dfps
var is_first_person := true

# === CHARACTER VISUALS & ANIMATIONS ===
@onready var mesh := $Skeleton_Rogue
@onready var anim_player := $Skeleton_Rogue/AnimationPlayer

# === UI ===
var jump_charge_bar: ProgressBar

# === RAYCASTS FOR MANTLING ===
@onready var mantle_ray := $MantleRay
@onready var mantle_check_above := $MantleCheckAbove

# === INTERNAL STATE ===
var yaw := 0.0
var pitch := 0.0
const PITCH_MIN := deg_to_rad(-50)
const PITCH_MAX := deg_to_rad(20)

var jump_charge := 0.0
var is_charging_jump := false
var is_mantling := false
var mantle_timer := 0.0

# Clumsy wobble
var wobble_strength := 0.25
var wobble_speed := 1.5
var move_dir_smoothed := Vector3.ZERO
var move_dir_inertia := Vector3.ZERO

# Bed interaction
var near_bed := false
var nearby_bed_node = null

func _ready():
	name = "Player"
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	PlayerManager.set_current_player(self)

	spring_arm.spring_length = 4.0
	spring_arm.margin = 0.25
	
	update_camera_mode()
	
	# Force first person at start
	camera_fps.current = is_first_person
	camera.current = not is_first_person
	spring_arm.visible = not is_first_person
	mesh.visible = not is_first_person  # Show mesh only in third person
	
	jump_charge_bar = get_node_or_null("PlayerUI/VBoxContainer/JumpChargeBar")
	if jump_charge_bar == null:
		print("JumpChargeBar not found")

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, PITCH_MIN, PITCH_MAX)
		if yaw > PI: yaw -= TAU
		elif yaw < -PI: yaw += TAU

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif event.is_action_pressed("toggle_fps"):
			toggle_camera_mode()
		elif event.keycode == KEY_E and near_bed and nearby_bed_node != null:
			nearby_bed_node.sleep_here()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func update_camera_mode():
	camera_fps.current = is_first_person
	camera.current = not is_first_person
	spring_arm.visible = not is_first_person
	mesh.visible = not is_first_person  # Show mesh only in third person

func toggle_camera_mode():
	is_first_person = not is_first_person
	update_camera_mode()

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
	else:
		spring_arm.rotation = Vector3(pitch, yaw, 0)

	# === MOVEMENT ===
	var move_dir := Vector3.ZERO
	if move_input.length() > 0.1:
		var cam_basis = camera_fps.global_transform.basis if is_first_person else spring_arm.global_transform.basis
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
	if Input.is_action_pressed("jump") and not is_on_floor():
		if mantle_ray.is_colliding() and not mantle_check_above.is_colliding():
			start_mantle()

	# === MOVE & ANIMATE ===
	move_and_slide()
	handle_animation()
	update_jump_ui()

# Example handle_movement_with_input from earlier:
func handle_movement_with_input(input_vec: Vector2, delta: float):
	var move_dir = Vector3.ZERO
	if input_vec.length() > 0:
		var cam_basis = (camera_fps if is_first_person else spring_arm).global_transform.basis
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
		if mantle_ray.is_colliding() and not mantle_check_above.is_colliding():
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
		var cam_basis = (camera_fps if is_first_person else spring_arm).global_transform.basis
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

func handle_jump_logic(delta):
	if is_on_floor():
		if Input.is_action_pressed("jump"):
			is_charging_jump = true
			jump_charge = min(jump_charge + delta, max_jump_charge_time)
		elif is_charging_jump:
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
	mantle_timer = 0.0
	play_anim("Cheer")
	velocity = Vector3(velocity.x, jump_velocity * 1.2, velocity.z)

func handle_mantle(delta):
	mantle_timer += delta
	if mantle_timer >= mantle_duration:
		is_mantling = false

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
	if jump_charge_bar:
		jump_charge_bar.value = jump_charge
		jump_charge_bar.visible = is_charging_jump

func _on_bed_area_entered(_bed):
	near_bed = true
	nearby_bed_node = _bed

func _on_bed_area_exited(_bed):
	near_bed = false
	nearby_bed_node = null

func respawn(new_position: Vector3) -> void:
	global_transform.origin = new_position
	velocity = Vector3.ZERO
	move_dir_inertia = Vector3.ZERO
	move_dir_smoothed = Vector3.ZERO

	var rot = (spring_arm if not is_first_person else camera_fps).rotation
	pitch = rot.x
	yaw = rot.y
	mesh.rotation.y = yaw
