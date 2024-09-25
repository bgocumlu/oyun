extends CharacterBody2D

@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var healthbar: ProgressBar = $healthbar
@onready var debug: Label = $debug
@onready var shock_timer: Timer = $misc/shock_timer

@onready var hurtbox: CollisionShape2D = $Sprite2D/hurtbox/CollisionShape2D
@onready var hitbox = null

const EFFECT_AREA = preload("res://scenes/lightning_area.tscn")
const PROJECTILE = preload("res://scenes/projectile.tscn")
const BAT = preload("res://scenes/bat.tscn")

var target: CharacterBody2D

signal on_death

var shock: bool = false
var knockback: Vector2 = Vector2.ZERO
var direction: Vector2
var speed: float = 40
var entry: bool = true

@export var max_health: float
@export var wander: bool = true

var anim: String = "side"
@onready var attack_cooldown: Timer = $misc/attack_cooldown
@onready var poison_cooldown_timer: Timer = $misc/poison_cooldown
@onready var slowdown_cooldown_timer: Timer = $misc/slowdown_cooldown
@onready var heal_cooldown_timer: Timer = $misc/heal_cooldown
@onready var summon_cooldown_timer: Timer = $misc/summon_cooldown
@onready var insta_damage_cooldown_timer: Timer = $misc/insta_damage_cooldown

var attacks: Array[bool] = [false, false, false, false, false]

enum States {
	Idle,
	Wandering,
	Follow,
	Retreat,
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
		direction = Vector2.ZERO
		if current_state != States.Dead:
			on_death.emit()
			change_state(States.Dead)
		return
		
	if target:
		direction = target.position - position
		if current_state == States.Retreat:
			$Sprite2D.scale.x = -1 if velocity.x < 0 else 1
		else:
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
		States.Retreat:
			_retreat_state(delta)
		States.Attack:
			_attack_state(delta)
		States.Hit:
			_hit_state(delta)
		States.Shocked:
			_shocked_state(delta)
		States.Dead:
			_dead_state(delta)
	move_and_slide()
	update_anim()

func _idle_state(_delta: float):
	if entry:
		entry = false
		animation_play("idle")
		await get_tree().create_timer(randf_range(1, 9), false).timeout
		if not target and wander:
			change_state(States.Wandering)

	velocity = Vector2.ZERO
	if target: 
		change_state(States.Follow)

func _follow_state(_delta: float):
	if entry:
		entry = false
		anim = "side"
		animation_play("walk")

	if not target:
		change_state(States.Idle)
		direction = Vector2.ZERO
		return
	
	velocity = direction.normalized() * speed * 1.5
	
	var length: float = direction.length()
	if length < 100 and is_instance_valid(target) and healthbar.health > 0:
		change_state(States.Attack)

func _wandering_state(_delta: float):
	if entry:
		entry = false
		velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * speed * 0.5
		update_anim()
		animation_play("walk")
		await get_tree().create_timer(randf_range(1, 3), false).timeout
		change_state(States.Idle)

func _retreat_state(_delta: float):
	if entry:
		velocity = direction.normalized() * -speed * 2
		update_anim()
		animation_play("walk")
		entry = false

	if direction.length() <= 70:
		slowdown_attack()
		if randf() < 0.01:
			summon_bats()
		
	if direction.length() >= 95:
		velocity = direction.normalized() * speed
		update_anim()
		if healthbar.health < max_health * 0.7:
			heal()
		change_state(States.Attack)

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
		animation_play("skill")
		velocity = direction.normalized() * speed
		update_anim()
		await animation.animation_finished
		attack_cooldown.start()
		update_anim()
		animation_play("idle")
		var length: float = direction.length()
		if length > 100:
			change_state(States.Follow)

	if not target:
		change_state(States.Idle)
		direction = Vector2.ZERO
		return
		
	if direction.length() < 50:
		slowdown_attack()
		change_state(States.Retreat)
	elif direction.length() < 75:
		velocity = direction.normalized() * -speed * 0.5
	elif direction.length() <= 100:
		velocity = Vector2.ZERO
	else:
		velocity = direction.normalized() * speed

func poison_attack():
	if not attacks[0]:
		attacks[0] = true
		var projectile = PROJECTILE.instantiate()
		projectile.launch_projectile(global_position, global_position.direction_to(target.global_position), (target.global_position - global_position).length(), randf_range(30, 60))
		get_parent().add_child(projectile)
		projectile.sprite.modulate = Color(0.7, 0.0, 100)
		projectile.circle.modulate = "cc01ff18"
		projectile.hitbox.type = "Poison"
		projectile.hitbox.damage_power = 0.0
		projectile.hitbox.knockback_power = 0.0
		projectile.hitbox.set_collision_layer_value(4, true)
		projectile.hitbox.set_collision_layer_value(3, false)
		poison_cooldown_timer.start()

func slowdown_attack():
	if not attacks[1]:
		attacks[1] = true
		var area = EFFECT_AREA.instantiate()
		area.global_position = global_position
		area.modulate = "00000075"
		area.find_child("LightningHitbox").set_collision_layer_value(3, false)
		area.find_child("LightningHitbox").set_collision_layer_value(4, true)
		add_child(area)
		area.find_child("AnimationPlayer").play("big")
		slowdown_cooldown_timer.start()

func heal():
	if not attacks[2]:
		attacks[2] = true
		$misc/heal_cooldown/count.start()
		$misc/heal_cooldown/duration.start()
		heal_cooldown_timer.start()

func summon_bats():
	if not attacks[3]:
		attacks[3] = true
		var positions: Array[Vector2] = [Vector2(20, -20), Vector2(-20, -20), Vector2(0, -20)]
		for i in range(3):
			var bat = BAT.instantiate()
			bat.global_position = global_position + positions[i]
			bat.target = target
			get_parent().add_child(bat)
		summon_cooldown_timer.start()

func insta_damage_attack():
	if not attacks[4]:
		attacks[4] = true
		var projectile = PROJECTILE.instantiate()
		projectile.launch_projectile(global_position, global_position.direction_to(target.global_position), (target.global_position - global_position).length(), randf_range(30, 60))
		get_parent().add_child(projectile)
		projectile.hitbox.set_collision_layer_value(4, true)
		projectile.hitbox.set_collision_layer_value(3, false)
		insta_damage_cooldown_timer.start()

func attack():
	var array: Array[int]
	for i in range(5):
		if i == 2 and healthbar.health >= max_health * 0.7:
			continue
		if not attacks[i]:
			array.push_back(i)
	if array.is_empty():
		return
	match array.pick_random():
		0:
			poison_attack()
		1:
			slowdown_attack()
		2:
			heal()
		3:
			summon_bats()
		4:
			insta_damage_attack()

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

func animation_play(animation_name: String):
	animation.play(animation_name + "_" + anim)

func update_anim(type: bool = false):
	var degrees = rad_to_deg(velocity.angle()) 
	if type:
		degrees = rad_to_deg(direction.angle()) 
		
	if degrees >= -45.0 or degrees <= 45.0:
		anim = "side"
	if degrees > -135.0 and degrees < -45.0:
		anim = "back"
	elif degrees > 45.0 and degrees < 135.0:
		anim = "front"
	elif degrees >= 135.0 or degrees <= -135.0:
		anim = "side"


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
	var damage: float = randi_range(1, 3)
	healthbar.health -= damage
	Global.label_popup(self, str(damage), $misc/damage_label.global_position, "ffff6e")


func _on_attack_cooldown_timeout() -> void:
	if current_state == States.Attack:
		entry = true


func _on_poison_cooldown_timeout() -> void:
	attacks[0] = false

func _on_slowdown_cooldown_timeout() -> void:
	attacks[1]  = false

func _on_heal_cooldown_timeout() -> void:
	attacks[2]  = false

func _on_summon_cooldown_timeout() -> void:
	attacks[3]  = false

func _on_insta_damage_cooldown_timeout() -> void:
	attacks[4]  = false


func _on_count_timeout() -> void:
	var value: int = randi_range(2, 5)
	healthbar.health += value
	Global.label_popup(self, str(value), $misc/damage_label.global_position, "00ff00")

func _on_duration_timeout() -> void:
	$misc/heal_cooldown/count.stop()
