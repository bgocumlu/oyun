extends Node2D

@onready var duration_timer: Timer = $duration
@onready var ghost_timer: Timer = $ghost_timer
@export var dash_cooldown: float = 0.5

const DASH_GHOST = preload("res://scenes/dash_ghost.tscn")
var can_dash: bool = true
var sprite: Sprite2D = null
var player: CharacterBody2D = null

func start_dash(_player: CharacterBody2D, _sprite: Sprite2D, duration: float) -> void:
	duration_timer.wait_time = duration
	duration_timer.start()
	
	ghost_timer.start()
	
	self.sprite = _sprite
	self.player = _player
	instance_ghost()

func instance_ghost():
	var ghost: Sprite2D = DASH_GHOST.instantiate()
	ghost.global_position = player.global_position
	ghost.global_position.y -= 12
	ghost.texture = sprite.texture
	ghost.vframes = sprite.vframes
	ghost.hframes = sprite.hframes
	ghost.frame = sprite.frame
	ghost.flip_h = sprite.flip_h
	player.get_parent().add_child(ghost)

func is_dashing():
	return not duration_timer.is_stopped()

func end_dash():
	ghost_timer.stop()
	can_dash = false
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true


func _on_duration_timeout() -> void:
	end_dash()


func _on_ghost_timer_timeout() -> void:
	instance_ghost()
