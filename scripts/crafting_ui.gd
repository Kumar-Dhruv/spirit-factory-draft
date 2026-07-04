extends Control

@export var recipe_slot : PackedScene

func build_recipes(recipes : Dictionary):
	for r in recipes.keys():
		var s = recipe_slot.instantiate()
		s.recipe = {r : recipes[r]}
		$GridContainer.add_child(s)
		s.update_text()
		
func delete_recipes():
	for r in $GridContainer.get_children():
		r.queue_free()

func get_recipe_slots():
	return $GridContainer.get_children()

func change_visible(x):
	visible = x
