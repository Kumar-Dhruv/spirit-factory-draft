extends CharacterBody3D

@onready var player: CharacterBody3D = $"."
@onready var camera_controller: Node3D = $CameraController
@onready var camera_3d: Camera3D = $CameraController/Camera3D
@onready var health: ProgressBar = $Control/stats/health
@onready var recoil_reset: Label = $"Control/recoil reset"
@onready var recoil_reset_timer: Timer = $"recoil reset"
@onready var regen_timer: Timer = $"regen timer"

var mouse_sensitivity: float = 0.002

const WALK_SPEED: = 7.0
const SPRINT_SPEED := 11.0
const DASH_SPEED := 30.0

var ground_accel := 15.0
var ground_friction := 12.0
var current_speed := WALK_SPEED

var is_dashing := false
var dash_timer := 0.0
const  DASH_DURATION := 0.15

var current_hp = 100
const MAX_HP = 100
var regen_rate = 5
var is_healing = false
var can_regen = false

#region Camera Effect Variables
@export_category("Camera Effect Settings")
@export var enable_strafe_tilt : bool = true
@export var enable_damage_kick : bool = true
@export var enable_weapon_kick : bool = true
@export var enable_screen_shake : bool = true #use in feq 3 greanade launcher 
@export var  enable_head_bobbing : bool = true

@export_category("Camera Effects Values")

@export_subgroup("strafe_tilt_values")
@export var run_pitch : float = 0.1
@export var run_roll : float = 0.25
@export var max_pitch : float = 1.0
@export var max_roll : float = 2.5

@export_subgroup("damage_kick")
@export var damage_time :float = 0.3
@export var pitch :float = 15.0
@export var roll :float = 10.0
var _damage_kick_pitch :float = 0.0
var _damage_kick_roll :float = 0.0
var _damage_timer :float = 0.0

@export_subgroup("weapon_kick")
@export var recoil_cam_stiffness : float = 80.0
@export var recoil_cam_damping : float = 10.0
@export var recoil_cam_max : float = 50.0

var _recoil_angles : Vector3 = Vector3.ZERO
var _recoil_velocity : Vector3 = Vector3.ZERO

@export_subgroup("Headbob")

@export_range(0.0,1.0,0.001) var bob_pitch : float = 0.05
@export_range(0.0,1.0,0.001) var bob_roll : float = 0.025
@export_range(0.0,0.05,0.001) var bob_up : float = 0.05
@export_range(3.0,8.0,0.1) var bob_frequency :float = 6.0

var _screen_shake_tween : Tween

var _step_timer : float = 0.0

const MIN_SCREEN_SHAKE : float = 0.05
const MAX_SCREEN_SHAKE :float = 0.5
#endregion

func _ready() -> void:
	loader.player = $"."
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	calculate_view_offset(delta)

func _physics_process(delta: float) -> void:
	
	if dash_timer > 0:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
	
	if Input.is_action_pressed("dash") and !is_dashing:
		is_dashing = true
		dash_timer = DASH_DURATION
	
	if is_dashing:
		current_speed = DASH_SPEED
	elif Input.is_action_pressed("sprint") and is_on_floor():
		current_speed = SPRINT_SPEED
	else:
		current_speed = WALK_SPEED
	
	var input_dir = Input.get_vector("left","right","forward","backward")
	handle_movement(input_dir,delta)
	
	health.value = clampf(current_hp, 0, 100)
	recoil_reset.text = "%.1f" % recoil_reset_timer.time_left
	
	if is_healing and current_hp < 100 and can_regen:
		regen()
		
	move_and_slide()

func handle_movement(input_dir:Vector2,delta:float)->void:
	var direction = (transform.basis*Vector3(input_dir.x,0,input_dir.y)).normalized()
	var accel = ground_accel 
	
	if direction:
		if is_dashing:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = lerp(velocity.x,direction.x*current_speed,accel*delta)
			velocity.z = lerp(velocity.z,direction.z*current_speed,accel*delta)
	else:
		var friction = ground_friction
		velocity.x = move_toward(velocity.x,0,friction*delta)
		velocity.z = move_toward(velocity.z,0,friction*delta)

#region Camera Effect Functions

func calculate_view_offset(delta:float):
	if !player:return
	
	_damage_timer -= delta
	
	var angles = Vector3.ZERO
	var offset = Vector3.ZERO
	
	#headbobing sin calculation
	var speed = Vector2(velocity.x,velocity.z).length()
	if speed > 0.1 and player.is_on_floor():
		_step_timer += delta*(speed/bob_frequency)
		_step_timer = fmod(_step_timer,1.0)
	else:
		_step_timer = 0.0
	var bob_sin = sin(_step_timer*2.0*PI)*0.5
	
	#camera tilt while strafing
	if enable_strafe_tilt:
		var forward = camera_3d.global_transform.basis.z
		var right = camera_3d.global_transform.basis.x
		
		var forward_dot = velocity.dot(forward)
		var forward_tilt = clampf(forward_dot*deg_to_rad(run_pitch),deg_to_rad(-max_pitch),deg_to_rad(max_pitch))
		angles.x += forward_tilt
		
		var right_dot = velocity.dot(right)
		var right_tilt = clampf(right_dot*deg_to_rad(run_roll),deg_to_rad(-max_roll),deg_to_rad(max_roll))
		angles.z -= right_tilt
	
	#damage kick effect
	if enable_damage_kick:
		var damage_ratio = max(0,_damage_timer/damage_time)	
		angles.x += damage_ratio*_damage_kick_pitch
		angles.z += damage_ratio*_damage_kick_roll
	
	#weapon kick
	if enable_weapon_kick:
		var d = min(delta,0.05)
		var angles_max := deg_to_rad(recoil_cam_max)
		
		for axis in 3:
			var r = SpringUtl.apply(_recoil_angles[axis],_recoil_velocity[axis],
			0.0,recoil_cam_stiffness,recoil_cam_damping,delta
			)
			_recoil_angles[axis] = clamp(r.x,-angles_max,angles_max)
			_recoil_velocity[axis] = r.y
		angles += _recoil_angles
	#Headbob
	if enable_head_bobbing and !is_dashing:
		var pitch_delta = deg_to_rad(bob_pitch)*speed
		angles.x -= pitch_delta
		
		var roll_delta = deg_to_rad(bob_roll)*speed
		angles.z -= roll_delta
		
		var bob_height = bob_sin*speed*bob_up
		offset.y += bob_height
	
	camera_3d.position = offset
	camera_3d.rotation = angles
	
func add_damage_kick(pitch:float,roll:float,source:Vector3):
	var forward = camera_3d.global_transform.basis.z
	var right = camera_3d.global_transform.basis.x
	var direction = camera_3d.global_position.direction_to(source)
	var forward_dot = direction.dot(forward)
	var right_dot = direction.dot(right)
	
	_damage_kick_pitch = deg_to_rad(pitch)*forward_dot
	_damage_kick_roll = deg_to_rad(roll)*right_dot
	_damage_timer = damage_time

func add_weapon_kick(pitch:float,yaw:float,roll:float):
	_recoil_angles.x += deg_to_rad(pitch)
	_recoil_angles.y += deg_to_rad(randf_range(-yaw,yaw))
	_recoil_angles.z += deg_to_rad(randf_range(-roll,roll))
	
func add_screen_shake(amount:float,seconds:float)->void:
	if _screen_shake_tween:
		_screen_shake_tween.kill()
	
	_screen_shake_tween = create_tween()
	_screen_shake_tween.tween_method(update_screen_shake.bind(amount),0.0,1.0,seconds).set_ease(Tween.EASE_OUT)
	
func update_screen_shake(alpha:float,amount:float)->void:
	amount = remap(amount,0.0,1.0,MIN_SCREEN_SHAKE,MAX_SCREEN_SHAKE)
	var current_shake_amount = amount*(1.0-alpha)
	camera_3d.h_offset = randf_range(-current_shake_amount,current_shake_amount)
	camera_3d.v_offset = randf_range(-current_shake_amount,current_shake_amount)
	
func get_bob_phase()->float:
	return _step_timer
#endregion

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x*mouse_sensitivity)
		camera_controller.rotate_x(-event.relative.y*mouse_sensitivity)
		camera_controller.rotation.x = clamp(camera_controller.rotation.x,-PI/2,PI/2)
	
func regen():
	current_hp = move_toward(current_hp,MAX_HP,regen_rate)
	can_regen = false
	$regen.start()
	
func hit(dmg,source_pos:Vector3 = Vector3.ZERO):
	current_hp -= dmg
	if current_hp <= 0:
		$Control/die.visible = true
	is_healing = false
	regen_timer.stop()
	regen_timer.start()
	
	if source_pos != Vector3.ZERO:
		# Feel free to adjust the 15.0 (pitch) and 10.0 (roll) values to make it punchier
		add_damage_kick(pitch, roll, source_pos)

func _on_regen_timer_timeout() -> void:
	is_healing = true
	can_regen = true


func _on_regen_timeout() -> void:
	can_regen = true
	
func add_inv(x, n):
	$inventory.add_item(x, n)
	
	#MECHANIC
	#we can make the gun to be charged at a charging dock and while chargining we can not use it
	#and then we have to find a fuse to put into our gun because every time we are out of charge
	#it destroys it's fuse.
	#adds a survival/stealth part where you have to roam around the facility unarmed to gather material
	#in vurnalable state
