extends Area2D

@onready var speed: float = 250

@onready var hitbox: Area2D = $AnimatedSprite2D/Hitbox
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_collision_shape: CollisionShape2D = $AnimatedSprite2D/Hitbox/CollisionShape2D
var target = null

func _ready() -> void:
	set_as_top_level(true)
	await animated_sprite.animation_finished
	set_physics_process(false)
	hitbox_collision_shape.disabled = true
	$CollisionShape2D.disabled = true
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	queue_free()

func _physics_process(delta: float) -> void:
	position += Vector2.RIGHT.rotated(rotation) * speed * delta
	if hitbox.hit_count > 0:
		queue_free()

func _on_area_entered(_area: Area2D) -> void:
	set_physics_process(false)
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	queue_free()


func _on_body_entered(_body: Node2D) -> void:
	set_physics_process(false)
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	queue_free()
