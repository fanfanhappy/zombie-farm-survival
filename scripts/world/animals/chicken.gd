class_name Chicken
extends CharacterBody2D

const CHICKEN_TEXTURE := preload("res://assets/art/characters/free_chicken_sprites.png")
const ROAM_RADIUS := 54.0

var home_position := Vector2.ZERO
var roam_target := Vector2.ZERO
var decision_time := 0.0
var egg_ready := false
var animation_time := 0.0
var chicken_index := 0
var sprite: Sprite2D


func setup(at_position: Vector2, index: int) -> void:
	position = at_position
	home_position = at_position
	roam_target = at_position
	chicken_index = index


func _ready() -> void:
	add_to_group("chickens")
	add_to_group("interactables")
	add_to_group("mouse_action_targets")
	z_index = 3
	sprite = Sprite2D.new()
	sprite.texture = CHICKEN_TEXTURE
	sprite.hframes = 4
	sprite.vframes = 2
	sprite.scale = Vector2(2.0, 2.0)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	_choose_next_target()


func _physics_process(delta: float) -> void:
	decision_time -= delta
	animation_time += delta
	if decision_time <= 0.0 or global_position.distance_to(roam_target) < 3.0:
		_choose_next_target()
	var direction := global_position.direction_to(roam_target)
	velocity = direction * 18.0
	move_and_slide()
	if absf(direction.x) > 0.05:
		sprite.flip_h = direction.x < 0.0
	sprite.frame = chicken_index % 2 * 4 + (int(animation_time * 3.0) % 2)


func get_interaction_prompt() -> String:
	return "左键/E 收取鸡蛋" if egg_ready else "母鸡今天还没有产蛋"


func get_stamina_cost() -> float:
	return 0.0


func can_interact(game: Node) -> bool:
	if egg_ready:
		return true
	game.show_message("母鸡今天还没有产蛋")
	return false


func interact(game: Node) -> void:
	if not egg_ready:
		return
	if not game.can_add_resource("egg", 1):
		game.show_message("背包已满，暂时无法收取鸡蛋")
		return
	egg_ready = false
	game.add_resource("egg", 1)


func advance_day() -> void:
	egg_ready = true


func reset_for_new_game() -> void:
	position = home_position
	roam_target = home_position
	egg_ready = false


func create_save_data() -> Dictionary:
	return {"x": position.x, "y": position.y, "egg_ready": egg_ready}


func restore_save_data(data: Dictionary) -> void:
	position = Vector2(float(data.get("x", home_position.x)), float(data.get("y", home_position.y)))
	roam_target = position
	egg_ready = bool(data.get("egg_ready", false))


func _choose_next_target() -> void:
	decision_time = randf_range(1.5, 3.5)
	roam_target = home_position + Vector2(randf_range(-ROAM_RADIUS, ROAM_RADIUS), randf_range(-ROAM_RADIUS, ROAM_RADIUS))
