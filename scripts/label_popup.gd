extends Node2D

var angle_vector: Vector2
@onready var label: Label = $Label
var text: String = "hey"

func _ready() -> void:
	set_as_top_level(true)
	label.text = text
	
	var tween: Tween = get_tree().create_tween().set_parallel()
	
	var half: bool = randf() < 0.5
	var random_angle: float = deg_to_rad(-randf_range(10.0, 70.0)) if half else deg_to_rad(-randf_range(110.0, 170.0))
	
	angle_vector = label.position.direction_to(Vector2.RIGHT.rotated(random_angle)) 
	
	tween.tween_property(label, "position", angle_vector * 10, 0.2).as_relative().set_delay(0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_delay(0.1)

	await tween.finished
	queue_free()
