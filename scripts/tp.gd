extends Node3D

@export var tp_id = "E"
@export var tp_target = "B"
@export var is_disabled = false
@export var open_on_switch = false
@export var switch_id = "prot"
@export var reciver_only = false
@export var always_enabled = false


var is_player = false

func _ready() -> void:
	$Label3D.text = "TP to %s" % tp_target
	if reciver_only:
		$CPUParticles3D.emitting = false
		$Label3D.visible = false
		
	if not always_enabled:
		loader.switch_toggled.connect(on_switch_toggle)
		
	loader.verify_tp.connect(on_tp)
	update_collisions()

func update_collisions():
	if is_disabled:
		$Area3D/CollisionShape3D.disabled = true
		visible = false
	else:
		$Area3D/CollisionShape3D.disabled = false
		visible = true

func on_switch_toggle(id, state):
	if id != switch_id:
		return
		
	if state == open_on_switch:
		is_disabled = false
	else:
		is_disabled = true
	
	update_collisions()

func on_tp(id, target):
	if id == tp_target and target == tp_id:
		loader.tp_player(global_position)
		
func _input(event: InputEvent) -> void:
	if reciver_only: 
		return
	if Input.is_action_just_pressed("interact") and is_player:
		loader.verify_tp.emit(tp_id, tp_target)

func _on_area_3d_body_entered(body: Node3D) -> void:
	is_player = true
	$Control.visible = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	is_player = false
	$Control.visible = false
