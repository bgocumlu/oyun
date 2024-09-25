extends CharacterBody2D
class_name Player

@export var default_speed: float = 50
@export var speed_when_attacking: float = 40

var speed: float = default_speed

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var healthbar: ProgressBar = $CanvasLayer/healthbar
@onready var camera: Camera2D = $Camera2D
const LIGHTNING_AREA = preload("res://scenes/lightning_area.tscn")
const PROJECTILE = preload("res://scenes/projectile.tscn")

@export var max_health: float = 100
@export var max_mana: float = 100
var health: float = max_health :
	set(value):
		health = min(value, max_health)
		healthbar.health = health
var mana: float = max_mana :
	set(value):
		mana = min(value, max_mana)
		healthbar.mana = mana

var take_damage: bool = false
var knockback: Vector2 = Vector2.RIGHT
var hit_count = 0

var character_direction : Vector2
var current_dir: String = "right"
@onready var col: CollisionShape2D = $CollisionShape2D

@onready var dash: Node2D = $dash
@export var dash_speed: float = 120
@export var dash_duration: float = 0.2

@onready var laser: Node2D = $laser

var moving : bool = false

var character_angle: float = 0
var mouse_aim: bool = false

var special1_cooldown = false

var poisoned: bool = false

var slowdown_data: Array[float] = [default_speed, speed_when_attacking, dash_speed, dash_duration]

var health_potion_count: int = 3:
	set(value):
		health_potion_count = value
		$CanvasLayer/healthbar/h_potion.frame = min(3, value)
var health_potion_value: float = 25.0
var mana_potion_count: int = 2:
	set(value):
		mana_potion_count = value
		$CanvasLayer/healthbar/m_potion.frame = min(2, value)
var mana_potion_value: float = 25.0

var interaction_area: Interactable = null
var new_powerup: int = 0
var checkpoint_data: Array

var blade: String = ""
var laser_default_pulse: float = 2
var area_default_scale: Vector2 = Vector2(1.0, 1.0)
var bomb_default_damage: float = 35

var powerups: Array[bool] = [false,false,false,false,false,false,false,false,]
var powerup_funcs = [
	func(): area_powerup(), 
	func(): bomb_powerup(),
	func(): poison_powerup(),
	func(): health_powerup(),
	func(): mana_powerup(),
	func(): laser_powerup(),
	func(): dash_powerup(),
	func(): speed_powerup(),
]

signal on_death
var death_count: int = 0

func _ready() -> void:
	animation_player.play("idle_side")
	laser.hitbox_area.hitbox_owner = self
	healthbar.init_player(health, mana)
	checkpoint_data.resize(5)
	set_checkpoint()

func _physics_process(delta: float) -> void:
	if health <= 0:
		set_physics_process(false)
		laser.end_shooting()
		$poison/damage.stop()
		default_speed = slowdown_data[0]
		speed_when_attacking = slowdown_data[1]
		dash_speed = slowdown_data[2]
		dash_duration = slowdown_data[3]
		animation_player.play("death")
		$Sprite2D/Hitbox/CollisionShape2D.disabled = true
		$Sprite2D/hurtbox/CollisionShape2D.disabled = true
		set_collision_layer_value(9, false)
		await get_tree().create_timer(1.5, false).timeout
		$Sprite2D/hurtbox/CollisionShape2D.disabled = false
		set_collision_layer_value(9, true)
		return_to_checkpoint()
		set_physics_process(true)
		on_death.emit()
		death_count += 1
		return
		
	player_movement(delta)

func player_movement(delta: float) -> void:
	character_direction.x = Input.get_axis("move_left", "move_right")
	character_direction.y = Input.get_axis("move_up", "move_down")
	character_direction = character_direction.normalized()

	if character_direction:
		character_angle = character_direction.angle()

	if not animation_player.current_animation.begins_with("attack"):
		if character_direction.x > 0: sprite.flip_h = true
		if character_direction.x < 0: sprite.flip_h = false
		if not character_direction:
			var dir: Vector2 = Vector2.RIGHT.rotated(character_angle).round()
			if dir.x > 0: sprite.flip_h = true
			if dir.x < 0: sprite.flip_h = false

	if take_damage:
		velocity = knockback * delta * 100
		$Sprite2D/Hitbox/CollisionShape2D.disabled = true
		camera.offset = Vector2(randi_range(-1, 1), randi_range(-1, 1))
		if not animation_player.current_animation.begins_with("hit"):
			take_damage = false
			camera.offset = Vector2.ZERO
			
	elif Input.is_action_just_pressed("left_click"):
		attack_angle(rad_to_deg($hand.global_position.direction_to(get_global_mouse_position()).angle()))
	elif Input.is_action_just_pressed("joypad_attack"):
		attack()
	elif Input.is_action_just_pressed("right_click") and mana >= 25:
		var projectile: Node2D = PROJECTILE.instantiate()
		projectile.launch_projectile($hand.global_position, $hand.global_position.direction_to(get_global_mouse_position()), 100, 45)
		add_child(projectile)
		projectile.hitbox.hitbox_owner = self
		projectile.hitbox.damage_power = bomb_default_damage
		mana -= 25
	elif Input.is_action_just_pressed("joypad_ranged") and mana >= 25:
		var projectile: Node2D = PROJECTILE.instantiate()
		projectile.launch_projectile($hand.global_position, Vector2.RIGHT.rotated(character_angle), 100, 45)
		add_child(projectile)
		projectile.hitbox.hitbox_owner = self
		projectile.hitbox.damage_power = bomb_default_damage
		mana -= 25
	elif Input.is_action_just_pressed("dash") and dash.can_dash and not dash.is_dashing():
		dash.start_dash(self, sprite, dash_duration)
	elif Input.is_action_just_pressed("special1") and not special1_cooldown and mana >= 15:
		var area: Node2D = LIGHTNING_AREA.instantiate()
		area.global_position = global_position
		area.scale = area_default_scale
		area.find_child("LightningHitbox").hitbox_owner = self
		add_child(area)
		mana -= 15

		special1_cooldown = true
		await get_tree().create_timer(1.5, false).timeout
		special1_cooldown = false

	if Input.is_action_just_pressed("use_health_potion") and health_potion_count > 0:
		var value = health_potion_value if health + health_potion_value <= max_health else max_health - health
		health_potion_count -= 1
		health += health_potion_value
		Global.label_popup(self, str(value), $damage_label.global_position, "00ff00")
	elif Input.is_action_just_pressed("use_mana_potion") and mana_potion_count > 0:
		var value = mana_potion_value if mana + mana_potion_value <= max_mana else max_mana - mana
		mana_potion_count -= 1
		mana += mana_potion_value
		Global.label_popup(self, str(value), $damage_label.global_position, "0000ff")
	if Input.is_action_just_pressed("special2"):
		laser.start_shooting()
		mouse_aim = true
		mana -= laser_default_pulse
	if Input.is_action_just_released("special2"):
		laser.end_shooting()

	if Input.is_action_just_pressed("joypad_special2"):
		laser.start_shooting()
		mouse_aim = false
		mana -= laser_default_pulse
	if Input.is_action_just_released("joypad_special2"):
		laser.end_shooting()

	if hit_count < $Sprite2D/Hitbox.hit_count:
		mana += 4 * ($Sprite2D/Hitbox.hit_count - hit_count)
		hit_count = $Sprite2D/Hitbox.hit_count
	
	if mana > 0:
		if mouse_aim:
			laser.shootf(get_global_mouse_position() - laser.global_position, delta * 180)
		else:
			laser.shootf(Vector2.RIGHT.rotated(character_angle), delta)
	else:
		laser.end_shooting()
	
	if Input.is_action_just_pressed("interact"):
		if interaction_area:
			var powerup_menu = preload("res://scenes/powerup_menu.tscn").instantiate()
			interaction_area.data.clear()
			interaction_area.data.append("Statue")
			var random: int
			for i in range(3):
				while true:
					random = randi_range(0, 7)
					if not powerups[random] and not interaction_area.data.has(random):
						break
				interaction_area.data.append(random)
			powerup_menu.data = interaction_area.interaction_data()
			add_child(powerup_menu)
			interaction_area.set_shine(false)
			$CanvasLayer/accept_label.visible = false
			
	if new_powerup != 0:
		print(interaction_area.data[new_powerup])
		powerup_funcs[interaction_area.data[new_powerup]].call()
		new_powerup = 0
		interaction_area.disable()
	
	if dash.is_dashing():
		speed = dash_speed
		set_collision_layer_value(2, false)
		set_collision_mask_value(8, false)
		set_collision_mask_value(5, false)
		$Sprite2D/hurtbox/CollisionShape2D.disabled = true
	else:
		speed = speed_when_attacking if animation_player.current_animation.begins_with("attack") else default_speed
		set_collision_layer_value(2, true)
		set_collision_mask_value(8, true)
		set_collision_mask_value(5, true)
		$Sprite2D/hurtbox/CollisionShape2D.disabled = false
	
	if take_damage:
		pass
	elif character_direction:
		moving = true
		velocity = character_direction * speed * delta * 100
	elif speed == dash_speed:
		character_direction = Vector2.RIGHT.rotated(character_angle).round()
		velocity = character_direction * speed * delta * 100
		moving = true
	else:
		moving = false
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 100)

	if not animation_player.current_animation.begins_with("attack") and not animation_player.current_animation.begins_with("hit"):
		speed = default_speed
		play_anim(moving)
	
	update_dir()
	move_and_slide()

func update_dir():
	if take_damage:
		return
	if velocity.x > 0 and not velocity.y:
		current_dir = "right"
	elif velocity.x < 0 and not velocity.y:
		current_dir = "left"
	elif not velocity.x and velocity.y > 0:
		current_dir = "down"
	elif not velocity.x and velocity.y < 0:
		current_dir = "up"
	elif velocity.x > 0 and velocity.y > 0:
		current_dir = "downright"
	elif velocity.x < 0 and velocity.y > 0:
		current_dir = "downleft"
	elif velocity.x > 0 and velocity.y < 0:
		current_dir = "upright"
	elif velocity.x < 0 and velocity.y < 0:
		current_dir = "upleft"

func play_anim(movement: bool):
	if current_dir == "right" or current_dir == "left"  or current_dir == "downleft" or current_dir == "upleft"  or current_dir == "downright"  or current_dir == "upright":
		if movement:
			animation_player.play("walk_side")
		else:
			animation_player.play("idle_side")
	elif current_dir == "down":
		if movement:
			animation_player.play("walk_front")
		else:
			animation_player.play("idle_front")
	elif current_dir == "up":
		if movement:
			animation_player.play("walk_back")
		else:
			animation_player.play("idle_back")

func attack():
	if animation_player.current_animation.begins_with("attack"):
		return

	speed = speed_when_attacking

	if current_dir == "right" or current_dir == "left"  or current_dir == "downleft" or current_dir == "upleft"  or current_dir == "downright"  or current_dir == "upright":
		animation_player.play("attack" + blade + "_side")
		if sprite.flip_h:
			$Sprite2D/Hitbox/CollisionShape2D.position = Vector2(15, -3)
		else:
			$Sprite2D/Hitbox/CollisionShape2D.position = Vector2(-15, -3)
	elif current_dir == "down":
		animation_player.play("attack" + blade + "_front")
	elif current_dir == "up":
		animation_player.play("attack" + blade + "_back")

func attack_angle(degrees: float):
	if animation_player.current_animation.begins_with("attack"):
		return

	speed = speed_when_attacking

	if degrees >= -45.0 or degrees <= 45.0:
		sprite.flip_h = true
		animation_player.play("attack" + blade + "_side")
		$Sprite2D/Hitbox/CollisionShape2D.position = Vector2(15, -3)
	if degrees > -135.0 and degrees < -45.0:
		animation_player.play("attack" + blade + "_back")
	elif degrees > 45.0 and degrees < 135.0:
		animation_player.play("attack" + blade + "_front")
	elif degrees >= 135.0 or degrees <= -135.0:
		sprite.flip_h = false
		animation_player.play("attack" + blade + "_side")
		$Sprite2D/Hitbox/CollisionShape2D.position = Vector2(-15, -3)

func return_to_checkpoint():
	global_position = checkpoint_data[0]
	health = max(1, checkpoint_data[1])
	mana = checkpoint_data[2]
	health_potion_count = checkpoint_data[3]
	mana_potion_count = checkpoint_data[4]
	
func set_checkpoint():
	checkpoint_data[0] = global_position
	checkpoint_data[1] = health
	checkpoint_data[2] = mana
	checkpoint_data[3] = health_potion_count
	checkpoint_data[4] = mana_potion_count

func area_powerup():
	powerups[0] = true
	area_default_scale = Vector2(1.7, 1.7)

func bomb_powerup():
	powerups[1] = true
	bomb_default_damage = 50
	
func poison_powerup():
	powerups[2] = true
	$Sprite2D/Hitbox.poisonous = true
	
func health_powerup():
	powerups[3] = true
	var value = 80.0 if health + 80.0 <= max_health else max_health - health
	health_potion_count += 2
	health += 80.0
	Global.label_popup(self, str(value), $damage_label.global_position, "00ff00")
	
func mana_powerup():
	powerups[4] = true
	var value = 80.0 if mana + 80.0 <= max_mana else max_mana - mana
	mana_potion_count += 2
	mana += 80.0
	Global.label_popup(self, str(value), $damage_label.global_position, "0000ff")
	
func laser_powerup():
	powerups[5] = true
	laser_default_pulse = 3
	laser.hitbox.get_parent().damage_power = 20
	laser.line.default_color = "ff0000"

func dash_powerup():
	powerups[6] = true
	dash.dash_cooldown = 0.35

func speed_powerup():
	powerups[7] = true
	var multiplier: float = 1.2
	default_speed *= multiplier
	speed_when_attacking *= multiplier
	dash_speed *= multiplier
	slowdown_data = [default_speed, speed_when_attacking, dash_speed, dash_duration]

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if health <= 0:
		return

	if area.name == "Hitbox" or (area.name == "ProjectileHitbox" and area.type == "Electric"):
		if current_dir == "right" or current_dir == "left"  or current_dir == "downleft" or current_dir == "upleft"  or current_dir == "downright"  or current_dir == "upright":
			animation_player.play("hit_side")
		elif current_dir == "down":
			animation_player.play("hit_front")
		elif current_dir == "up":
			animation_player.play("hit_back")
		take_damage = true

		health -= area.damage_power
		area.hit_count += 1
		Global.label_popup(self, str(area.damage_power), $damage_label.global_position, "ff0000")
		knockback = position.direction_to(area.global_position) * -area.knockback_power
	elif area.name == "Orb":
		if area.type == 0:
			health += area.damage_power
			Global.label_popup(self, str(area.damage_power), $damage_label.global_position, "00ff00")
		elif area.type == 1:
			mana += area.damage_power
			Global.label_popup(self, str(area.damage_power), $damage_label.global_position, "0000ff")
		area.hit_count += 1
	elif area.name == "ProjectileHitbox":
		if area.type == "Poison":
			$poison/AnimationPlayer.play("default")
			$poison/poison_timer.start()
			$poison/damage.start()
	elif area.name == "LightningHitbox":
		$slowdown/AnimationPlayer.play("default")
		$slowdown/slowdown_timer.start()
		default_speed = slowdown_data[0] / 2
		speed_when_attacking = slowdown_data[1] / 2
		dash_speed = slowdown_data[2] / 2
		dash_duration = slowdown_data[3] / 2
	elif area is Interactable:
		if not interaction_area:
			interaction_area = area
			$CanvasLayer/accept_label.visible = true

func _on_laser_pulse_signal() -> void:
	mana -= laser_default_pulse

func _on_damage_timeout() -> void:
	var damage: int = randi_range(2, 6)
	health -= damage
	Global.label_popup(self, str(damage), $damage_label.global_position, "a020f0")

func _on_poison_timer_timeout() -> void:
	$poison/damage.stop()

func _on_slowdown_timer_timeout() -> void:
	default_speed = slowdown_data[0]
	speed_when_attacking = slowdown_data[1]
	dash_speed = slowdown_data[2]
	dash_duration = slowdown_data[3]


func _on_hurtbox_area_exited(area: Area2D) -> void:
	if interaction_area == area:
		interaction_area = null
		$CanvasLayer/accept_label.visible = false
