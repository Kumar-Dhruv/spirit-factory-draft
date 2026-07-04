extends StaticBody3D

@export var inventory_data : InventoryData
@export var inventory_id = "locker"

func _ready() -> void:
	inventory_data.update_data()
	loader.save_inv(inventory_id, inventory_data)
