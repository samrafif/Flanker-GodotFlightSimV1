extends RigidBody3D
const Utils = preload("res://scripts/utils.gd")

const maxSpeed = 500.0
const throttleDelta = 50.0
var target_speed = 0.0
var forward_speed = 0.0
var mouse_pos: Vector2 = Vector2.ZERO

var local_velocity: Vector3 = Vector3.ZERO
var horizontal_aoa = 0.0
var vertical_aoa = 0.0

var linearLiftCoef = 0.01
var liftPower = 0.5
var rudderPower = 0.01
var inducedDragCoef = 0.1
@export var liftCoefCurve: Curve

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var velocity = Vector3(0,0,0)

var text: RichTextLabel
var text2: RichTextLabel
var speed_ind: ColorRect

func _ready():
	text = get_node("/root/Main/RichTextLabel")
	text2 = get_node("/root/Main/RichTextLabel2")
	speed_ind = get_node("/root/Main/ColorRect2")
	
	liftCoefCurve.bake()

func update_status():
	local_velocity = transform.basis.inverse() * self.linear_velocity
	
	if self.linear_velocity.length() < 0.1:
		horizontal_aoa = 0.0
		vertical_aoa = 0.0
	else:
		horizontal_aoa = atan2(-local_velocity.y, -local_velocity.z)
		vertical_aoa = atan2(local_velocity.x, -local_velocity.z)
		

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_speed = min(forward_speed + throttleDelta, maxSpeed)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			if (target_speed - throttleDelta) > 0:
				target_speed = min(forward_speed - throttleDelta, maxSpeed)
			else:
				target_speed = 0.0

	if event is InputEventMouseMotion:
		mouse_pos = event.position
		print("Mouse Motion at: ", mouse_pos.y*0.1-30)

func calculate_lift(aoa, rightAxis, liftPowerVal):
	var lift_velocity = Plane(rightAxis).project(-local_velocity)
	var lv2 = lift_velocity.length_squared()
	
	var lift_coef = liftCoefCurve.sample_baked(Utils.map_val(rad_to_deg(aoa+0.01),-90.0,90.0,0.0,1.0))
	var lift_force = lv2 * liftPowerVal * lift_coef
	
	# lift is perpendicular to velocity
	var lift_direction = lift_velocity.normalized().cross(rightAxis)
	var lift = lift_direction * lift_force
	
	var drag_force = lift_coef * lift_coef
	var drag_direction = -local_velocity.normalized()
	var induced_drag = drag_force * lv2 * drag_direction * inducedDragCoef
	
	return lift + induced_drag

func update_thrust():
	pass

func _process(delta):
	update_status()
	
	if Input.is_action_pressed("ui_up"):
		apply_torque_impulse(Vector3(deg_to_rad(20),0,0))
		
	if Input.is_action_pressed("ui_down"):
		apply_torque_impulse(Vector3(deg_to_rad(-20),0,0))
	
	if Input.is_action_pressed("ui_right"):
		apply_torque_impulse(Vector3(0,deg_to_rad(-20),deg_to_rad(-10)))
		
	if Input.is_action_pressed("ui_left"):
		apply_torque_impulse(Vector3(0,deg_to_rad(20),deg_to_rad(10)))
	
	text.text = "Pos: %f %f %f \n Vel: %f %f %f" % [
		self.position.x,self.position.y,self.position.z,
		self.linear_velocity.x,self.linear_velocity.y,self.linear_velocity.z ]
		
	text2.text = "Throttle: %d" % ((target_speed/maxSpeed)*100) + "%"
	#speed_ind.position.y = 512 - Trans3DUtils.map_val(-local_velocity.y, 0, 100, 0, 512-64)
	speed_ind.position.y = 512 - Utils.map_val(self.linear_velocity.length(), 0, 250, 0, 512-64)
	
	# Thrust
	forward_speed = target_speed
	velocity = transform.basis * (forward_speed*Vector3.FORWARD)
	apply_force(velocity)
	
	var lv2 = local_velocity.length_squared()
	var drag_coef = Utils.Scale6(
		local_velocity.normalized(),
		.015,.015,
		.015,.015,
		.015,.005
	)
	
	var drag = drag_coef.length() * lv2 * -local_velocity.normalized()
	apply_force(drag)
	
	var a = calculate_lift(horizontal_aoa, Vector3.RIGHT, liftPower)
	apply_force(a)
	var b = calculate_lift(vertical_aoa, Vector3.UP, rudderPower)
	apply_force(b)

func unified_debug(delta):
	prints("========", delta, "========")
	prints("Vel: ", self.linear_velocity, "LocVel: ", local_velocity)
	prints("Rot: ", self.rotation_degrees)
	prints()
