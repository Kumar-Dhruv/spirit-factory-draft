@tool
extends Area3D

@export var size = Vector2(20, 20)
@onready var collision_shape = $CollisionShape3D

func _ready() -> void:
	if not Engine.is_editor_hint():
		update_collision_box()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		update_collision_box()


func update_collision_box():
	# This creates a brand new, unique box shape for this specific room
	if collision_shape != null:
		var new_shape = BoxShape3D.new()
		new_shape.size = Vector3(size.x, 0, size.y)
		collision_shape.shape = new_shape
