extends Node3D

@export var id = "X"

func _ready() -> void:
	$Label3D.text = "Key %s" % id

func _on_area_3d_body_entered(body: Node3D) -> void:
	#loader.add_key(id)
	queue_free()
