extends CharacterBody2D

@export var speed: float = 25
var player_chase: bool = false
var player: Node2D = null
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

var max_health: float = 50
var health: float: 
	set(value):
		health = min(value, max_health)
		$healthbar.health = health

var take_damage: bool = false
var knockback: Vector2 = Vector2.ZERO

var shock: bool = false
@onready var shock_timer: Timer = $shock_timer

func _ready() -> void:
	animation.play("idle_front")
	shock_timer.timeout.connect(get_shocked)
	$healthbar.init_enemy(max_health)
	health = max_health

func _physics_process(delta: float) -> void:
	if health <= 0:
		$CollisionShape2D.disabled = true
		$hurtbox/CollisionShape2D.disabled = true
		$healthbar.visible = false
		animation.play("death")
		await animation.animation_finished
		queue_free()
		return
	elif health <= 25:
		$AnimatedSprite2D.modulate = "ffb150"
		

	if take_damage:
		velocity = knockback * delta * 100
		if not animation.is_playing():
			take_damage = false
			
	elif shock:
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 100)
	
	elif player_chase:
		#position += (player.position - position)/speed * delta * 100
		if not take_damage:
			velocity = position.direction_to(player.position) * speed * delta * 100
		
		if (player.position.x - position.x) < 0:
			animation.flip_h = true
		else:
			animation.flip_h = false
		
		animation.play("walk_side")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 100)
		animation.play("idle_front")
		
	move_and_slide()

func _on_detection_area_body_entered(body: Node2D) -> void:
	player = body
	player_chase = true


func _on_detection_area_body_exited(_body: Node2D) -> void:
	player = null
	player_chase = false
	

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "Hitbox":
		animation.play("hurt")
		health -= area.damage_power
		area.hit_count += 1
		Global.label_popup(self, str(area.damage_power), $damage_label.global_position)
		take_damage = true
		knockback = position.direction_to(area.global_position) * -area.knockback_power
	elif area.name == "LightningHitbox":
		animation.play("hurt")
		$lightning/AnimationPlayer.play("default")
		shock = true
		shock_timer.start()
		await get_tree().create_timer(1.5).timeout
		shock = false
		shock_timer.stop()
	elif area.name == "ProjectileHitbox":
		if area.type == "Electric":
			animation.play("hurt")
			health -= area.damage_power
			area.hit_count += 1
			Global.label_popup(self, str(area.damage_power), $damage_label.global_position)
			take_damage = true
			knockback = position.direction_to(area.global_position) * -area.knockback_power

func get_shocked():
	var damage: float = randi_range(1, 3)
	health -= damage
	Global.label_popup(self, str(damage), $damage_label.global_position, "ffff6e")
