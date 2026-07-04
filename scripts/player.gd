extends CharacterBody3D

var input_dir : Vector2 = Vector2.ZERO
var mouse_sensitivity = 0.005
var speed = 7

var wave_type = 0
var freq_config = 0
var freq_mods = [1, 3 ,5]
var power = 0

var default_shot_dmg = 1
var max_power_timer = 0.3
var current_power = 0
var max_power_reached = false

var holding_fire = false

var hp = 100
var regen_rate = 5
var is_regening = false
var can_regen = false

var freq_cost = [1,20 ,50]
var waste_cost = 10
var mag_size = 100
var mag_count = 0
var sd_amt = 0

var can_shoot = true

func _ready() -> void:
	loader.player = $"."
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	

func _input(event: InputEvent) -> void:
	input_dir = Vector2(-Input.get_axis("bw", "fw"), Input.get_axis("l", "r"))
	
	#DebugDraw3D.draw_arrow_ray(global_position, -$Camera3D.global_basis.z, 10)
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		$Camera3D.rotate_x(-event.relative.y * mouse_sensitivity)
		$Camera3D.rotation.x = clampf($Camera3D.rotation.x, -deg_to_rad(70), deg_to_rad(70))
	
	if Input.is_action_just_pressed("fire"):
		shoot()
		holding_fire = true
	elif Input.is_action_just_released("fire"):
		shoot()
		holding_fire = false
	elif Input.is_action_just_pressed("alt fire"):
		knockback_shot()
	
	if Input.is_action_just_pressed("freq"):
		increase_freq()
	
	#if Input.is_action_just_pressed("wave mode"):
		#match wave_type:
			#0: 
				#wave_type = 1 
				#$Control/wave.text = "wave type: stun"
				#$Control/knck.text = "knockback: false"
			#1: 
				#wave_type = 0
				#$Control/wave.text = "wave type: dmg"
				#$Control/knck.text = "knockback: true"
		
		

func increase_freq():
	freq_config += 1
	if freq_config == 3:
		freq_config = 0
	
	
	
func knockback_shot():
	if $Camera3D/RayCast3D.is_colliding():
		var s = $Camera3D/RayCast3D.get_collider()
		s.knockback(-global_basis.z)
		

func shoot():
	if holding_fire:
		
		if not can_shoot:
			return
		
		if $Camera3D/RayCast3D.is_colliding():
			mag_size -= freq_cost[freq_config]
			var s = $Camera3D/RayCast3D.get_collider()
			print(s.name)
			match wave_type:
				0: 
					var a = false
					if max_power_reached:
						a = true
					s.hit(default_shot_dmg * freq_mods[freq_config], a, freq_config	)
					
					match freq_config:
						1:
							s.group_knockback(global_position)
						2:
							s.group_hit(default_shot_dmg * freq_mods[freq_config], a, freq_config)
		else:
			if freq_config > 0:
				mag_size -= waste_cost
			else:
				mag_size -= freq_cost[freq_config]
				
		can_shoot = false
		$"recoil reset".start()
	
	check_reload()

		
	
func check_reload():
	if mag_size <= 0:
		if mag_count <= 0:
			return
		mag_count -= 1
		mag_size = 120
		
	

func _physics_process(delta: float) -> void:
	
	if holding_fire:
		current_power += delta
		if current_power >= max_power_timer:
			max_power_reached = true
			current_power = max_power_timer
	else:
		max_power_reached = false
		current_power = 0
	
	mag_size = clampf(mag_size, 0, 120)
	
	$Control/stats/pow.text = "power: %.1f" % (current_power / max_power_timer)
	$Control/stats/health.value = clampf(hp, 0, 100)
	$Control/stats/mag.text = "%dx%d" % [mag_count, mag_size]
	$Control/stats/mg.value = clampf(mag_size, 0, 120)
	$Control/stats/freq.text = "freq mod: %d" % (freq_config + 1)
	#$Control/sd.text = "%d x spirit dust" % sd_amt
	$"Control/recoil reset".text = "%.1f" % $"recoil reset".time_left
	
		
	
	
	velocity = (basis.z * input_dir.x + basis.x * input_dir.y) * speed
	
	if is_regening and hp < 100 and can_regen:
		regen()

	
	move_and_slide()
	
func regen():

	hp += regen_rate
	#if hp >= 50:
		#is_regening = false
		#return
		
	hp = clampf(hp, 0, 100)
	can_regen = false
	$regen.start()

func hit(dmg):
	hp -= dmg
	if hp <= 0:
		$Control/die.visible = true
	is_regening = false
	$"regen timer".stop()
	$"regen timer".start()


func _on_regen_timer_timeout() -> void:
	is_regening = true
	can_regen = true


func _on_regen_timeout() -> void:
	can_regen = true


func _on_recoil_reset_timeout() -> void:
	can_shoot = true
	
	
func add_inv(x, n):
	$inventory.add_item(x, n)
