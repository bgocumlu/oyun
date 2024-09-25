extends State

func _enter_tree() -> void:
	randomize()

func enter():
	super.enter() #extend
	owner.set_physics_process(true)
	animation_player.play("idle")

func exit():
	super.exit()
	owner.set_physics_process(false)
	
func transition():
	if owner.direction.length() <= 50:
		get_parent().change_state("attack")
	if owner.direction.length() > 150:
		if randf() < 0.5:
			get_parent().change_state("teleport")
		else:
			get_parent().change_state("spawn_minion")
			
	if owner.healthbar.health <= 0:
		get_parent().change_state("death")

func _on_weak_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if randf() < 0.3:
			get_parent().change_state("teleport")
