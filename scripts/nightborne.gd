extends CharacterBody2D

@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var healthbar: ProgressBar = $healthbar
@onready var debug: Label = $debug
@onready var shock_timer: Timer = $misc/shock_timer

@onready var hurtbox: CollisionShape2D = $Sprite2D/hurtbox/CollisionShape2D
@onready var hitbox: CollisionPolygon2D = $Sprite2D/Hitbox/CollisionPolygon2D

var target: CharacterBody2D

signal on_death

var shock: bool = false
var knockback: Vector2 = Vector2.ZERO
var direction: Vector2
var speed: float = 100
var entry: bool = true

@export var max_health: float

enum States {
	Idle,
	Wandering,
	Follow,
	Attack,
	Hit,
	Shocked,
	Dead,
}

var current_state: States

func _ready() -> void:
	randomize()
	current_state = States.Idle
	healthbar.init_enemy(max_health)
	$CollisionShape2D.disabled = false
	
func _process(_delta: float) -> void:
	if not is_instance_valid(target):
		target = null
		
	if healthbar.health <= 0:
		hitbox.disabled = true
		direction = Vector2.ZERO
		on_death.emit()
		change_state(States.Dead)
		return
		
	if target:
		direction = target.position - position
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
		await get_tree().create_timer(randf_range(1, 9)).timeout
		if not target:
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
	if length < 35 and is_instance_valid(target) and healthbar.health > 0:
		change_state(States.Attack)

func _wandering_state(_delta: float):
	if entry:
		entry = false
		animation.play("walk")
		velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * speed * 0.5
		await get_tree().create_timer(randf_range(1, 3)).timeout
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
		var length: float = direction.length()
		entry = true
		if length > 35:
			change_state(States.Follow)

	if not target:
		change_state(States.Idle)
		direction = Vector2.ZERO
		return
		
	velocity = direction.normalized() * speed
	if direction.length() < 30:
		velocity = Vector2.ZERO
	 


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
		if area.hitbox_owner.is_in_group("Player"):
			target = area.hitbox_owner as CharacterBody2D
		#detection.scale = Vector2(2.5, 2.5)
		animation.play("hit")
		hitbox.set_deferred("disabled", true)
		healthbar.health -= area.damage_power
		area.hit_count += 1
		Global.label_popup(self, str(area.damage_power), $misc/damage_label.global_position)
		knockback = position.direction_to(area.global_position) * -area.knockback_power
		change_state(States.Hit)
	elif area.name == "LightningHitbox":
		if area.hitbox_owner.is_in_group("Player"):
			target = area.hitbox_owner as CharacterBody2D
		#detection.scale = Vector2(2.5, 2.5)
		animation.play("hit")
		hitbox.set_deferred("disabled", true)
		$misc/lightning/AnimationPlayer.play("default")
		change_state(States.Shocked)
		shock = true
		shock_timer.start()
		await get_tree().create_timer(1.5).timeout
		shock = false
		shock_timer.stop()
	elif area.name == "ProjectileHitbox":
		if area.type == "Electric":
			if area.hitbox_owner.is_in_group("Player"):
				target = area.hitbox_owner as CharacterBody2D
			#detection.scale = Vector2(2.5, 2.5)
			animation.play("hit")
			hitbox.set_deferred("disabled", true)
			healthbar.health -= area.damage_power
			area.hit_count += 1
			Global.label_popup(self, str(area.damage_power), $misc/damage_label.global_position)
			knockback = position.direction_to(area.global_position) * -area.knockback_power
			change_state(States.Hit)


func _on_shock_timer_timeout() -> void:
	var damage: float = randi_range(1, 3)
	healthbar.health -= damage
	Global.label_popup(self, str(damage), $misc/damage_label.global_position, "ffff6e")
