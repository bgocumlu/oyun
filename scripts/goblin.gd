extends CharacterBody2D

@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var healthbar: ProgressBar = $healthbar
@onready var debug: Label = $debug
@onready var shock_timer: Timer = $misc/shock_timer

@onready var hurtbox: CollisionShape2D = $Sprite2D/hurtbox/CollisionShape2D
@onready var hitbox: CollisionShape2D = $Sprite2D/Hitbox/CollisionShape2D
@onready var detection: CollisionShape2D = $Sprite2D/detection/CollisionShape2D

var target: CharacterBody2D

signal on_death

var shock: bool = false
var knockback: Vector2 = Vector2.ZERO
var direction: Vector2
var speed: float = 50
var bomb_count: int = 1
var entry: bool = true

enum States {
	Idle,
	Wandering,
	Follow,
	Attack,
	Throw,
	Hit,
	Shocked,
	Dead,
}

@export var max_health: float = 100
@export var wander: bool = true

var current_state: States

func _ready() -> void:
	randomize()
	current_state = States.Idle
	healthbar.init_enemy(max_health)


func _process(_delta: float) -> void:
	if not is_instance_valid(target):
		target = null
		
	if healthbar.health <= 0:
		hitbox.disabled = true
		direction = Vector2.ZERO
		if current_state != States.Dead:
			on_death.emit()
			change_state(States.Dead)
		return
		
	if target:
		var head: Vector2 = target.position
		head.y -= 8
		direction = head - position
		$Sprite2D.scale.x = -1 if direction.x < 0 else 1
	elif velocity.x:
		$Sprite2D.scale.x = -1 if velocity.x < 0 else 1


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		target = null

	if debug.visible:
		debug.text = States.keys()[current_state]
	match current_state:
		States.Idle:
			_idle_state(delta)
		States.Wandering:
			_wandering_state(delta)
		States.Follow:
			_follow_state(delta)
		States.Attack:
			_attack_state(delta)
		States.Throw:
			_throw_state(delta)
		States.Hit:
			_hit_state(delta)
		States.Shocked:
			_shocked_state(delta)
		States.Dead:
			_dead_state(delta)
	move_and_slide()


func _idle_state(_delta: float):
	if entry:
		entry = false
		animation.play("idle")
		await get_tree().create_timer(randf_range(1, 9), false).timeout
		if not target and wander:
			change_state(States.Wandering)

	velocity = Vector2.ZERO
	if target: 
		change_state(States.Follow)

func _follow_state(_delta: float):
	if entry:
		entry = false
		animation.play("walk")

	if not target:
		change_state(States.Idle)
		direction = Vector2.ZERO
		return

	velocity = direction.normalized() * speed
	
	var length: float = direction.length()
	if length < 28 and is_instance_valid(target) and healthbar.health > 0:
		change_state(States.Attack)
	elif length > 120 and is_instance_valid(target) and bomb_count > 0:
		change_state(States.Throw)

func _wandering_state(_delta: float):
	if entry:
		entry = false
		animation.play("walk")
		velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * speed * 0.5
		await get_tree().create_timer(randf_range(1, 3), false).timeout
		change_state(States.Idle)
	
func _hit_state(delta: float):
	if entry:
		entry = false

	velocity = knockback * delta * 100
	if not animation.current_animation.begins_with("hit"):
		change_state(States.Follow)
		velocity = Vector2.ZERO
	
func _attack_state(_delta: float):
	if entry:
		entry = false
		animation.play("attack")
		await animation.animation_finished
		entry = true
		var length: float = direction.length()
		if length >= 28:
			change_state(States.Follow)

	if not target:
		change_state(States.Idle)
		direction = Vector2.ZERO
		return
		
	velocity = direction.normalized() * speed

func _throw_state(_delta: float):
	if entry:
		entry = false
		if bomb_count > 0:
			bomb_count -= 1
			var projectile = preload("res://scenes/projectile.tscn").instantiate()
			projectile.launch_projectile(global_position, global_position.direction_to(target.global_position), 200, 60)
			animation.play("idle")
			velocity *= 0.2
			await get_tree().create_timer(0.3, false).timeout
			get_parent().add_child(projectile)
			projectile.sprite.modulate = "d0ff00"
			projectile.circle.modulate = "ff5c0018"
			projectile.hitbox.set_collision_layer_value(4, true)
			projectile.hitbox.set_collision_layer_value(3, false)
			change_state(States.Follow)
		else:
			change_state(States.Follow)

func _shocked_state(_delta: float):
	if entry:
		entry = false
		
	velocity = Vector2.ZERO
	if not shock:
		change_state(States.Idle)

func _dead_state(_delta: float):
	if entry:
		entry = false
		animation.play("death")
		velocity = Vector2.ZERO
		await animation.animation_finished
		if is_instance_valid(self):
			queue_free()


func change_state(state: States):
	entry = true
	current_state = state

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if healthbar.health <= 0 or current_state == States.Dead:
		return
	if area.name == "Hitbox":
		target = area.hitbox_owner as CharacterBody2D
		detection.scale = Vector2(2.5, 2.5)
		animation.play("hit")
		healthbar.health -= area.damage_power
		area.hit_count += 1
		Global.label_popup(self, str(area.damage_power), $misc/damage_label.global_position)
		knockback = position.direction_to(area.global_position) * -area.knockback_power
		change_state(States.Hit)
	elif area.name == "LightningHitbox":
		target = area.hitbox_owner as CharacterBody2D
		detection.scale = Vector2(2.5, 2.5)
		animation.play("hit")
		$misc/lightning/AnimationPlayer.play("default")
		change_state(States.Shocked)
		shock = true
		shock_timer.start()
		await get_tree().create_timer(area.duration, false).timeout
		shock = false
		shock_timer.stop()
	elif area.name == "ProjectileHitbox":
		if area.type == "Electric":
			target = area.hitbox_owner as CharacterBody2D
			detection.scale = Vector2(2.5, 2.5)
			animation.play("hit")
			healthbar.health -= area.damage_power
			area.hit_count += 1
			Global.label_popup(self, str(area.damage_power), $misc/damage_label.global_position)
			knockback = position.direction_to(area.global_position) * -area.knockback_power
			change_state(States.Hit)

func _on_shock_timer_timeout() -> void:
	var damage: float = randi_range(1, 3)
	healthbar.health -= damage
	Global.label_popup(self, str(damage), $misc/damage_label.global_position, "ffff6e")

func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if not target:
			if randf() < 0.1:
				target = body
				detection.scale = Vector2(2.5, 2.5)
				$detection_pulse.start()

func _on_detection_body_exited(body: Node2D) -> void:
	if body == target:
		target = null
		detection.scale = Vector2(1.0, 1.0)

func _on_detection_pulse_timeout() -> void:
	if not target:
		detection.disabled = true
		await get_tree().create_timer(0.2, false).timeout
		detection.disabled = false

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	$detection_pulse.stop()
