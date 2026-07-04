class_name InventoryData
extends Resource

@export var placed_items : Array[ItemData]
@export var placed_qty : Array[int]

var slots : Array[Dictionary]
var slots_filled = 0
@export var size = 6


func _init() -> void:
	slots.resize(size)
	slots.fill({})
	
	
func update_data():
		
	slots.resize(size)
	slots.fill({})
	
	var i = 0
	for item in placed_items:
		slots[i] = {item : placed_qty[i]}
		print(item.id)
		i += 1
		
	print(slots)
	

func add_item(item : ItemData, qty=1, dont_stack=false):
	var n = qty
	var item_added = false
	
	if item.stackable and not dont_stack:
		for i in range(slots.size()):
			if n <= 0:
				break
			
			var s : Dictionary = slots[i]
			if s.has(item):
				var x = s[item]
				if x < item.stack_limit:
					var diff = item.stack_limit - x
					var fill = min(diff, n)
					slots[i][item] += fill
					n -= fill
					item_added = true
	
	
	if n > 0:
		for i in range(slots.size()):
			if n <= 0:
				break
				
			if slots[i].is_empty():
				var fill = min(item.stack_limit, n)
				slots[i] = {item : fill}
				item_added = true
				n -= fill
	
	return item_added
	
func take_items(item: ItemData, qty=1):
	var n = qty
	
	for i in range(slots.size()):
		if n <= 0:
			break
		
		var s : Dictionary = slots[i]
		if s.has(item):
			var x = s[item]
			if x > n:
				slots[i][item] -= n
				n = 0
				break
			else:
				slots[i] = {}
				n -= x

func check_for_qty(item, qty):
	var n = 0
	for i in range(slots.size()):
		if n >= qty:
			return true
		
		var s : Dictionary = slots[i]
		if s.has(item):
			var x = s[item]
			n += x
		
	
	if n < qty:
		return false

func check_for_item(id):
	for x : Dictionary in slots:
		if (x.keys().size()) > 0:
			if x.keys()[0].id == id:
				return true
	return false
	
func remove_item(idx):
	slots[idx] = {}
	


func _to_string() -> String:
	return str(slots)
