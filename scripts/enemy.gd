extends CharacterBody3D

@onready var nav : NavigationAgent3D = $NavigationAgent3D
@onready var player : CharacterBody3D = loader.player

var speed = 5
var max_speed = 6
var min_speed = 3
var chase_speed = 15
var agitated_chase_speed = 30
var mov_dir
var chase_pos = Vector3.ZERO
var agitated_chase_pos = Vector3.ZERO
var dist_cat = 0
var agitated_lock_chance = 0.3
var crimson_lock_chance = 0.5

var cooldoown_c = [1.5, 1.5, 1]
var cc
var agitated_cooldown = 1
var crimson_cooldown = 0.9

var max_chase_cirle = 15

var is_chasing = false
var is_stunned = false
var is_knockbacked = false
var is_inactive = false
var is_crimson = false
var is_dmging = false
var can_dmg = false
var is_player = false

@export var is_agitated = false

var hp = 5
var normal_hp = 5
var agitated_hp = 2
var crimson_hp = 6

var knockback_spd = 50
var knockback_friction = 150
var knockback_heavy_friction_mod = 2
var knockback_velo : Vector3
var is_heavy_friction = false

var sm : StandardMaterial3D
var nm : StandardMaterial3D
var am : StandardMaterial3D
var cm : StandardMaterial3D

var base_dmg = 1.5
var max_dmg_multiplier = 2.5
var dmg_circle_start = 3
var dmg_circle_end = 2
var agitated_dmg_circle = 2.5
var crimson_damage_multipliyer = 3

var hit_stun_chance = 0.3

var drop_amt = [28, 35, 40]
var sd : PackedScene

var reset_distance = 30
signal reset 

@export var dmg_graph : Curve

func _ready() -> void:
	cc = cooldoown_c.pick_random()
	$chase.start(cooldoown_c.pick_random())
	#cc = agitated_cooldown
	sm = preload("res://resources/stunned.tres")
	nm = preload("res://resources/normal.tres")
	am = preload("res://resources/agitated.tres")
	cm = preload("res://resources/crimson.tres")
	
	sd = preload("res://objects/spirit_dust.tscn")
	
	
	$Label3D.text = str(hp)
	
	if is_agitated:
		agitate()

func default():
	is_chasing = false
	is_stunned = false
	is_knockbacked = false
	$dmg.stop()
	$"dmg reset".stop()
	$"hit stun".stop()
	
	if is_crimson: hp = 5
	elif is_agitated: hp = 3
	else: hp = 10
	
	
	

func _physics_process(delta: float) -> void:
	$Label3D.text = str(hp)
	
	var dist = (global_position - player.global_position).length()
	if dist <= 7:
		dist_cat = 0
		#loader.switch($".", 0)
	elif dist <= 15:
		dist_cat = 1
		#loader.switch($".", 1)
	else:
		dist_cat = 2 
		#loader.switch($'.', 2)
	
	if is_inactive:
		return
		
	if (player.global_position - global_position).length() >= reset_distance:
		reset.emit()
		
	
	
	#cc -= delta
	#if cc <= 0:
		#is_chasing = true
		#if is_agitated:
			#cc = agitated_cooldown
		#else:
			#cc = cooldoown_c.pick_random()
		
	if not is_agitated:
		if not is_stunned and not is_knockbacked:
			if is_chasing:
				chase()
			else:
				follow()
		elif is_stunned:
			velocity = Vector3.ZERO
		
		if is_knockbacked:
			velocity = knockback_velo
			var k = knockback_friction
			knockback_velo = knockback_velo.move_toward(Vector3.ZERO, k * delta)
			if velocity.length() <= 0:
				is_knockbacked = false
				velocity = Vector3.ZERO
	
	else:
		if is_chasing:
			agitated_chase()
		else:
			velocity = Vector3.ZERO
			
	
	
	move_and_slide()

func dmg_player():
	
	if not is_player and not is_agitated:
		return
	
	if is_inactive:
		return
	
	var y = 0
	
	if is_crimson:
		y = base_dmg * crimson_damage_multipliyer
	elif is_agitated:
		y = base_dmg * max_dmg_multiplier
	else:
		var m = base_dmg * (max_dmg_multiplier - 1) / (dmg_circle_start - dmg_circle_end)
		var x = (player.global_position - global_position).length()
		var c = base_dmg + m * dmg_circle_start 
		
		y = -m * x + c
	
	player.hit(abs(y))
	#
	#
	#$"dmg reset".stop()
	#
	#if $dmg.is_stopped():
		#$dmg.start()
	#elif $dmg.paused:
		#$dmg.paused = false
		#
	
	pass
	
	
func follow():
	nav.target_position = player.global_position
	if not nav.is_target_reached():
		mov_dir = (nav.get_next_path_position() - global_position).normalized()
		velocity = mov_dir * speed
		

func chase():
	if chase_pos == Vector3.ZERO:
		var a = get_chase_pos()
		if a:
			chase_pos = a
		else:
			is_chasing = false
			return
	
	nav.target_position = chase_pos
	#DebugDraw3D.draw_sphere(chase_pos)
	
	if not nav.is_navigation_finished():
		mov_dir = (nav.get_next_path_position() - global_position).normalized()
		velocity = mov_dir * chase_speed
	else:
		is_chasing = false
		chase_pos = Vector3.ZERO

func agitated_chase():
	if agitated_chase_pos == Vector3.ZERO:
		var a = get_agitated_chase_pos()
		if a:
			agitated_chase_pos = a
		else:
			is_chasing = false
			agitated_chase_pos = Vector3.ZERO
		
	
	nav.target_position = agitated_chase_pos
	#DebugDraw3D.draw_sphere(agitated_chase_pos)
	#
	if not nav.is_navigation_finished():
		mov_dir = (nav.get_next_path_position() - global_position).normalized()
		velocity = mov_dir * agitated_chase_speed
	else:
		is_chasing = false
		agitated_chase_pos = Vector3.ZERO
		velocity = Vector3.ZERO
		
func get_chase_pos():
	
	var valid_angle_multipler = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
	
	if dist_cat == 1:
		valid_angle_multipler = [1, 2, 3, 4]

	var n = valid_angle_multipler.pick_random()
	var valid_angle = deg_to_rad(30 * n)
	var dist = (global_position - player.global_position).length()
	#var x = lerpf(dmg_circle_start, max_chase_cirle, randf()) * Vector2(cos(valid_angle), sin(valid_angle))
	var x = clampf(dist, 0, max_chase_cirle) * Vector2(cos(valid_angle), sin(valid_angle))
	var chase_pos = player.global_position + Vector3(x.x, global_position.y, x.y)
	return chase_pos


func get_agitated_chase_pos():
	var x
	var y
	var valid_angle_multipler = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
	var u 
	var v = randf()
	var x1 = player.global_position.x
	var y1 = player.global_position.z
	var x2 = global_position.x
	var y2 = global_position.z
	var r1 = max_chase_cirle
	var r2 = 5
	
	var c = agitated_lock_chance
	if is_crimson:
		c = crimson_lock_chance
	if (randf() > c):
		u = deg_to_rad(valid_angle_multipler.pick_random() * 30)
	else:
		u = atan2(y1 - y2, x1 - x2)
		u += randf_range(-1, 1)

	x = (1 - v) * (x2 + r2 * cos(u)) + v * (x1 + r1*cos(u))
	y = (1 - v) * (y2 + r2 * sin(u)) + v * (y1 + r1*sin(u))
	return Vector3(x, 0, y)
	


func hit(dmg, agitate=false, mod=0):
	hp -= dmg
	if hp <= 0:
		if is_agitated and not is_crimson:
			var s : Node3D = sd.instantiate()
			s.get_node("pickup").value = drop_amt[mod]
			s.global_position = position
			get_parent().add_child(s)
			print("s")

		if is_crimson:
			queue_free()
			return
		else:
			if (mod == 2 and is_agitated) or not is_agitated:
				queue_free()
				return
			else:
				is_inactive = true
				default()
				$crimson.start()
				visible = false
				$CollisionShape3D.disabled = true
				$Area3D/CollisionShape3D.disabled = true
				$chase.stop()
				print("crimson")
	
	if agitate and not is_agitated:
		agitate()
	elif agitate and is_agitated and (mod == 2):
		queue_free()
	elif not agitate and not is_agitated:
		var x = randf()
		if x < hit_stun_chance and not is_agitated:
			stun(true)
		
			

func agitate(crimson=false):
	is_agitated = true
	is_chasing = true
	$MeshInstance3D.set_surface_override_material(0, am)
	if not crimson:
		if hp > agitated_hp:
			hp = agitated_hp
	else:
		hp = crimson_hp
		$MeshInstance3D.set_surface_override_material(0, cm)
		agitated_cooldown = crimson_cooldown
	
	$"dmg reset".wait_time = 0.2
	

func stun(hit_stun=false):
	is_stunned = true
	$MeshInstance3D.set_surface_override_material(0, sm)
	if not hit_stun:
		$"stun timer".start()
	else:
		$"hit stun".start()

func knockback(dir):

	is_knockbacked = true
	knockback_velo = dir * knockback_spd

func group_knockback(pos : Vector3, heavy_friction = false):
	var x = $"knockback group".get_overlapping_bodies()
	for e : Node3D in x:
		if not e.is_in_group("enemy"):
			continue
		
		var d : Vector3 = (global_position - pos).normalized()
		d.y = 0
		
		e.knockback(d)

func group_hit(dmg, agitate=false, mod=2):
	var x = $"hit group".get_overlapping_bodies()
	for e: Node3D in x:
		
	
		if not e.is_in_group("enemy") or e == self:
			continue
		
		e.hit(dmg, agitate, mod)

func _on_stun_timer_timeout() -> void:
	is_stunned = false
	$MeshInstance3D.set_surface_override_material(0, nm)


func _on_dmg_reset_timeout() -> void:
	$dmg.stop()
	$dmg.paused = false


func _on_dmg_timeout() -> void:
	dmg_player()
	


func _on_hit_stun_timeout() -> void:
	is_stunned = false
	$MeshInstance3D.set_surface_override_material(0, nm)


func _on_crimson_timeout() -> void:
	is_inactive = false
	is_crimson = true
	agitate(true)
	visible = true
	$CollisionShape3D.disabled = false
	$Area3D/CollisionShape3D.disabled = false
	$chase.start()
	hp = 5
	print("crimsoned")


func _on_chase_timeout() -> void:
	is_chasing = true
	speed = randi_range(min_speed, max_speed)
	if is_agitated:
		$chase.start(agitated_cooldown)
	else:
		$chase.start(cooldoown_c[dist_cat])


func _on_area_3d_body_entered(body: Node3D) -> void:
	$"dmg reset".stop()
	
	if $dmg.is_stopped():
		if is_agitated or is_crimson:
			dmg_player()
			print("damaged")
		$dmg.start()
	elif $dmg.paused:
		$dmg.paused = false
		
	is_player = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	$dmg.paused = true
	$"dmg reset".start()
	
	is_player = false
