extends Area3D

@export var data : ItemData
var value = 1

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.add_inv(data, value)
		print("pickip")
		get_parent().queue_free()
