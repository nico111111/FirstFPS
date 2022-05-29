extends KinematicBody


# stats
var curHp : int = 10
var maxHp : int = 10
var ammo : int = 15
var score : int = 0

# physics
var moveSpeed : float = 5.0
var jumpForce : float = 5.0
var gravity : float = 12.0

# cam look
var minLookAngle : float = -90.0
var maxLookAngle : float = 90.0
var lookSensitivity : float = 0.5

# vectors
var vel : Vector3 = Vector3()
var mouseDelta : Vector2 = Vector2()

# player components
onready var camera = get_node("Camera")
onready var muzzle = get_node("Camera/GunModel/Muzzle")
onready var bulletScene = preload("res://Scene/Bullet.tscn")
onready var ui : Node = get_node("/root/MainScene/CanvasLayer/UI")

func _ready ():
	# hide and lock the mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# set the UI
	ui.update_health_bar(curHp, maxHp)
	ui.update_ammo_text(ammo)
	ui.update_score_text(score)


# called when an input is detected
func _input (event):
	# did the mouse move?
	if event is InputEventMouseMotion:
		mouseDelta = event.relative
		
# called every frame
func _process (delta):
	# rotate camera along X axis
	camera.rotation_degrees -= Vector3(rad2deg(mouseDelta.y), 0, 0) * lookSensitivity * delta
	# clamp the vertical camera rotation
	camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, minLookAngle, maxLookAngle)
  
	# rotate player along Y axis
	rotation_degrees -= Vector3(0, rad2deg(mouseDelta.x), 0) * lookSensitivity * delta
  
	# reset the mouse delta vector
	mouseDelta = Vector2()
	
	if Input.is_action_just_pressed("shoot"):
		shoot()


func _physics_process(delta):
	# reset the x and z velocity
	vel.x = 0
	vel.z = 0
	var input = Vector2()
	# movement inputs
	if Input.is_action_pressed("move_forward"):
		input.y -= 1
	if Input.is_action_pressed("move_backward"):
		input.y += 1
	if Input.is_action_pressed("move_left"):
		input.x -= 1
	if Input.is_action_pressed("move_right"):
		input.x += 1
	# normalize the input so we can't move faster diagonally
	input = input.normalized()
	
	# get our forward and right directions
	var forward = global_transform.basis.z
	var right = global_transform.basis.x
	
	# set the velocity
	vel.z = (forward * input.y + right * input.x).z * moveSpeed
	vel.x = (forward * input.y + right * input.x).x * moveSpeed
	# apply gravity
	vel.y -= gravity * delta
	# move the player
	vel = move_and_slide(vel, Vector3.UP)
	
	# jump if we press the jump button and are standing on the floor
	if Input.is_action_pressed("jump") and is_on_floor():
		vel.y = jumpForce


# called when we press the shoot button - spawn a new bullet
func shoot ():
	var bullet = bulletScene.instance()
	get_node("/root/MainScene").add_child(bullet)
	bullet.global_transform = muzzle.global_transform
	bullet.scale = Vector3.ONE
	ammo -= 1
	ui.update_ammo_text(ammo)

# called when an enemy damages us
func take_damage (damage):
	curHp -= damage
	ui.update_health_bar(curHp, maxHp)
	if curHp <= 0:
		die()
		
func die() :
	pass
	
func add_score (amount):
	score += amount
	ui.update_score_text(score)
	
func add_health (amount):
	curHp = clamp(curHp + amount, 0, maxHp)
	ui.update_health_bar(curHp, maxHp)

func add_ammo (amount):
	ammo += amount
	ui.update_ammo_text(ammo)
