extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Engine.max_fps = 200
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$FPS.text = "FPS: " + str(Engine.get_frames_per_second())
	
	if Input.is_action_just_pressed("interact"):
		$wave.reset_wave()
	pass
