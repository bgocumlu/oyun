extends Node2D

var target: Node2D
var speed: float = 120
var direction: Vector2 = Vector2.RIGHT

var type: int = 0
var value: int = 5

@onready var hitbox: Area2D = $Sprite2D/Orb
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	set_as_top_level(true)
	if target:
		direction = (target.position - position).normalized()
	
	hitbox.damage_power = value
	hitbox.type = type
	
	if hitbox.type == 0:
		sprite.modulate = Color(0, 25500, 0)
	elif hitbox.type == 1:
		sprite.modulate = Color(0, 0, 25500)
	
	await get_tree().create_timer(10.0, false).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	if hitbox.hit_count > 0:
		queue_free()
		return
	position += direction * speed * delta


func _on_timer_timeout() -> void:
	if target:
		direction = (target.position - position).normalized()
