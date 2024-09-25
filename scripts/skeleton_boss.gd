extends CharacterBody2D

@onready var player: CharacterBody2D = get_parent().find_child("player")
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var healthbar: ProgressBar = $UI/healthbar

var direction: Vector2
var attack_direction: Vector2

signal on_death
var speed: float = 50

func _ready() -> void:
	set_physics_process(false)
	healthbar.init_enemy(800)

func _process(_delta: float) -> void:

	if healthbar.health <= 0:
		$Hitbox/CollisionShape2D.disabled = true
		$CollisionPolygon2D.disabled = true 
		on_death.emit()
		find_child("FSM").change_state("death")

	direction = player.position - position
	animated_sprite_2d.flip_h = direction.x < 0
	$CollisionPolygon2D.scale.x = -1 if animated_sprite_2d.flip_h else 1
	$hurtbox/CollisionPolygon2D.scale.x = -1 if animated_sprite_2d.flip_h else 1
	$Hitbox/CollisionShape2D.position = Vector2(-23, 0) if animated_sprite_2d.flip_h else Vector2(23, 0)
	
func _physics_process(delta: float) -> void:
	if healthbar.health <= 0:
		return

	velocity = direction.normalized() * speed
	move_and_collide(velocity * delta)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if healthbar.health <= 0:
		return
	if area.name == "Hitbox":
		area.hit_count += 1
		Global.label_popup(self, str(area.damage_power), $damage_label.global_position)
		healthbar.health -= area.damage_power
	elif area.name == "LightningHitbox":
		$lightning/AnimationPlayer.play("default")
		$shock_timer.start()
		await get_tree().create_timer(area.duration, false).timeout
		$shock_timer.stop()
	elif area.name == "ProjectileHitbox":
		if area.type == "Electric":
			healthbar.health -= area.damage_power
			area.hit_count += 1
			Global.label_popup(self, str(area.damage_power), $damage_label.global_position)


func _on_shock_timer_timeout() -> void:
	var damage: float = randi_range(1, 3)
	healthbar.health -= damage
	Global.label_popup(self, str(damage), $damage_label.global_position, "ffff6e")


func death_summon():
	Global.death_summon(player, global_position)
