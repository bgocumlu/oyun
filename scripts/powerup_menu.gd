extends CanvasLayer

@onready var data: Array


var powerups: Array[String] = [
	"Area+", "Bomb+", "-", 
	"Health", "Mana", "Laser+", 
	"Dash+", "Speed+"
]

func _ready() -> void:
	$Control/HBoxContainer/Button.text = powerups[data[1]]
	$Control/HBoxContainer/Button2.text = powerups[data[2]]
	$Control/HBoxContainer/Button3.text = powerups[data[3]]
	if data:
		get_parent().set_physics_process(false)


func _process(_delta: float) -> void:
	get_parent().play_anim(false)

func _on_button_pressed() -> void:
	if data:
		get_parent().new_powerup = 1
		get_parent().set_physics_process(true)
	queue_free()

func _on_button_2_pressed() -> void:
	if data:
		get_parent().new_powerup = 2
		get_parent().set_physics_process(true)
	queue_free()

func _on_button_3_pressed() -> void:
	if data:
		get_parent().new_powerup = 3
		get_parent().set_physics_process(true)
	queue_free()
