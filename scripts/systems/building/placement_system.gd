class_name PlacementSystem
extends Node2D

signal placement_started(item_id: String)
signal placement_ended

const GRID_SIZE := WorldGrid.CELL_SIZE
const MAP_BOUNDS := Rect2(32, 32, 1216, 736)
const FENCE_SCENE := preload("res://scenes/world/defenses/fence.tscn")
const SPIKE_SCENE := preload("res://scenes/world/defenses/spike.tscn")
const SNARE_TRAP_SCENE := preload("res://scenes/world/defenses/snare_trap.tscn")
const STORAGE_CHEST_SCENE := preload("res://scenes/world/storage/storage_chest.tscn")

var game_controller: Node2D
var placement_parent: Node2D
var inventory: InventorySystem
var selected_item_id := ""
var placement_type := ""
var rotation_quarters := 0
var placement_valid := false
var preview_instance: Node2D


func setup(controller: Node2D, world_parent: Node2D, inventory_system: InventorySystem) -> void:
	game_controller = controller
	placement_parent = world_parent
	inventory = inventory_system
	visible = false


func _process(_delta: float) -> void:
	if not is_placing(): return
	global_position = WorldGrid.snap_world_position(get_global_mouse_position())
	rotation = rotation_quarters * PI * 0.5
	placement_valid = _check_placement_valid()
	if is_instance_valid(preview_instance):
		preview_instance.modulate = Color(0.45, 1.0, 0.55, 0.72) if placement_valid else Color(1.0, 0.38, 0.34, 0.72)


func begin_placement(item_id: String) -> void:
	if not inventory.has_item(item_id):
		game_controller.show_message("背包里没有这个物品")
		return
	var item_data := inventory.get_item_data(item_id)
	if item_data.get("category", "") != "placeable": return
	selected_item_id = item_id
	placement_type = item_data.get("placement_type", "")
	rotation_quarters = 0
	_create_preview()
	visible = true
	placement_started.emit(item_id)
	game_controller.show_message("左键放置　R旋转　右键或Esc取消")


func rotate_preview() -> void:
	if not is_placing(): return
	rotation_quarters = (rotation_quarters + 1) % 4


func try_place() -> bool:
	if not is_placing() or not placement_valid: return false
	if not inventory.remove_item(selected_item_id, 1):
		cancel_placement(); return false
	var structure: Node2D
	if placement_type == "storage_chest": structure = STORAGE_CHEST_SCENE.instantiate()
	elif placement_type == "snare_trap": structure = SNARE_TRAP_SCENE.instantiate()
	elif placement_type == "fence": structure = FENCE_SCENE.instantiate()
	else: structure = SPIKE_SCENE.instantiate()
	structure.position = global_position
	structure.rotation = rotation
	placement_parent.add_child(structure)
	if structure is DefenseStructure: structure.setup(placement_type)
	game_controller.show_message("已放置%s" % inventory.get_display_name(selected_item_id))
	if not inventory.has_item(selected_item_id): cancel_placement()
	return true


func cancel_placement() -> void:
	selected_item_id = ""
	placement_type = ""
	visible = false
	if is_instance_valid(preview_instance):
		preview_instance.queue_free()
	preview_instance = null
	placement_ended.emit()


func is_placing() -> bool:
	return not selected_item_id.is_empty()


func _check_placement_valid() -> bool:
	if global_position.distance_to(game_controller.player.global_position) > 240.0: return false
	var footprint := Vector2(48, 20) if placement_type == "fence" else (Vector2(42, 30) if placement_type == "storage_chest" else Vector2(32, 32))
	var corners := [Vector2(-footprint.x, -footprint.y) * 0.5, Vector2(footprint.x, footprint.y) * 0.5]
	for corner in corners:
		if not MAP_BOUNDS.has_point(global_position + corner.rotated(rotation)): return false
	var shape := RectangleShape2D.new()
	shape.size = footprint - Vector2(3, 3)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(rotation, global_position)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return get_world_2d().direct_space_state.intersect_shape(query, 8).is_empty()


func _create_preview() -> void:
	if is_instance_valid(preview_instance):
		preview_instance.queue_free()
	var preview_scene: PackedScene
	match placement_type:
		"fence": preview_scene = FENCE_SCENE
		"storage_chest": preview_scene = STORAGE_CHEST_SCENE
		"snare_trap": preview_scene = SNARE_TRAP_SCENE
		_: preview_scene = SPIKE_SCENE
	preview_instance = preview_scene.instantiate() as Node2D
	preview_instance.process_mode = Node.PROCESS_MODE_DISABLED
	if preview_instance is CollisionObject2D:
		preview_instance.collision_layer = 0
		preview_instance.collision_mask = 0
	if preview_instance is Area2D:
		preview_instance.monitoring = false
	add_child(preview_instance)
	for helper_name in ["LevelLabel", "HealthBar", "ChargesLabel"]:
		var helper := preview_instance.get_node_or_null(helper_name) as CanvasItem
		if is_instance_valid(helper):
			helper.hide()
