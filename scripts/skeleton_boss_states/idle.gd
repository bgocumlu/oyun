extends State

var player_entered: bool = false

func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_entered = true
		$"../../UI".visible = true
		$"../../detection/CollisionShape2D".set_deferred("disabled", true)
		
func transition():
	if player_entered:
		get_parent().change_state("follow")
