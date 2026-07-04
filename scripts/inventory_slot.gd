extends Control

var slot_index
var inv_id

signal slot_clicked

func update_text(text):
	$Label.text = text

func delete_slot():
	queue_free()
	
func _on_gui_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("fire"):
		slot_clicked.emit()
