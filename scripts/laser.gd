extends Node2D

@onready var hitbox: CollisionShape2D = $Line2D/Hitbox/CollisionShape2D
@onready var hitbox_area: Area2D = $Line2D/Hitbox
@onready var line: Line2D = $Line2D

var max_range: float = 12000

var based_width: float = 700
var width_y: float = based_width
var shoot: bool = false

@onready var pulse_timer: Timer = $pulse
var pulse: bool = true

var mouse_position: Vector2 = Vector2.ZERO

signal pulse_signal

func start_shooting():
	shoot = true
	hitbox.disabled = false
	$pulse.start()

func end_shooting():
	shoot = false
	hitbox.shape.b = Vector2.ZERO
	hitbox.disabled = true
	$pulse.stop()
	$Line2D.points[1] = $Line2D.points[0]
	mouse_position = Vector2.ZERO

func shootf(pos: Vector2, turn_speed: float):
	if not shoot:
		return
		
	$Line2D.width = width_y
	
	if mouse_position == Vector2.ZERO:
		mouse_position = pos
	elif mouse_position != pos:
		mouse_position += mouse_position.direction_to(pos).normalized() * turn_speed
		
	var max_cast_to: Vector2 = mouse_position.normalized() * max_range
	$RayCast2D.target_position = max_cast_to
	
	if $RayCast2D.is_colliding():
		$Reference.global_position = $RayCast2D.get_collision_point()
		$Line2D.set_point_position(1, $Line2D.to_local($Reference.global_position))
	else:
		$Reference.global_position = $RayCast2D.target_position
		$Line2D.points[1] = $Reference.global_position
		
	hitbox.shape.b = $Line2D.points[1]

func _on_pulse_timeout() -> void:
	hitbox.disabled = pulse
	pulse = not pulse
	pulse_signal.emit()
