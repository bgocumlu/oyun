extends Area2D
class_name Interactable

var data: Array[Variant]

func disable():
	get_child(0).disabled = true

func enable():
	get_child(0).disabled = false

func interaction_data() -> Array[Variant]:
	return data
