@tool
extends SubViewportContainer

func _process(delta):
	if Engine.is_editor_hint():
		# Forces the viewport container to redraw every frame in the editor
		queue_redraw()
