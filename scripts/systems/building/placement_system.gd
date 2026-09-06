class_name PlacementSystem
extends Node2D

signal placement_started(item_id: String)
signal placement_ended

const GRID_SIZE := 32.0
const MAP_BOUNDS := Rect2(32, 32, 1216, 736)

var game_world: Node2D
var inventory: InventorySystem
var selected_item_id := ""
var placement_type := ""
var rotation_quarters := 0
var placement_valid := false


func setup(world: Node2D, inventory_system: InventorySystem) -> void:
	game_world = world
	inventory = inventory_system
	visible = false


func _process(_delta: float) -> void:
	if not is_placing(): return
	global_position = get_global_mouse_position().snapped(Vector2(GRID_SIZE, GRID_SIZE))
	rotation = rotation_quarters * PI * 0.5
	placement_valid = _check_placement_valid()
	queue_redraw()


func begin_placement(item_id: String) -> void:
	if not inventory.has_item(item_id):
		game_world.show_message("背包里没有这个物品")
		return
	var item_data := inventory.get_item_data(item_id)
	if item_data.get("category", "") != "placeable": return
	selected_item_id = item_id
	placement_type = item_data.get("placement_type", "")
	rotation_quarters = 0
	visible = true
	placement_started.emit(item_id)
	game_world.show_message("左键放置　R旋转　右键或Esc取消")


func rotate_preview() -> void:
	if not is_placing(): return
	rotation_quarters = (rotation_quarters + 1) % 4


func try_place() -> bool:
	if not is_placing() or not placement_valid: return false
	if not inventory.remove_item(selected_item_id, 1):
		cancel_placement(); return false
	var structure: Node2D
	if placement_type == "storage_chest": structure = StorageChest.new()
	else: structure = DefenseStructure.new()
	structure.position = global_position
	structure.rotation = rotation
	game_world.add_child(structure)
	if structure is DefenseStructure: structure.setup(placement_type)
	game_world.show_message("已放置%s" % inventory.get_display_name(selected_item_id))
	if not inventory.has_item(selected_item_id): cancel_placement()
	return true


func cancel_placement() -> void:
	selected_item_id = ""
	placement_type = ""
	visible = false
	queue_redraw()
	placement_ended.emit()


func is_placing() -> bool:
	return not selected_item_id.is_empty()


func _check_placement_valid() -> bool:
	if global_position.distance_to(game_world.player.global_position) > 240.0: return false
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


func _draw() -> void:
	if not is_placing(): return
	var color := Color(0.35, 0.9, 0.45, 0.65) if placement_valid else Color(0.95, 0.28, 0.25, 0.65)
	if placement_type == "fence":
		draw_rect(Rect2(-24, -8, 48, 16), color)
		for x in [-18, 0, 18]: draw_rect(Rect2(x - 3, -13, 6, 26), color)
	elif placement_type == "storage_chest":
		draw_rect(Rect2(-21, -14, 42, 28), color)
		draw_rect(Rect2(-4, -2, 8, 10), color.lightened(0.18))
	else:
		for x in [-10, 0, 10]: draw_colored_polygon(PackedVector2Array([Vector2(x - 5, 13), Vector2(x, -14), Vector2(x + 5, 13)]), color)
