extends StaticBody3D

@export var ammo : ItemData 
@export var test : ItemData
@export var rsd : ItemData
@export var b : ItemData

var recipes : Dictionary 

func _ready() -> void:
	recipes = {
	ammo : [[rsd, 10]],
	test : [[b, 1], [rsd, 5]]
	}
