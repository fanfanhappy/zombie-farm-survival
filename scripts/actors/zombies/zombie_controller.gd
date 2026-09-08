class_name Zombie
extends CharacterBody2D

signal defeated(zombie: Zombie)
var target: Player
var homestead: HomesteadCore
var definition: EnemyDefinition
var enemy_id: StringName = &"normal_infected"
var move_speed := 62.0
var health := 50.0
var max_health := 50.0
var attack_cooldown := 0.0
var hit_flash := 0.0
var player_aggro_time := 0.0
var experience_reward := 12
var aggro_distance := 105.0
var aggro_duration := 3.0
var player_attack_damage := 9.0
var homestead_attack_damage := 10.0
var defense_attack_damage := 12.0
var attack_interval := 0.8
var body_tint := Color("#73945c")
var slow_multiplier := 1.0
var slow_time_left := 0.0
@onready var visual: Node2D = $Visual
@onready var head: Polygon2D = $Visual/Head
@onready var health_bar: ProgressBar = $HealthBar


func setup(player: Player, home: HomesteadCore, enemy_definition: EnemyDefinition) -> void:
	target = player
	homestead = home
	definition = enemy_definition
	if definition != null:
		_apply_visual_scene(definition.visual_scene)
		enemy_id = definition.enemy_id
		move_speed = definition.move_speed
		max_health = definition.max_health
		health = max_health
		experience_reward = definition.experience_reward
		aggro_distance = definition.aggro_distance
		aggro_duration = definition.aggro_duration
		player_attack_damage = definition.player_attack_damage
		homestead_attack_damage = definition.homestead_attack_damage
		defense_attack_damage = definition.defense_attack_damage
		attack_interval = definition.attack_interval
		body_tint = definition.body_tint
		visual.scale = definition.visual_scale
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.visible = false
	add_to_group("zombies")
	_update_visual_state()


func _apply_visual_scene(scene: PackedScene) -> void:
	if scene == null: return
	var replacement := scene.instantiate() as Node2D
	if replacement == null:
		push_warning("敌人外观场景根节点必须是 Node2D")
		return
	visual.replace_by(replacement)
	visual.queue_free()
	visual = replacement
	head = visual.get_node_or_null("Head") as Polygon2D


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target): return
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	hit_flash = maxf(hit_flash - delta, 0.0)
	player_aggro_time = maxf(player_aggro_time - delta, 0.0)
	slow_time_left = maxf(slow_time_left - delta, 0.0)
	if slow_time_left <= 0.0: slow_multiplier = 1.0
	var pursue_player := player_aggro_time > 0.0 or global_position.distance_to(target.global_position) < aggro_distance
	var target_position := target.global_position if pursue_player else homestead.global_position
	var target_distance := global_position.distance_to(target_position)
	if target_distance > 27.0:
		velocity = global_position.direction_to(target_position) * move_speed * slow_multiplier
		move_and_slide(); _check_structure_collision()
	else:
		velocity = Vector2.ZERO
		if attack_cooldown <= 0.0:
			if pursue_player: target.take_damage(player_attack_damage)
			else: homestead.take_damage(homestead_attack_damage)
			attack_cooldown = attack_interval
	_update_visual_state()


func _check_structure_collision() -> void:
	for index in get_slide_collision_count():
		var collider := get_slide_collision(index).get_collider()
		if collider is DefenseStructure and attack_cooldown <= 0.0:
			collider.take_damage(defense_attack_damage)
			if collider.defense_type == "spike": take_damage(collider.spike_damage)
			attack_cooldown = attack_interval
		elif collider is HomesteadCore and attack_cooldown <= 0.0:
			collider.take_damage(homestead_attack_damage)
			attack_cooldown = attack_interval


func take_damage(amount: float, source: Node = null) -> void:
	health -= amount; hit_flash = 0.1
	if source is Player: player_aggro_time = aggro_duration
	health_bar.value = maxf(health, 0.0)
	health_bar.visible = health > 0.0 and health < max_health
	if health <= 0.0: defeated.emit(self); queue_free()
	else: _update_visual_state()


func apply_slow(multiplier: float, duration: float) -> void:
	slow_multiplier = minf(slow_multiplier, clampf(multiplier, 0.1, 1.0))
	slow_time_left = maxf(slow_time_left, duration)


func _update_visual_state() -> void:
	if not is_instance_valid(head):
		return
	head.color = Color("#f3e4c2") if hit_flash > 0.0 else body_tint
