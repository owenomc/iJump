extends VehicleBody3D

@export var ENGINE_POWER := 300.0
@export var BRAKE_FORCE := 60.0
@export var MAX_STEER := 0.5
@export var STEER_SPEED := 4.0

var steer_angle := 0.0

@onready var wheel_fl: VehicleWheel3D = $FrontLeftWheel
@onready var wheel_fr: VehicleWheel3D = $FrontRightWheel
@onready var wheel_rl: VehicleWheel3D = $BackLeftWheel
@onready var wheel_rr: VehicleWheel3D = $BackRightWheel

func _physics_process(delta):
	var throttle := Input.get_axis("move_down", "move_up")
	var steer_input := Input.get_axis("move_right", "move_left")

	# Smooth steering
	steer_angle = move_toward(steer_angle, steer_input * MAX_STEER, STEER_SPEED * delta)

	# Apply to front wheels only
	wheel_fl.steering = steer_angle
	wheel_fr.steering = steer_angle

	# Apply forward force to rear wheels only (go-kart behavior)
	wheel_rl.engine_force = throttle * ENGINE_POWER
	wheel_rr.engine_force = throttle * ENGINE_POWER

	# Brake if no input
	var is_braking := is_zero_approx(throttle)
	wheel_fl.brake = BRAKE_FORCE if is_braking else 0.0
	wheel_fr.brake = BRAKE_FORCE if is_braking else 0.0
	wheel_rl.brake = BRAKE_FORCE if is_braking else 0.0
	wheel_rr.brake = BRAKE_FORCE if is_braking else 0.0
