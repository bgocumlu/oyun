extends State

var can_transition: bool = false

func enter():
	super.enter()
	animation_player.play("skill")
	await animation_player.animation_finished
	can_transition = true

func teleport():
	var direction: Vector2 = Vector2(1, 0.6) if randf() < 0.5 else Vector2(-1, 0.6)
	owner.position = player.position + direction * 45

func transition():
	if can_transition:
		get_parent().change_state("attack")
		can_transition = false
