extends Control

var recipe = {}
signal recipe_clicked

func update_text() -> void:
	var product = recipe.keys()[0]
	var inputs = recipe.values()[0]
	var s = "%s = " % product.id
	for i in inputs:
		s += "%s%d + " % [i[0].id, i[1]]
	
	$Label.text = s
	
func delete_recipe():
	queue_free()

func _on_gui_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("fire"):
		print("em")
		recipe_clicked.emit()
