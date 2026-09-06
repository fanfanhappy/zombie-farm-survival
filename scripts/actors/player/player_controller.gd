class_name Player
extends CharacterBody2D

@onready var character_sprite: Sprite2D = $CharacterSprite

const WALK_TEXTURE := preload("res://assets/art/characters/basic_charakter_spritesheet.png")
const ACTION_TEXTURE := preload("res://assets/art/characters/basic_charakter_actions.png")
const TOOL_ACTION_DURATION := 0.48

signal interaction_requested
signal attack_requested
signal health_changed(current: float, maximum: float)
signal died
signal stamina_changed(current: float, maximum: float)
signal hunger_changed(current: float, maximum: float)
signal thirst_changed(current: float, maximum: float)
signal level_changed(level: int, experience: int, next_level_experience: int)
signal action_failed(reason: String)

@export var move_speed := 180.0
@export var max_health := 100.0
@export var attack_cooldown := 0.38
@export var sprint_speed_multiplier := 1.5
@export var max_stamina := 100.0
@export var stamina_regeneration_per_second := 22.0
@export var sprint_stamina_per_second := 18.0
@export var attack_stamina_cost := 12.0
@export var max_hunger := 100.0
@export var hunger_loss_per_second := 0.45
@export var sprint_hunger_multiplier := 1.6
@export var starvation_damage_per_second := 5.0
@export var max_thirst := 100.0
@export var thirst_loss_per_second := 0.7
@export var sprint_thirst_multiplier := 1.8
@export var dehydration_damage_per_second := 7.0

var health := 100.0
var stamina := 100.0
var hunger := 100.0
var thirst := 100.0
var facing_direction := Vector2.DOWN
var step_time := 0.0
var attack_time_left := 0.0
var hurt_flash_left := 0.0
var attack_damage := 25.0
var equipped_weapon_id := "wooden_club"
var equipped_weapon := "木棒"
var stamina_regeneration_delay := 0.0
var well_fed_time := 0.0
var level := 1
var experience := 0
var environment_thirst_multiplier := 1.0
var tool_action_time_left := 0.0
var tool_action_row_offset := 0


func _ready() -> void:
	# 1层：战斗与防御设施；2层：树木、矿石和生活设施。
	collision_layer = 1
	collision_mask = 3
	health = max_health
	stamina = max_stamina
	hunger = max_hunger
	thirst = max_thirst
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	hunger_changed.emit(hunger, max_hunger)
	thirst_changed.emit(thirst, max_thirst)
	level_changed.emit(level, experience, get_next_level_experience())


func _physics_process(delta: float) -> void:
	tool_action_time_left = maxf(tool_action_time_left - delta, 0.0)
	well_fed_time = maxf(well_fed_time - delta, 0.0)
	attack_time_left = maxf(attack_time_left - delta, 0.0)
	hurt_flash_left = maxf(hurt_flash_left - delta, 0.0)
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var arrows := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := Vector2.ZERO if tool_action_time_left > 0.0 else (keyboard + arrows).limit_length(1.0)
	var sprinting := direction != Vector2.ZERO and Input.is_action_pressed("sprint") and stamina > 0.0
	_update_hunger(delta, sprinting)
	_update_thirst(delta, sprinting)
	var current_speed := move_speed * sprint_speed_multiplier if sprinting else move_speed
	velocity = direction * current_speed
	if sprinting:
		_spend_stamina_continuous(sprint_stamina_per_second * delta)
	else:
		_regenerate_stamina(delta)
	if direction != Vector2.ZERO:
		facing_direction = direction.normalized()
		step_time += delta * 10.0
	else:
		step_time = 0.0
	_update_character_sprite(direction)
	move_and_slide()
	global_position.x = clampf(global_position.x, 24.0, 1256.0)
	global_position.y = clampf(global_position.y, 24.0, 776.0)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if tool_action_time_left > 0.0: return
	if event.is_action_pressed("interact"):
		interaction_requested.emit()


func try_mouse_attack(target_position: Vector2) -> bool:
	if attack_time_left > 0.0 or tool_action_time_left > 0.0: return false
	var direction := global_position.direction_to(target_position)
	if direction != Vector2.ZERO: facing_direction = direction
	if not try_spend_stamina(attack_stamina_cost):
		action_failed.emit("体力不足，无法攻击")
		return false
	attack_time_left = attack_cooldown
	attack_requested.emit()
	queue_redraw()
	return true


func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	hurt_flash_left = 0.12
	health_changed.emit(health, max_health)
	if health <= 0.0:
		died.emit()


func revive(at_position: Vector2) -> void:
	global_position = at_position
	health = max_health
	stamina = max_stamina
	hunger = max_hunger * 0.55
	thirst = max_thirst * 0.45
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	hunger_changed.emit(hunger, max_hunger)
	thirst_changed.emit(thirst, max_thirst)


func reset_for_new_game(at_position: Vector2) -> void:
	global_position = at_position
	level = 1
	experience = 0
	max_health = 100.0
	health = max_health
	max_stamina = 100.0
	stamina = max_stamina
	hunger = max_hunger
	thirst = max_thirst
	well_fed_time = 0.0
	environment_thirst_multiplier = 1.0
	equip_weapon("wooden_club", "木棒", 25.0)
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	hunger_changed.emit(hunger, max_hunger)
	thirst_changed.emit(thirst, max_thirst)
	level_changed.emit(level, experience, get_next_level_experience())


func heal(amount: float) -> void:
	health = minf(health + amount, max_health)
	health_changed.emit(health, max_health)


func try_spend_stamina(amount: float) -> bool:
	if stamina < amount: return false
	stamina = maxf(stamina - amount, 0.0)
	stamina_regeneration_delay = 0.8
	stamina_changed.emit(stamina, max_stamina)
	return true


func restore_stamina(amount: float) -> void:
	stamina = minf(stamina + amount, max_stamina)
	stamina_changed.emit(stamina, max_stamina)


func restore_hunger(amount: float) -> void:
	hunger = minf(hunger + amount, max_hunger)
	hunger_changed.emit(hunger, max_hunger)


func spend_hunger(amount: float) -> void:
	hunger = maxf(hunger - amount, 0.0)
	hunger_changed.emit(hunger, max_hunger)


func restore_thirst(amount: float) -> void:
	thirst = minf(thirst + amount, max_thirst)
	thirst_changed.emit(thirst, max_thirst)


func spend_thirst(amount: float) -> void:
	thirst = maxf(thirst - amount, 0.0)
	thirst_changed.emit(thirst, max_thirst)


func _update_hunger(delta: float, sprinting: bool) -> void:
	var multiplier := sprint_hunger_multiplier if sprinting else 1.0
	hunger = maxf(hunger - hunger_loss_per_second * multiplier * delta, 0.0)
	if hunger <= 0.0: take_damage(starvation_damage_per_second * delta)
	hunger_changed.emit(hunger, max_hunger)


func _update_thirst(delta: float, sprinting: bool) -> void:
	var multiplier := (sprint_thirst_multiplier if sprinting else 1.0) * environment_thirst_multiplier
	thirst = maxf(thirst - thirst_loss_per_second * multiplier * delta, 0.0)
	if thirst <= 0.0: take_damage(dehydration_damage_per_second * delta)
	thirst_changed.emit(thirst, max_thirst)


func _spend_stamina_continuous(amount: float) -> void:
	stamina = maxf(stamina - amount, 0.0)
	stamina_regeneration_delay = 0.45
	stamina_changed.emit(stamina, max_stamina)


func _regenerate_stamina(delta: float) -> void:
	stamina_regeneration_delay = maxf(stamina_regeneration_delay - delta, 0.0)
	if stamina_regeneration_delay > 0.0 or stamina >= max_stamina: return
	var multiplier := 1.35 if well_fed_time > 0.0 else 1.0
	stamina = minf(stamina + stamina_regeneration_per_second * multiplier * delta, max_stamina)
	stamina_changed.emit(stamina, max_stamina)


func equip_weapon(item_id: String, weapon_name: String, damage: float) -> void:
	equipped_weapon_id = item_id
	equipped_weapon = weapon_name
	attack_damage = damage


func apply_well_fed(duration: float) -> void:
	well_fed_time = maxf(well_fed_time, duration)


func get_attack_damage() -> float:
	var level_multiplier := 1.0 + float(level - 1) * 0.05
	return attack_damage * level_multiplier * (1.2 if well_fed_time > 0.0 else 1.0)


func add_experience(amount: int) -> bool:
	experience += maxi(amount, 0)
	var leveled_up := false
	while experience >= get_next_level_experience():
		experience -= get_next_level_experience()
		level += 1
		max_health += 10.0
		max_stamina += 5.0
		health = max_health
		stamina = max_stamina
		leveled_up = true
	level_changed.emit(level, experience, get_next_level_experience())
	if leveled_up:
		health_changed.emit(health, max_health)
		stamina_changed.emit(stamina, max_stamina)
	return leveled_up


func get_next_level_experience() -> int:
	return 40 + (level - 1) * 25


func play_tool_action(action_type: String) -> void:
	# 动作表第1组是锄地（0-3行），第2组是砍树（4-7行）。
	match action_type:
		"axe": tool_action_row_offset = 4
		"water": tool_action_row_offset = 8
		_: tool_action_row_offset = 0
	tool_action_time_left = TOOL_ACTION_DURATION
	velocity = Vector2.ZERO
	_update_character_sprite(Vector2.ZERO)


func _get_direction_row() -> int:
	if absf(facing_direction.x) > absf(facing_direction.y):
		return 3 if facing_direction.x > 0.0 else 2
	return 0 if facing_direction.y > 0.0 else 1


func _update_character_sprite(direction: Vector2) -> void:
	if not is_instance_valid(character_sprite): return
	var direction_row := _get_direction_row()
	if tool_action_time_left > 0.0:
		character_sprite.texture = ACTION_TEXTURE
		character_sprite.hframes = 3
		character_sprite.vframes = 12
		var elapsed := TOOL_ACTION_DURATION - tool_action_time_left
		var action_frame := mini(int(elapsed / (TOOL_ACTION_DURATION / 3.0)), 2)
		character_sprite.frame = (tool_action_row_offset + direction_row) * 3 + action_frame
		character_sprite.modulate = Color("#ffb3ad") if hurt_flash_left > 0.0 else Color.WHITE
		return
	if character_sprite.texture != WALK_TEXTURE:
		character_sprite.texture = WALK_TEXTURE
		character_sprite.hframes = 4
		character_sprite.vframes = 4
	var animation_frame := 0 if direction == Vector2.ZERO else int(step_time) % 4
	character_sprite.frame = direction_row * 4 + animation_frame
	character_sprite.modulate = Color("#ffb3ad") if hurt_flash_left > 0.0 else Color.WHITE


func _draw() -> void:
	if attack_time_left > attack_cooldown - 0.14:
		draw_arc(facing_direction * 18.0, 24.0, facing_direction.angle() - 0.8, facing_direction.angle() + 0.8, 12, Color("#f4e3a1"), 4.0)
