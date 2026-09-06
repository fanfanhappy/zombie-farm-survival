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


func setup(player: Player, home: HomesteadCore, fast := false) -> void:
	# 僵尸检测玩家、农舍和可破坏防御，不检测生活设施层。
	collision_layer = 1
	collision_mask = 1
	target = player
	homestead = home
	if fast: move_speed = 105.0; health = 32.0; experience_reward = 20
	add_to_group("zombies")
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 9.0; capsule.height = 26.0; shape.shape = capsule
	add_child(shape); queue_redraw()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target): return
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	hit_flash = maxf(hit_flash - delta, 0.0)
	player_aggro_time = maxf(player_aggro_time - delta, 0.0)
	var pursue_player := player_aggro_time > 0.0 or global_position.distance_to(target.global_position) < 105.0
	var target_position := target.global_position if pursue_player else homestead.global_position
	var target_distance := global_position.distance_to(target_position)
	if target_distance > 27.0:
		velocity = global_position.direction_to(target_position) * move_speed
		move_and_slide(); _check_structure_collision()
	else:
		velocity = Vector2.ZERO
		if attack_cooldown <= 0.0:
			if pursue_player: target.take_damage(9.0)
			else: homestead.take_damage(10.0)
			attack_cooldown = 0.8
	queue_redraw()


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
	else: queue_redraw()


func _draw() -> void:
	var color := Color("#f3e4c2") if hit_flash > 0.0 else Color("#73945c")
	draw_circle(Vector2(0, 10), 10.0, Color("#3f523d"))
	draw_rect(Rect2(-9, -4, 18, 20), Color("#645d54"))
	draw_rect(Rect2(-8, -17, 16, 14), color)
	draw_circle(Vector2(-3, -10), 1.4, Color("#bd3f3f")); draw_circle(Vector2(3, -10), 1.4, Color("#bd3f3f"))
