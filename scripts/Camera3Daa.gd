extends Camera3D

# The target node the camera will follow
@export var target: NodePath
# Offset from the target node
@export var offset: Vector3 = Vector3(0,1,4)
# Rotation speed
@export var rotation_speed: float = 0.1

# Internal reference to the target
var _target_node: Node3D

func _ready():
	if target:
		_target_node = get_node(target)

func _process(delta):
	if _target_node:
		# Update the position to follow the target with an offset
		global_transform.origin = _target_node.global_transform.origin + offset

		# Calculate the desired rotation
		var target_direction = (_target_node.global_transform.origin - global_transform.origin).normalized()
		var target_rotation = global_transform.basis.get_rotation_quaternion().slerp(Quaternion(target_direction, 0), rotation_speed * delta)

		# Apply the rotation to the camera
		global_transform.basis = Basis(target_rotation)
