extends Node

const LABEL_POPUP = preload("res://scenes/label_popup.tscn")
const SKELETON_BOSS_MINION = preload("res://scenes/skeleton_boss_minion.tscn")
const ORB = preload("res://scenes/orb.tscn")
const SPAWN_EFFECT = preload("res://scenes/spawn_effect.tscn")

func label_popup(node: Node, text: String, pos: Vector2, color: Color = "ffffff"):
	var label: Node2D = LABEL_POPUP.instantiate()
	label.z_index = 5
	label.global_position = pos
	label.text = text
	label.modulate = color
	node.add_child(label)

func death_summon(node: Node, pos: Vector2):
	var positions: Array[Vector2] = [Vector2(40, 40), Vector2(40, -40), Vector2(-40, 40), Vector2(-40, -40)]
	for p in positions:
		var minion: CharacterBody2D = SKELETON_BOSS_MINION.instantiate()
		minion.position = pos + p
		minion.character = node
		minion.set_as_top_level(true)
		node.add_child(minion)

func summon_orb(target: Node2D, from: Vector2, value: int, type: int):
	var orb = ORB.instantiate()
	orb.global_position = from
	orb.target = target
	orb.type = type
	orb.value = value
	target.add_child(orb)

func enemy_spawn_effect(enemy: CharacterBody2D):
	var spawn_effect: AnimatedSprite2D = SPAWN_EFFECT.instantiate()
	enemy.add_child(spawn_effect)
	
	enemy.set_process(false)
	enemy.set_physics_process(false)
	enemy.hurtbox.disabled = true
	enemy.find_child("CollisionShape2D").disabled = true
	enemy.find_child("healthbar").visible = false
	await get_tree().create_tween().tween_property(enemy, "modulate", Color(1, 1, 1), 1).from(Color(0, 0, 0, 0.1)).finished
	enemy.set_process(true)
	enemy.set_physics_process(true)
	enemy.hurtbox.disabled = false
	enemy.find_child("CollisionShape2D").disabled = false
	enemy.find_child("healthbar").visible = true
