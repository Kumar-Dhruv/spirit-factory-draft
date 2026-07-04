extends Node3D

@export var open_on_switch = false
@export var is_locked = false
@export var switch_id = "prot"

func _ready() -> void:
	loader.switch_toggled.connect(on_switch_toggle)
	
	update_collision()
	
func on_switch_toggle(id, state):
	if id != switch_id:
		return
		
	if state == open_on_switch:
		is_locked = false
	else: is_locked = true
	
	update_collision()
	
func update_collision():
	
	if is_locked:
		$StaticBody3D/CollisionShape3D.disabled = false
		$StaticBody3D/MeshInstance3D.visible = true
		$Label3D.visible = true
	else: 
		$StaticBody3D/CollisionShape3D.disabled = true
		$StaticBody3D/MeshInstance3D.visible = false
		$Label3D.visible = false
	
