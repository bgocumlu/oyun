extends Area2D

@onready var area: CollisionShape2D = $CollisionShape2D
@export var wave_count: int
@export var health_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
@export var knockback_multiplier: float = 1.0
@export var enemies: Array[PackedScene]
@export var enemy_counts: Array[int]

var target: Player
var start: bool = false
var timeout: bool = false
var counter: int = 0

func _ready() -> void:
	randomize()

func _process(_delta: float) -> void:
	if target and not start and counter < wave_count:
		start = true
		start_wave()
		counter += 1
		print(name, " ", counter, "/", wave_count)

	if get_child_count() < 2 and not timeout and start:
		if counter >= wave_count:
			queue_free()
			print(name, " ", "Finished")
		timeout = true
		await get_tree().create_timer(1.0, false).timeout
		timeout = false
		start = false

func _on_body_entered(body: Player) -> void:
	target = body

func start_wave() -> void:
	if enemies.is_empty():
		var temp: bool = true
		var children = get_children()
		for child in children:
			if temp: temp = false
			else: child.target = target
	
	for i in range(enemy_counts.size()):
		for j in range(enemy_counts[i]):
			var enemy = enemies[i].instantiate()
			enemy.global_position.x = randf_range(area.global_position.x - area.shape.size.x / 2, area.global_position.x + area.shape.size.x / 2)
			enemy.global_position.y = randf_range(area.global_position.y - area.shape.size.y / 2, area.position.y + area.shape.size.y / 2)
			enemy.max_health *= health_multiplier
			add_child(enemy)
			if enemy.hitbox:
				enemy.hitbox.get_parent().damage_power *= damage_multiplier
				enemy.hitbox.get_parent().knockback_power *= knockback_multiplier
			Global.enemy_spawn_effect(enemy)
			enemy.target = target

func reset_wave():
	target = null
	counter = 0
	start = false
	timeout = false
	var temp: bool = true
	var children = get_children()
	
	if enemies.is_empty():
		for child in children:
			if temp: temp = false
			else:
				if "target" in child:
					child.target = null
				child.global_position.x = randf_range(area.global_position.x - area.shape.size.x / 2, area.global_position.x + area.shape.size.x / 2)
				child.global_position.y = randf_range(area.global_position.y - area.shape.size.y / 2, area.position.y + area.shape.size.y / 2)
		return

	for child in children:
		if temp: temp = false
		else: child.free()
