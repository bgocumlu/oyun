extends CharacterBody2D

@onready var player: CharacterBody2D = get_parent().find_child("player")
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var character: CharacterBody2D

var health: float = 20

func _ready() -> void:
	set_physics_process(false)
	await animated_sprite_2d.animation_finished
	set_physics_process(true)
	animated_sprite_2d.play("idle")
	$hitbox_timer.start()

func _physics_process(delta: float) -> void:
	if health <= 0:
		animated_sprite_2d.play("death")
		$hitbox_timer.stop()
		$Hitbox/CollisionShape2D2.disabled = true
		await animated_sprite_2d.animation_finished
		queue_free()
		return
		
	var direction: Vector2
	if player:
		direction = player.position - position
	else:
		direction = character.position - position
		
	velocity = direction.normalized() * 60
	move_and_collide(velocity * delta)
	

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "Hitbox":
		area.hit_count += 1
		Global.label_popup(self, str(area.damage_power), $damage_label.global_position)
		health -= area.damage_power
	elif area.name == "LightningHitbox":
		$lightning/AnimationPlayer.play("default")
		$shock_timer.start()
		await get_tree().create_timer(area.duration, false).timeout
		$shock_timer.stop()
	elif area.name == "ProjectileHitbox":
		if area.type == "Electric":
			health -= area.damage_power
			area.hit_count += 1
			Global.label_popup(self, str(area.damage_power), $damage_label.global_position)

func _on_shock_timer_timeout() -> void:
	var damage: float = randi_range(1, 3)
	health -= damage
	Global.label_popup(self, str(damage), $damage_label.global_position, "ffff6e")


func _on_hitbox_timer_timeout() -> void:
	$Hitbox/CollisionShape2D2.disabled = not $Hitbox/CollisionShape2D2.disabled
