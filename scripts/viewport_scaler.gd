extends SubViewportContainer

@export_group("Aspect Ratio Settings")
@export var aspect_width: int = 16
@export var aspect_height: int = 9

@export_group("Layout Settings")
@export_range(0.0, 1.0) var screen_height_percentage: float = 1.0

@onready var sub_viewport: SubViewport = get_child(0)

func _ready() -> void:
	# Recalculate if the window size shifts
	get_tree().root.size_changed.connect(recalculate_size)
	recalculate_size()


func recalculate_size() -> void:
	if not sub_viewport:
		return
		
	var valid_width = max(1, aspect_width)
	var valid_height = max(1, aspect_height)
	var target_aspect_ratio: float = float(valid_width) / float(valid_height)

	# 1. FIX: Get the internal, unscaled UI canvas size (ignores window scaling)
	var ui_canvas_size: Vector2 = Vector2(get_tree().root.content_scale_size)

	# 2. Calculate dimensions matching your layout parameters
	var target_height: float = ui_canvas_size.y * screen_height_percentage
	var target_width: float = target_height * target_aspect_ratio

	# Safety clamp if the width overshoots the design layout bounds
	if target_width > ui_canvas_size.x:
		target_width = ui_canvas_size.x * screen_height_percentage
		target_height = target_width / target_aspect_ratio

	var final_size := Vector2(target_width, target_height)

	# 3. Apply the clean, unscaled size to the nodes
	size = Vector2i(final_size)
	sub_viewport.size = Vector2i(final_size)

	# 4. Center it perfectly inside your UI design space
	position = (ui_canvas_size - final_size) / 2.0
