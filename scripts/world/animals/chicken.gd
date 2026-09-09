class_name Chicken
extends CharacterBody2D

const ROAM_RADIUS := 54.0

var home_position := Vector2.ZERO
var roam_target := Vector2.ZERO
var decision_time := 0.0
var egg_ready := false
@export var chicken_index := 0
@export var persistence_id: StringName
@onready var sprite: AnimatedSprite2D = $ChickenAnimation
@onready var world_tile_map: WorldTileMap = get_tree().get_first_node_in_group("world_tilemap") as WorldTileMap


func setup(at_position: Vector2, index: int) -> void:
	position = at_position
	home_position = at_position
	roam_target = at_position
	chicken_index = index


func _ready() -> void:
	home_position = position
	roam_target = position
	add_to_group("chickens")
	add_to_group("interactables")
	add_to_group("mouse_action_targets")
	z_index = 3
	sprite.play(&"chicken_a" if chicken_index % 2 == 0 else &"chicken_b")
	_choose_next_target()


func _physics_process(delta: float) -> void:
	decision_time -= delta
	if decision_time <= 0.0 or global_position.distance_to(roam_target) < 3.0:
		_choose_next_target()
	var direction := global_position.direction_to(roam_target)
	velocity = direction * 18.0
	var previous_position := global_position
	move_and_slide()
	if is_instance_valid(world_tile_map) and not world_tile_map.is_walkable_world_position(global_position, 5.0):
		global_position = previous_position
		velocity = Vector2.ZERO
		_choose_next_target()
	if absf(direction.x) > 0.05:
		sprite.flip_h = direction.x < 0.0


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
	return {"persistence_id": get_persistence_id(), "x": position.x, "y": position.y, "egg_ready": egg_ready}


func get_persistence_id() -> String:
	return String(persistence_id) if not persistence_id.is_empty() else String(name)


func restore_save_data(data: Dictionary) -> void:
	position = Vector2(float(data.get("x", home_position.x)), float(data.get("y", home_position.y)))
	roam_target = position
	egg_ready = bool(data.get("egg_ready", false))


func _choose_next_target() -> void:
	decision_time = randf_range(1.5, 3.5)
	for _attempt in 8:
		var candidate := home_position + Vector2(randf_range(-ROAM_RADIUS, ROAM_RADIUS), randf_range(-ROAM_RADIUS, ROAM_RADIUS))
		if not is_instance_valid(world_tile_map) or world_tile_map.is_walkable_world_position(candidate, 5.0):
			roam_target = candidate
			return
	roam_target = home_position
