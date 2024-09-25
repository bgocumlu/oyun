extends State

var can_transition: bool = true

var cooldown: bool = false

func _enter_tree() -> void:
	randomize()

func enter():
	super.enter()
	combo()
	owner.set_physics_process(true)
	

func attack(move: String = "1"):
	if cooldown:
		var random: float = randf()
		if random < 0.4:
			animation_player.play("attack2")
			owner.set_physics_process(true)
			cooldown = false
		elif random >= 0.4 and random < 0.8:
			animation_player.play("skill")
		else:
			animation_player.play("summon")
			
		await animation_player.animation_finished
		return

	animation_player.play("attack" + move)
	owner.set_physics_process(true)
	await animation_player.animation_finished
	if not cooldown:
		cooldown = true
		$"../../attack_cooldown".start()

func combo():
	if owner.direction.length() <= 50:
		can_transition = false

	await attack()
		
	can_transition = true
	combo()

func transition():
	if (owner.direction.length() > 50 and can_transition) or owner.healthbar.health <= 0:
		get_parent().change_state("follow")


func _on_attack_cooldown_timeout() -> void:
	cooldown = false
