extends Node3D

var ray : RayCast3D
var inv : Node3D
var storage : Node3D
var craft : Control
var interaction_state = false

func _ready() -> void:
	ray = get_parent().get_node("Camera3D/interactioncast")
	inv = get_parent().get_node("inventory")
	storage = get_parent().get_node("storage inventory")
	craft =  get_parent().get_node("crafting ui")
	inv.load_inv()
	storage.change_visible(false)
	craft.change_visible(false)
	
func _unhandled_input(event:InputEvent)->void:
	if event.is_action_pressed("quit"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("interact"):
		interaction_state = !interaction_state
		check_for_interaction()
		if not interaction_state:
			close_storage_window()
			close_craft_window()
		
		
func connect_slot_signals():
	var islots = inv.get_ui_slots()
	for si in islots:
		si.slot_clicked.connect(storage_switch.bind(si))
	
	var sslots = storage.get_ui_slots()
	for ss in sslots:
		ss.slot_clicked.connect(storage_switch.bind(ss))

func connect_recipe_signals():
	var slots = craft.get_recipe_slots()
	for s in slots:
		s.recipe_clicked.connect(validate_recipe.bind(s))
		
func check_for_interaction():
	
	if not ray.is_colliding():
		return
	
	var x : Node3D = ray.get_collider()
	if x.is_in_group("doors"):
		if x.unlocked:
			x.unlock()
		else:
			var s = inv.check_for_item(x.door_id)
			if s:
				x.unlock()
			else:
				print("key not found")
				
	elif x.is_in_group("storage") and interaction_state:
		var storage_id = x.inventory_id
		storage.inventory_id = storage_id
		#print(storage_id)
		storage.load_inv(storage_id)
		storage.change_visible(true)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		connect_slot_signals()
	
	elif x.is_in_group("crafting") and interaction_state:
		craft.build_recipes(x.recipes)
		craft.change_visible(true)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		connect_recipe_signals()
		


func close_storage_window():
	storage.change_visible(false)
	storage.inventory_id = ""
	storage.delete_slots()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func close_craft_window():
	craft.change_visible(false)
	craft.delete_recipes()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func storage_switch(slot):
	match slot.inv_id:
		inv.inventory_id:
			var i = inv.get_item(slot.slot_index)
			var r = storage.add_item(i.keys()[0], i.values()[0], true)
			print(r)
			if r:
				inv.delete_slot(slot.slot_index)
			connect_slot_signals()
		storage.inventory_id:
			var i = storage.get_item(slot.slot_index)
			var r = inv.add_item(i.keys()[0], i.values()[0], true)
			print(r)
			if r:
				storage.delete_slot(slot.slot_index)
			connect_slot_signals()
				
func validate_recipe(slot):
	print("recipe clicked")
	var product = slot.recipe.keys()[0]
	var inputs = slot.recipe.values()[0]
	
	for i in inputs:
		var r = inv.check_item_qty(i[0], i[1])
		if not r:
			print("not enuf")
			return 
	
	for i in inputs:
		inv.take_items(i[0], i[1])
	
	inv.add_item(product, 1)
	
