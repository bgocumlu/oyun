extends Node2D

@onready var hitbox: Area2D = $ProjectileHitbox
@onready var sprite: Sprite2D = $Projectile
@onready var circle: Sprite2D = $circle

var target = null

var initial_speed: float
var throw_angle_degrees: float
const gravity: float = 9.8
var time: float = 0.0

var initial_position: Vector2
var throw_direction: Vector2

var z_axis: float = 0.0
var is_launch: bool = false

var time_mult: float = 6.0

func _ready() -> void:
	set_as_top_level(true)

func _process(delta: float) -> void:
	time += delta * time_mult
	
	if is_launch:
		z_axis = initial_speed * sin(deg_to_rad(throw_angle_degrees)) * time - 0.5 * gravity * pow(time, 2)
		
		if z_axis > 0:
			var x_axis: float = initial_speed * cos(deg_to_rad(throw_angle_degrees)) * time
			global_position = initial_position + throw_direction * x_axis
			$Projectile.position.y = -z_axis
		else:
			$ProjectileHitbox/CollisionShape2D.disabled = false
			circle.visible = true
			await get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).tween_property(circle, "scale", Vector2(0.4, 0.4), 0.1).finished
			queue_free()

func launch_projectile(initial_pos: Vector2, direction: Vector2, desired_distance: float, desired_angle_deg: float):
	initial_position = initial_pos
	throw_direction = direction.normalized()
	
	throw_angle_degrees = desired_angle_deg
	initial_speed = pow(desired_distance * gravity / sin(2 * deg_to_rad(desired_angle_deg)), 0.5)
	
	global_position = initial_position
	time = 0.0
	is_launch = true
