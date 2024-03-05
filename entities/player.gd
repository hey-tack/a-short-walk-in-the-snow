extends CharacterBody3D

@onready var camera_mount = $camera_mount
@onready var animation_tree = $AnimationTree
@onready var armature = $Armature
@onready var mesh = $Armature/Skeleton3D/Spfhere

# This was partially built using Lukky's Godot 4.0 character
# controller tutorial: https://www.youtube.com/watch?v=EP5AYllgHy8

const SPEED = 4.0
const JUMP_VELOCITY = 4.5
const ACCELLERATION = 1.0
const LOOK_ACCELLERATION = 4.0

var MOMENTUM = 0
var lastdir = Vector3.ZERO
var lookRotationX = 0
var lookRotationY = 0

var pitch_max = 75
var pitch_min = -55

var oldLookVector = Vector2.ZERO

@export var sens_horizontal = 0.5
@export var sens_vertical = 0.5
@export var look_target: Node

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	animation_tree.active = true
	
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sens_horizontal))
		camera_mount.rotate_x(deg_to_rad(-event.relative.y * sens_vertical))
		camera_mount.rotation.x = clamp(camera_mount.rotation.x, deg_to_rad(pitch_min), deg_to_rad(pitch_max))
	
	if event is InputEventKey:
		if event.keycode == KEY_F and event.pressed: 
			animation_tree.set("parameters/YellOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func _process(delta): 
	# To set blend tree values based on what we're looking at.
	var finalRotationX
	var finalRotationY
	
	# TODO: Expand this to allow looking targets. 
	if look_target: 
		var targetVector = self.position.direction_to(look_target.position)
		var targetZDot = targetVector.dot(armature.global_transform.basis.z)
		# -1 is facing away, and 1 is facing directly
		
		# to determine if the object is to the "left" or "right of us,
		# we also need the x vector basis for the left dot
		
		var targetXDot = targetVector.dot(armature.global_transform.basis.x)
		# in this case, -1 is to the right, and 1 is to the left. 
		
		# Mathematically shift values around to match what we expect for blend trees. 
		# -1 = Looking to the left fully
		#  1 = Looking to the right fully
		#  0 = Looking dead center
		
		if targetXDot > 0: # Target is to the left
			finalRotationX = (targetZDot -1) / 2
		else: 			   # Target is to the right
			finalRotationX = (1 -targetZDot) / 2
		
		# Now we just have to figure out how "high" the target is. We can do with with 
		# a dot on the y vector.
		var targetYDot = targetVector.dot(armature.global_transform.basis.y)
		
#		if lookRotationY > 0: # target is above us
#			finalRotationY = targetYDot
#		else:                 # target is below
#			finalRotationY = targetYDot
		
		# in this case, it works out perfect for our needs, because 1 is directly above
		# and -1 is directly below. Which perfectly matches the blend tree setup.
		# so no need for additional checking, just set it to the dot.
		
		finalRotationY = targetYDot
		
	else: 
		lookRotationX = ((armature.rotation_degrees.y + 180) / 180)
		lookRotationY = ((camera_mount.rotation_degrees.x) / 180)
	
		# Some braindead maths, because I'm too tired to make this work another way.
		if lookRotationX > 1: 
			finalRotationX = -2 + lookRotationX
		else: 
			finalRotationX = lookRotationX
		
		# I'm not sure this condition is ever actually met honestly.
		if lookRotationY > 1:
			finalRotationY = -1 + lookRotationY
		else: 
			finalRotationY = lookRotationY * 2
	
	var lookVector = oldLookVector.lerp(Vector2(finalRotationX, finalRotationY), delta * LOOK_ACCELLERATION)
	
	print(lookVector)
	
	# Set the characters face to look the direction the camera is pointed
	animation_tree.set("parameters/LookRotation/blend_position", lookVector)
	
	mesh.set_blend_shape_value(mesh.find_blend_shape_by_name("LookX"), lookVector.x)
	mesh.set_blend_shape_value(mesh.find_blend_shape_by_name("LookY"), -lookVector.y)

	oldLookVector = lookVector;

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var lerped_direction = lerp(lastdir, direction, delta * ACCELLERATION);
	if direction:
		_speed_up(delta)
		animation_tree.set("parameters/MoveSpeed/blend_amount", (velocity.length() / SPEED))
		
		armature.look_at(position - lerped_direction)
		
		velocity.x = lerped_direction.x * MOMENTUM
		velocity.z = lerped_direction.z * MOMENTUM
		lastdir = lerped_direction;
	else:
		_slow_down(delta)
		animation_tree.set("parameters/MoveSpeed/blend_amount", (velocity.length() / SPEED))
		if lastdir:
			armature.look_at(position - lastdir)
			velocity.x = lastdir.x * MOMENTUM
			velocity.z = lastdir.z * MOMENTUM


	move_and_slide()
	
func _speed_up(delta): 
	# Gradually increment momentum.
	if MOMENTUM < SPEED: 
		MOMENTUM += (SPEED * delta) * ACCELLERATION
	
	# Cap out momentum to max speed.
	if MOMENTUM > SPEED: 
		MOMENTUM = SPEED
		
func _slow_down(delta): 
	# Gradually decrement momentum.
	if MOMENTUM > 0: 
		MOMENTUM -= (SPEED * delta) * ACCELLERATION
	
	# Slow to zero
	if MOMENTUM < 0: 
		MOMENTUM = 0	
