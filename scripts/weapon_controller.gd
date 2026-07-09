class_name WeaponController extends Node

@onready var player: CharacterBody3D = $".."
@onready var ray_cast: RayCast3D = $"../Camera3D/RayCast3D"
@onready var recoil_reset: Timer = $"../recoil reset"
@onready var mg: ProgressBar = $"../Control/stats/mg"
@onready var mag: Label = $"../Control/stats/mag"
@onready var freq: Label = $"../Control/stats/freq"
@onready var gun_pow: Label = $"../Control/stats/pow"
@onready var muzzle: Marker3D = $"../CameraController/Camera3D/gun/muzzle"
@onready var camera_3d: Camera3D = $"../CameraController/Camera3D"
@onready var gun: MeshInstance3D = $"../CameraController/Camera3D/gun"

#connent the weapon class with the player
var CHARGE_EFFECT:PackedScene = preload("res://props/frq_1_effect.tscn")
var charge_effect = null

var holding_fire:bool = false
var can_shoot:bool = true
var mag_size:int = 100
var mag_count:int = 0
var sd_amt:int = 0
var freq_cost:Array[int] = [1,20 ,50]
var waste_cost:int = 10

var wave_type :int= 0
var freq_config :int= 0
var freq_mods :Array[int]= [1, 3 ,5]
var power = 0

var default_shot_dmg = 1
var max_power_timer = 0.3
var current_power = 0
var max_power_reached = false

@export_group("Gun effects")
@export var idle_sway : bool = true
@export var look_sway : bool = true
@export var strafe_tilt : bool = true
@export var weapon_bob : bool = true
@export var recoil_gun : bool = true

@export_group("Weapon Idle Sway")
@export var idle_sway_frequency : float = 0.8
@export var	idle_sway_amplitude : Vector2 = Vector2(0.004,0.003)
@export var idle_sway_stiffness : float = 30.0
@export var idle_sway_damping : float = 6.0

var idle_time : float = 0.0
var _idle_x : float = 0.0
var _idle_y : float = 0.0
var _idle_x_velocity : float = 0.0
var _idle_y_velocity : float = 0.0

@export_group("Look Sway")
@export var look_lag_divisor : float = 45.0
@export var look_lag_rot_max : float = 45.0
@export var look_lag_pos_scale : float = 0.4

#Look sway
var _previoud_camera_rotation : Vector3 = Vector3.ZERO	
var _cam_rot_rate : Vector3 = Vector3.ZERO

var base_weapon_position : Vector3
var base_weapon_rotation : Vector3

@export_group("Gun Strafe Tilt")
@export var strafe_tilt_scale : float = 0.3
@export var strafe_tilt_max : float = 0.08
@export var strafe_tilt_stiffness : float = 80.0
@export var strafe_tilt_damping : float = 10.0

var _strafe_tilt : float = 0.0
var _strafe_tilt_velocity : float = 0.0

@export_group("Weapon Bob")
@export var weapon_bob_amplitude : Vector2 = Vector2(0.04,0.022)
@export var bob_max_speed : float = 10.0
@export var bob_stiffness : float = 60.0
@export var bob_damping : float = 10.0

var _bob_x : float = 0.0
var _bob_x_velocity : float = 0.0
var _bob_y : float = 0.0
var _bob_y_velocity : float = 0.0

@export_group("Recoil Screen")
@export var recoil_cam_pitch : float = 1.25
@export var recoil_cam_yaw : float = 0.25
@export var recoil_cam_roll : float = 0.0
@export var recoil_model_kickback : float = 0.02
@export var recoil_model_rise : float = 8.0

@export_group("Recoil Gun")
@export var recoil_model_stiffness : float = 200.0
@export var recoil_model_damping : float = 11.0
@export var recoil_model_max : float = 0.15
@export var recoil_pitch_max : float = 0.4

var _recoil_z : float = 0.0
var _recoil_z_velocity : float = 0.0
var _recoil_pitch : float = 0.0
var _recoil_pitch_velocity : float = 0.0

func _ready() -> void:
	#pass
	start_effect_one()
	base_weapon_position = gun.position
	base_weapon_rotation = gun.rotation
	
func _process(delta: float) -> void:
	_apply_offsets(delta)
	
func _physics_process(delta: float) -> void:
	mag.text = "%dx%d" % [mag_count, mag_size]
	mg.value = clampf(mag_size, 0, 120)
	gun_pow.text = "power: %.1f" % (current_power / max_power_timer)
	freq.text = "freq mod: %d" % (freq_config + 1)
	
	if holding_fire:
		current_power += delta
		if current_power >= max_power_timer:
			max_power_reached = true
			current_power = max_power_timer
	else:
		max_power_reached = false
		current_power = 0
	
	mag_size = clampf(mag_size, 0, 120)
#instantiating the weapon model

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("fire"):
		holding_fire = true
		shoot()
		#print(muzzle)
		charge_effect.visible = true
		charge_effect.get_node("GPUParticles3D").emitting = true
		#stop_effect_one()
		player.add_weapon_kick(recoil_cam_pitch,recoil_cam_yaw,recoil_cam_roll)
		_add_model_recoil()
		
	elif Input.is_action_just_released("fire"):
		holding_fire = false
		shoot()
		if charge_effect:
			charge_effect.get_node("GPUParticles3D").emitting = false
			charge_effect.visible = false
		#charge_effect.get_node("GPUParticles3D").emitting = true
	elif Input.is_action_just_pressed("alt fire"):
		knockback_shot()
	
	if Input.is_action_just_pressed("freq"):
		increase_freq()
	
func shoot():
	if holding_fire and can_shoot:
		#print(gun_tip)
		#print(holding_fire)
		#print(ray_cast.is_colliding())
		if ray_cast.is_colliding():
			mag_size -= freq_cost[freq_config]
			var enemy = ray_cast.get_collider()
			print(enemy.name)
			match wave_type:
				0: 
					var a = false
					if max_power_reached:
						a = true
					enemy.hit(default_shot_dmg * freq_mods[freq_config], a, freq_config	)
					
					match freq_config:
						1:
							enemy.group_knockback(get_parent().global_position)
						2:
							enemy.group_hit(default_shot_dmg * freq_mods[freq_config], a, freq_config)
		else:
			if freq_config > 0 :
				mag_size -= waste_cost
			else:
				mag_size -= freq_cost[freq_config]
				
		can_shoot = false
		recoil_reset.start()
	
	check_reload()

func check_reload():
	if mag_size <= 0:
		if mag_count <= 0:
			return
		mag_count -= 1
		mag_size = 120
		
func knockback_shot():
	if ray_cast.is_colliding():
		var s = ray_cast.get_collider()
		s.knockback(-get_parent().global_basis.z)
		
func increase_freq():
	freq_config += 1
	if freq_config == 3:
		freq_config = 0
		
func _on_recoil_reset_timeout() -> void:
	can_shoot = true

#region Laser
func start_effect_one()->void:
	if charge_effect == null:
		charge_effect = CHARGE_EFFECT.instantiate()
		muzzle.add_child(charge_effect)
		charge_effect.position = Vector3.ZERO
		charge_effect.visible = false
		
func stop_effect_one()->void:
	if charge_effect:
		charge_effect.queue_free()
		charge_effect = null
#endregion

#region Gun Effects Function

func _update_idle_sway(delta:float)->Vector3:
	idle_time += delta
	
	var speed = Vector2(player.velocity.x,player.velocity.z).length()
	var target_x := 0.0
	var target_y := 0.0
	
	if speed < 0.1:
		target_x = sin(idle_time * idle_sway_frequency) * idle_sway_amplitude.x
		target_y = sin(idle_time * idle_sway_frequency * 0.618) * idle_sway_amplitude.y
	
	var result_x = SpringUtl.apply(_idle_x,_idle_x_velocity,target_x,
	idle_sway_stiffness,idle_sway_damping,delta)
	
	_idle_x = result_x.x
	_idle_x_velocity = result_x.y
	
	var result_y = SpringUtl.apply(_idle_y,_idle_y_velocity,target_y,
	idle_sway_stiffness,idle_sway_damping,delta)
	
	_idle_y = result_y.x
	_idle_y_velocity = result_y.y
	
	var idle_offset = Vector3(_idle_x,_idle_y,0.0)
	return idle_offset

func _update_look_sway(delta:float) -> Vector3:
	if !camera_3d:
		return Vector3.ZERO
		
	var cam_rot = camera_3d.global_rotation
	
	var rot_delta = Vector3(
		angle_difference(_previoud_camera_rotation.x, cam_rot.x),
		angle_difference(_previoud_camera_rotation.y, cam_rot.y),
		0.0
	)
	_previoud_camera_rotation = cam_rot
	
	var max_rad = deg_to_rad(look_lag_rot_max)
	rot_delta.x = clamp(rot_delta.x,-max_rad,max_rad)
	rot_delta.y = clamp(rot_delta.y,-max_rad,max_rad)
	rot_delta.z = 0.0
	
	var interp_speed = (10/delta) / look_lag_divisor
	_cam_rot_rate = _cam_rot_rate.lerp(rot_delta, clamp(interp_speed*delta,0.0,1.0))
	
	var norm_pitch = _cam_rot_rate.x / max_rad if max_rad > 0.0 else 0.0 
	var norm_yaw = _cam_rot_rate.y / max_rad if max_rad > 0.0 else 0.0 
		
	var look_pos : Vector3 = Vector3(
		norm_yaw*look_lag_pos_scale,
		norm_pitch*-look_lag_pos_scale,
		0.0
	)
	return look_pos

func _update_strafe_tilt(delta:float) -> float:
	if !player or !camera_3d:
		return 0.0
		
	var local_velocity = camera_3d.global_transform.basis.inverse()*player.velocity
	var xz : Vector2 = Vector2(local_velocity.x,local_velocity.z)
	var xz_speed : float = xz.length()
	
	var lateral_fraction = abs(xz.x) / xz_speed if xz_speed > 0.1 else 0.0
	
	var tilt_taarget = clamp(
		-local_velocity.x*lateral_fraction*strafe_tilt_scale,
		-strafe_tilt_max,
		strafe_tilt_max
	)
	
	var result = SpringUtl.apply(
		_strafe_tilt,
		_strafe_tilt_velocity,
		tilt_taarget,
		strafe_tilt_stiffness,
		strafe_tilt_damping,
		delta
	)
	
	_strafe_tilt = result.x
	_strafe_tilt_velocity = result.y
	
	return _strafe_tilt

func _update_bob(delta:float) -> Vector3:
	if !gun or !camera_3d or !player:
		return Vector3.ZERO
		
	var phase : float = player.get_bob_phase()
	var speed := Vector2(player.velocity.x,player.velocity.z).length()
	
	var target_x := 0.0
	var target_y := 0.0
	
	if speed > 0.1:
		var speed_factor = clamp(speed/bob_max_speed,0.0,1.0)
		var angle := phase * TAU
		
		target_x = sin(angle) * weapon_bob_amplitude.x * speed_factor
		target_y = sin(angle*2.0) * weapon_bob_amplitude.y * speed_factor
		
	var result_x = SpringUtl.apply(_bob_x,_bob_x_velocity,target_x,bob_stiffness,bob_damping,delta)
	_bob_x = result_x.x
	_bob_x_velocity = result_x.y
		
	var result_y = SpringUtl.apply(_bob_y,_bob_y_velocity,target_y,bob_stiffness,bob_damping,delta)
	_bob_y = result_y.x
	_bob_y_velocity = result_y.y
	
	return Vector3(_bob_x,_bob_y,0.0)

func _add_model_recoil()->void:
	_recoil_z = recoil_model_kickback
	_recoil_pitch += deg_to_rad(recoil_model_rise)
	
func _update_recoil(delta:float) -> Vector3:
	#kickback
	var rz = SpringUtl.apply(_recoil_z,_recoil_z_velocity,
	0.0,recoil_model_stiffness,recoil_model_damping,delta
	)
	_recoil_z = clamp(rz.x,-recoil_model_max,recoil_model_max)
	_recoil_z_velocity = rz.y
	
	#muzzle rise
	var rp = SpringUtl.apply(_recoil_pitch,_recoil_pitch_velocity,
	0.0,recoil_model_stiffness,recoil_model_damping,delta
	)
	
	_recoil_pitch = clamp(rp.x,-recoil_pitch_max,recoil_pitch_max)
	_recoil_pitch_velocity = rp.y
	
	return Vector3(0.0,0.0,_recoil_z)


func _apply_offsets(delta:float) -> void:
	
	var idle_offset = _update_idle_sway(delta) if idle_sway else Vector3.ZERO
	var look_offset = _update_look_sway(delta) if look_sway else Vector3.ZERO
	var tilt_offset = Vector3(0.0,0.0,_update_strafe_tilt(delta)) if strafe_tilt else Vector3.ZERO
	var bob_offset = _update_bob(delta) if weapon_bob else Vector3.ZERO
	
	var recoil_pos = Vector3.ZERO
	var recoil_pitch = 0.0
	if recoil_gun:
		recoil_pos = _update_recoil(delta)
		recoil_pitch = _recoil_pitch
	
	gun.position = base_weapon_position + idle_offset + look_offset + bob_offset + recoil_pos
	
	gun.rotation = base_weapon_rotation + tilt_offset + Vector3(-recoil_pitch,0.0,0.0)
#endregion
