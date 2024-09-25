extends Node

func _ready() -> void:
	Engine.max_fps = 200

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().paused = not get_tree().paused
		$CanvasLayer.visible = get_tree().paused
		$CanvasLayer/pause_menu.resume_button.grab_focus()
