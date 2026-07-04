extends Node3D

@export var max_player_distance = 30
@onready var enemy = preload("res://actors/enemy.tscn")
var enemies = {}
var room_activated = false

func _ready() -> void:
	for x : Node3D in get_parent().get_children():
		if x.is_in_group("enemy"):
			enemies[x] = x.global_position
			x.is_inactive = true
			x.tree_exited.connect(on_enemy_destroyed.bind(x))
			x.reset.connect(reset.bind(x))
	
func reset(x):
	if room_activated:
		return
	x.default()
	x.is_inactive = true
	x.global_position = enemies[x]

func _on_spawner_body_entered(body: Node3D) -> void:
	for x in enemies:
		x.is_inactive = false
	room_activated = true
	#print("activated")
	
func on_enemy_destroyed(x):
	if enemies.has(x):
		enemies.erase(x)


func _on_spawner_body_exited(body: Node3D) -> void:
	room_activated = false
