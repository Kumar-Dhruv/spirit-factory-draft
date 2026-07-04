extends Node
@onready var player : CharacterBody3D

var inventories = {}

signal switch_toggled(id, state)

signal verify_tp(id, target)

signal reset_enemy(enemy)

func tp_player(pos):
	player.global_position.x = pos.x
	player.global_position.z = pos.z
	

func load_inv(id, size):
	var i
	
	if not inventories.has(id):
		i = InventoryData.new()
		i.size = size
		inventories[id] = i
	else:
		i = inventories[id]
	
	print("loaded")
	return i
	
func save_inv(id, inv):
	inventories[id] = inv
	print("saved")
	#print(inventories)
