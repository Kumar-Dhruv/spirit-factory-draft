extends Node3D

@export var door_id : String
@export var unlocked = false


func unlock():
	print("unlocked")
	unlocked = true
	$CollisionShape3D.disabled = true
	
	
