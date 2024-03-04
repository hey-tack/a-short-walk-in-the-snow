extends CharacterBody3D

@onready var camera_mount = $camera_mount
@onready var animation_tree = $AnimationTree
@onready var armature = $Armature

# This was partially built using Lukky's Godot 4.0 character
# controller tutorial: https://www.youtube.com/watch?v=EP5AYllgHy8

const SPEED = 4.0
const JUMP_VELOCITY = 4.5
const ACCELLERATION = 1.0

var MOMENTUM = 0
var lastdir = Vector3.ZERO;
var lookRotation = 0;

@export var sens_horizontal = 0.5
@export var sens_vertical = 0.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	animation_tree.active = true
	
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sens_horizontal))
		camera_mount.rotate_x(deg_to_rad(-event.relative.y * sens_vertical))

func _process(delta): 
	
	# TODO: Expand this to allow looking targets. 
	
	lookRotation = ((armature.rotation_degrees.y + 180) / 180); 
	var finalRotation;
	# Some braindead maths, because I'm too tired to make this work another way.
	if lookRotation > 1: 
		finalRotation = -2 + lookRotation;
	else: 
		finalRotation = lookRotation;
	
	print(finalRotation);
	# Set the characters face to look the direction the camera is pointed
	animation_tree.set("parameters/LookRotation/blend_position", Vector2(finalRotation, 0))


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
