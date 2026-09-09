class_name PlacementSystem
extends Node2D

signal placement_started(item_id: String)
signal placement_ended

const GRID_SIZE := WorldGrid.CELL_SIZE
const DEFAULT_PLACEABLE_DATABASE := preload("res://resources/placements/placeable_database.tres")
const DEFAULT_WORLD_SETTINGS := preload("res://resources/settings/world_settings.tres")

@export var placeable_database: PlaceableDatabase = DEFAULT_PLACEABLE_DATABASE
@export var world_settings: Resource = DEFAULT_WORLD_SETTINGS
var game_controller: Node2D
var placement_parent: Node2D
var inventory: InventorySystem
var selected_item_id := ""
var placement_type := ""
var rotation_quarters := 0
var placement_valid := false
var preview_instance: Node2D
var placeable_catalog: Dictionary = {}


func _ready() -> void:
	if placeable_database != null:
		placeable_catalog = placeable_database.build_catalog()


func setup(controller: Node2D, world_parent: Node2D, inventory_system: InventorySystem) -> void:
	game_controller = controller
	placement_parent = world_parent
	inventory = inventory_system
	visible = false


func _process(_delta: float) -> void:
	if not is_placing(): return
	if is_instance_valid(game_controller) and is_instance_valid(game_controller.world_tile_map):
		global_position = game_controller.world_tile_map.snap_to_farm_cell(get_global_mouse_position())
	else:
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
	if not placeable_catalog.has(placement_type):
		game_controller.show_message("没有配置该物品的放置场景")
		return
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
	var definition: Dictionary = placeable_catalog.get(placement_type, {})
	var structure := (definition.get("scene") as PackedScene).instantiate() as Node2D
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
	if world_settings == null: return false
	if global_position.distance_to(game_controller.player.global_position) > world_settings.placement_reach: return false
	var definition: Dictionary = placeable_catalog.get(placement_type, {})
	var footprint: Vector2 = definition.get("footprint", Vector2(32, 32))
	var corners := [Vector2(-footprint.x, -footprint.y) * 0.5, Vector2(footprint.x, footprint.y) * 0.5]
	for corner in corners:
		if not world_settings.get_placement_bounds().has_point(global_position + corner.rotated(rotation)): return false
		if is_instance_valid(game_controller.world_tile_map) and not game_controller.world_tile_map.is_buildable_world_position(global_position + corner.rotated(rotation)): return false
	if is_instance_valid(game_controller.world_tile_map) and not game_controller.world_tile_map.is_buildable_world_position(global_position): return false
	var shape := RectangleShape2D.new()
	shape.size = footprint - Vector2(3, 3)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(rotation, global_position)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	if not get_world_2d().direct_space_state.intersect_shape(query, 8).is_empty():
		return false
	var local_transform := Transform2D(rotation, global_position).affine_inverse()
	for node in get_tree().get_nodes_in_group("farm_plots"):
		var plot := node as FarmPlot
		if plot.state == FarmPlot.PlotState.EMPTY:
			continue
		var local_plot_position := local_transform * plot.global_position
		if absf(local_plot_position.x) <= footprint.x * 0.5 and absf(local_plot_position.y) <= footprint.y * 0.5:
			return false
	return true


func _create_preview() -> void:
	if is_instance_valid(preview_instance):
		preview_instance.queue_free()
	var definition: Dictionary = placeable_catalog.get(placement_type, {})
	var preview_scene := definition.get("scene") as PackedScene
	if preview_scene == null:
		return
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
