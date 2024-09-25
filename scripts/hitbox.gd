extends Area2D
class_name Hitbox

@export var damage_power: float = 25
@export var knockback_power: float = 50

@export var hitbox_owner: Node2D
var hit_count: int = 0

var poisonous: bool = false
