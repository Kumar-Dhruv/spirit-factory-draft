extends Node3D

var inventory : InventoryData
var label_setting : LabelSettings
var slot : PackedScene
@export var inventory_id : String
@export var size : int

func _ready() -> void:
	label_setting = preload("res://resources/invlabel.tres")
	slot = preload("res://UI/inventory_slot.tscn")
	
func load_inv(id = inventory_id):
	inventory = loader.load_inv(id, size)
	update_inventory()

func change_visible(x):
	$Inventory.visible = x

func add_item(item, n, dont_stack=false):
	var x = inventory.add_item(item, n, dont_stack)
	#if x > 0:
		#for i in range(x):
			##var label := Label.new()
			##label.text = "%s%d" % [item.id, n]
			##label.label_settings = label_setting
			##$Inventory/GridContainer.add_child(label)
			#
			#var sl = slot.instantiate()
			#sl.update_text("%s%d" % [item.id, n])
			#$Inventory/GridContainer.add_child(sl)
	update_inventory()
	
	return x
	
func update_inventory():
	var j = 0
	
	for x in $Inventory/GridContainer.get_children():
		x.queue_free()
	
	for s : Dictionary in inventory.slots:
		if s.is_empty():
			j += 1
			continue
		var sl = slot.instantiate()
		sl.update_text("%s%d" % [s.keys()[0].id, s.values()[0]])
		sl.slot_index = j
		sl.inv_id = inventory_id
		$Inventory/GridContainer.add_child(sl)
		#l[i].update_text("%s%d" % [s.keys()[0], s.values()[0]])
		#l[i].slot_index = j
		j += 1
		
func check_for_item(id):
	return inventory.check_for_item(id)
	
func delete_slots():
	for x in $Inventory/GridContainer.get_children():
		x.queue_free()
		
func delete_slot(idx):
	inventory.remove_item(idx)
	update_inventory()
	
func get_item(idx):
	return inventory.slots[idx]
		
func get_ui_slots():
	return $Inventory/GridContainer.get_children()
	
func check_item_qty(item, qty):
	return inventory.check_for_qty(item, qty)
	
func take_items(item, qty=1):
	inventory.take_items(item, qty)
	update_inventory()
