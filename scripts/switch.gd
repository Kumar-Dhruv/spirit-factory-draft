extends Node3D

@export var switch_id = "prot"

@export var state = false

var is_player = false

func _ready() -> void:
	if state:
		$t.text = "ON"
	else:
		$t.text = "OFF"
		
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("interact") and is_player:
		state = !state
		if state:
			$t.text = "ON"
		else:
			$t.text = "OFF"
			
		loader.switch_toggled.emit(switch_id, state)
		print("switched")
	


func _on_area_3d_body_entered(body: Node3D) -> void:
	is_player = true
	$Control.visible = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	is_player = false
	$Control.visible = false
