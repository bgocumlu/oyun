extends Area2D

var target: Node2D
var speed: float = 150
var direction: Vector2 = Vector2.RIGHT

@onready var hitbox: Area2D = $AnimatedSprite2D/Hitbox

func _ready() -> void:
	set_as_top_level(true)
	if target:
		direction = (target.position - position).normalized()
		hitbox.hitbox_owner = target
	if direction.x < 0:
		$AnimatedSprite2D.flip_h = true
		rotation = Vector2.LEFT.rotated(direction.angle()).angle()
	else:
		rotation = Vector2.RIGHT.rotated(direction.angle()).angle()
	
func _physics_process(delta: float) -> void:
	if hitbox.hit_count > 0:
		queue_free()
		return
	position += direction * speed * delta
	

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_area_entered(_area: Area2D) -> void:
	#await get_tree().create_timer(0.1, false).timeout
	queue_free()


func _on_body_entered(_body: Node2D) -> void:
	#await get_tree().create_timer(0.1, false).timeout
	queue_free()
