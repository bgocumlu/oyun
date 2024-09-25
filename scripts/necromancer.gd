extends CharacterBody2D

@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var healthbar: ProgressBar = $healthbar
@onready var debug: Label = $debug
@onready var shock_timer: Timer = $misc/shock_timer

@onready var hurtbox: CollisionShape2D = $Sprite2D/hurtbox/CollisionShape2D
@onready var hitbox = null

var target: CharacterBody2D

signal on_death

var shock: bool = false
var knockback: Vector2 = Vector2.ZERO
var direction: Vector2
var speed: float = 40
var entry: bool = true

@export var max_health: float
@export var wander: bool = true
@export var minion: PackedScene
@export var skull_projectile: PackedScene
var knockback_skill: bool = true
@onready var knockback_skill_timer: Timer = $misc/knockback_skill_timer

enum States {
	Idle,
	Wandering,
	Follow,
	Attack,
	Summon,
	Knockback,
	Hit,
	Shocked,
	Dead,
}

var current_state: States

func _ready() -> void:
	randomize()
	current_state = States.Idle
	healthbar.init_enemy(max_health)
	
func _process(_delta: float) -> void:
	if not is_instance_valid(target):
		target = null
		
	if healthbar.health <= 0:
		direction = Vector2.ZERO
		if current_state != States.Dead:
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
		States.Summon:
			_summon_state(delta)
		States.Knockback:
			_knockback_state(delta)
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
		await get_tree().create_timer(randf_range(6, 9), false).timeout
		if not target and wander:
			change_state(States.Wandering)

	velocity = Vector2.ZERO
	if target: 
		change_state(States.Follow)

func _follow_state(_delta: float):
	if entry:
		entry = false
		animation.play("idle")

	if not target:
		change_state(States.Idle)
		direction = Vector2.ZERO
		return

	velocity = direction.normalized() * speed
	
	var length: float = direction.length()
	if length < 150 and is_instance_valid(target) and healthbar.health > 0:
		change_state(States.Attack)

func _wandering_state(_delta: float):
	if entry:
		entry = false
		animation.play("idle")
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
		animation.play("ranged_attack")
		await animation.animation_finished
		if randf() < 0.66:
			entry = true
		else:
			change_state(States.Summon)
		
		var length: float = direction.length()
		if length >= 150:
			change_state(States.Follow)

	if not target:
		change_state(States.Idle)
		direction = Vector2.ZERO
		return
	
	if direction.length() < 50 and knockback_skill:
		change_state(States.Knockback)
	elif direction.length() < 75:
		velocity = direction.normalized() * -speed * 0.5
	elif direction.length() <= 100:
		velocity = Vector2.ZERO
	else:
		velocity = direction.normalized() * speed

func shoot():
	var skull = skull_projectile.instantiate()
	if direction.x < 0:
		skull.global_position = global_position + Vector2(15, -9)
	else:
		skull.global_position = global_position + Vector2(-15, -9)
	skull.speed = randf_range(200, 400)
	skull.target = target
	get_parent().call_deferred("add_child", skull)

func _summon_state(_delta: float):
	if entry:
		entry = false
		animation.play("summon")
		await animation.animation_finished
		change_state(States.Attack)

func spawn():
	var skeleton = minion.instantiate()
	skeleton.position = global_position + Vector2(40, 40)
	skeleton.target = target
	get_parent().call_deferred("add_child", skeleton)

func _knockback_state(_delta: float):
	if entry:
		entry = false
		if knockback_skill:
			var projectile = preload("res://scenes/projectile.tscn").instantiate()
			projectile.launch_projectile(global_position, global_position.direction_to(target.global_position), 0, 90)
			animation.play("knockback")
			velocity *= 0.2
			knockback_skill_timer.start()
			knockback_skill = false
			await get_tree().create_timer(0.6, false).timeout
			if not current_state == States.Dead:
				add_child(projectile)
				projectile.hitbox.set_collision_layer_value(4, true)
				projectile.hitbox.set_collision_layer_value(3, false)
				projectile.hitbox.damage_power = 5
				projectile.hitbox.knockback_power = 100
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
		$SprShadow.visible = false
		$CollisionShape2D.disabled = true
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
		$misc/lightning/AnimationPlayer.play("default")
		change_state(States.Shocked)
		shock = true
		shock_timer.start()
		await get_tree().create_timer(area.duration, false).timeout
		shock = false
		shock_timer.stop()
	elif area.name == "ProjectileHitbox":
		if area.type == "Electric":
			if area.hitbox_owner.is_in_group("Player"):
				target = area.hitbox_owner as CharacterBody2D
			#detection.scale = Vector2(2.5, 2.5)
			animation.play("hit")
			healthbar.health -= area.damage_power
			area.hit_count += 1
			Global.label_popup(self, str(area.damage_power), $misc/damage_label.global_position)
			knockback = position.direction_to(area.global_position) * -area.knockback_power
			change_state(States.Hit)


func _on_shock_timer_timeout() -> void:
	var damage: int = randi_range(1, 3)
	healthbar.health -= damage
	Global.label_popup(self, str(damage), $misc/damage_label.global_position, "ffff6e")

func _on_knockback_skill_timer_timeout() -> void:
	knockback_skill = true
