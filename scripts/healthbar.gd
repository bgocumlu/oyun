extends ProgressBar

@onready var damagebar: ProgressBar = $damagebar
@onready var timer: Timer = $Timer

var tween: Tween

var health: float: set = set_health
var mana: float: set = set_mana

func set_health(new_health: float):
	var previous_health = health
	health = min(max_value, new_health)
	value = health
	
	if health < previous_health:
		timer.start()
	else:
		damagebar.value = health

func set_mana(new_mana: float):
	mana = min($manabar.max_value, new_mana)
	$manabar.value = mana

func init_enemy(_health: float) -> void:
	max_value = _health
	value = _health
	damagebar.max_value = _health
	damagebar.value = _health
	health = _health


func init_player(_health: float, _mana: float) -> void:
	$manabar.visible = true
	$frame.visible = true
	
	max_value = _health
	value = _health
	damagebar.max_value = _health
	damagebar.value = _health
	self.health = _health
	
	$manabar.max_value = _mana
	$manabar.value = _mana
	self.mana = _mana

func _on_timer_timeout() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(damagebar, "value", health, 0.1)
