extends CharacterBody3D

var local_velocity = Vector3.ZERO

# Can't fly below this speed
var min_flight_speed = 10.0
# Maximum airspeed
var max_flight_speed = 150
# Turn rate
var turn_speed = 0.75
# Climb/dive rate
var pitch_speed = 0.5
# Wings "autolevel" speed
var level_speed = 3.0
# Throttle change speed
var throttle_delta = 10
var acceleration = 1

# Current speed
var forward_speed = 0.0
# Throttle input speed
var target_speed = 0.0
var drag = 0.01
# Lets us change behavior when grounded
var grounded = false

# control
var mouse_pos = Vector2.ZERO

# lift
var horizontalAoa = 0.0
var verticalAoa = 0.0

var linearLiftCoef = 0.1
var liftPower = 0.01
var liftCoefCurve = load("res://lift_coef_fr.tres")

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var text: RichTextLabel
var speed_ind: ColorRect

func _ready():
	text = get_node("/root/Main/RichTextLabel")
	speed_ind = get_node("/root/Main/ColorRect2")
	pass # Replace with function body.

func add_torque(state, torque_axis):
	var force_pos = torque_axis.cross(Vector3(0,1,0)).normalized()
	var torque = torque_axis.length()
	var force_dir = force_pos.cross(torque_axis).normalized() * torque

	state.add_force(force_dir, force_pos)
	state.add_force(-force_dir, -force_pos)

static func conv_vector(vec, transform):
	var b = transform.basis
	
	return b * vec

func update_velocity():
	
	local_velocity = conv_vector(velocity, transform)

func _input(event):
	if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			#print("Left button was clicked at ", event.position)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_speed = min(forward_speed + throttle_delta, max_flight_speed)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			if (target_speed - throttle_delta) > 0:
				target_speed = min(forward_speed - throttle_delta, max_flight_speed)
			else:
				target_speed = 0.0
	if event is InputEventMouseMotion:
		mouse_pos = event.position
		print("Mouse Motion at: ", mouse_pos.x*0.1-60)

func calculate_lift(aoa, rightAxis, liftPowerVal):
	var lift_velocity = Plane(rightAxis).project(-local_velocity)
	var lv2 = lift_velocity.length() * lift_velocity.length()
	
	var lift_force = lv2 * liftPowerVal * linearLiftCoef * aoa
	
	# lift is perpendicular to velocity
	var lift_direction = lift_velocity.normalized().cross(rightAxis)
	var lift = lift_direction * lift_force
	prints(liftCoefCurve.sample((1.0/100.0)*(aoa+90)+0))
	prints((1.0/100.0)*(aoa+90)+0)
	
	return lift

func _physics_process(delta):
	update_velocity()
	
	var a
	# FIX IT BRO
	forward_speed = target_speed
	a = Vector3.FORWARD * forward_speed
	velocity = lerp(velocity, a, acceleration *  delta) - (velocity * drag * Vector3(1,0,0)) * delta
	
	rotate_x(-(rotation.x-deg_to_rad(mouse_pos.y*0.1-30))*0.0001*velocity.length())
	rotate_y(-(rotation.y+deg_to_rad(mouse_pos.x*0.1-60))*0.0001*velocity.length())
	rotate_z(-(rotation.z+deg_to_rad(mouse_pos.x*0.1-60))*0.0001*velocity.length())
	
	if velocity.length() < 0.1:
		horizontalAoa = 0
		verticalAoa = 0
	else:
		horizontalAoa = atan2(-local_velocity.y, -local_velocity.z)
		verticalAoa = atan2(local_velocity.x, -local_velocity.z)
		
	var lift = calculate_lift(horizontalAoa, Vector3.RIGHT, liftPower)
	var lift_yaw = calculate_lift(verticalAoa, Vector3.UP, 0.001)
	velocity += lift + lift_yaw
	
	text.text = "%f %f %f" % [self.position.x, self.position.y, self.position.z]
	speed_ind.position.y = 512 - map_val(velocity.length(), 0, 100, 0, 512-64)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta * 2
	
	#prints(velocity, lift_yaw, lift, verticalAoa)

	move_and_slide()
