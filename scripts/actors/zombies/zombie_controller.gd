class_name Zombie
extends CharacterBody2D

signal defeated(zombie: Zombie)
var target: Player
var homestead: HomesteadCore
var move_speed := 62.0
var health := 50.0
var attack_cooldown := 0.0
var hit_flash := 0.0
var player_aggro_time := 0.0
var experience_reward := 12
var slow_multiplier := 1.0
var slow_time_left := 0.0
@onready var visual: Node2D = $Visual
@onready var head: Polygon2D = $Visual/Head


func setup(player: Player, home: HomesteadCore, fast := false) -> void:
	target = player
	homestead = home
	if fast:
		move_speed = 105.0; health = 32.0; experience_reward = 20
		visual.scale = Vector2(0.86, 0.86)
		head.color = Color("#91a865")
	add_to_group("zombies")
	_update_visual_state()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target): return
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	hit_flash = maxf(hit_flash - delta, 0.0)
	player_aggro_time = maxf(player_aggro_time - delta, 0.0)
	slow_time_left = maxf(slow_time_left - delta, 0.0)
	if slow_time_left <= 0.0: slow_multiplier = 1.0
	var pursue_player := player_aggro_time > 0.0 or global_position.distance_to(target.global_position) < 105.0
	var target_position := target.global_position if pursue_player else homestead.global_position
	var target_distance := global_position.distance_to(target_position)
	if target_distance > 27.0:
		velocity = global_position.direction_to(target_position) * move_speed * slow_multiplier
		move_and_slide(); _check_structure_collision()
	else:
		velocity = Vector2.ZERO
		if attack_cooldown <= 0.0:
			if pursue_player: target.take_damage(9.0)
			else: homestead.take_damage(10.0)
			attack_cooldown = 0.8
	_update_visual_state()


func _check_structure_collision() -> void:
	for index in get_slide_collision_count():
		var collider := get_slide_collision(index).get_collider()
		if collider is DefenseStructure and attack_cooldown <= 0.0:
			collider.take_damage(12.0)
			if collider.defense_type == "spike": take_damage(collider.spike_damage)
			attack_cooldown = 0.8
		elif collider is HomesteadCore and attack_cooldown <= 0.0:
			collider.take_damage(10.0)
			attack_cooldown = 0.8


func take_damage(amount: float, source: Node = null) -> void:
	health -= amount; hit_flash = 0.1
	if source is Player: player_aggro_time = 3.0
	if health <= 0.0: defeated.emit(self); queue_free()
	else: _update_visual_state()


func apply_slow(multiplier: float, duration: float) -> void:
	slow_multiplier = minf(slow_multiplier, clampf(multiplier, 0.1, 1.0))
	slow_time_left = maxf(slow_time_left, duration)


func _update_visual_state() -> void:
	if not is_instance_valid(head):
		return
	var base_color := Color("#91a865") if move_speed > 100.0 else Color("#73945c")
	head.color = Color("#f3e4c2") if hit_flash > 0.0 else base_color
