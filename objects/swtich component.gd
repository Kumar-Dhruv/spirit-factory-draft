extends StaticBody3D

@export var door1 : Node3D
@export var door2 : Node3D
@export var state = true

func _ready() -> void:
	state = !state
	toggle_switch()

func toggle_switch():
	state = !state
	if state:
		door1.unlocked = true
		door2.unlocked = false
		
	else:
		door1.unlocked = false
		door2.unlocked = true
