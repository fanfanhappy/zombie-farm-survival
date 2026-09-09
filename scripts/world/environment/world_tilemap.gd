class_name WorldTileMap
extends Node2D

const FARM_CELL_SIZE := WorldGrid.CELL_SIZE
const DEFAULT_WORLD_SETTINGS := preload("res://resources/settings/world_settings.tres")

@export var world_settings: Resource = DEFAULT_WORLD_SETTINGS

@onready var farming_layer: TileMapLayer = $FarmingTerrainLayer
@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var water_layer: TileMapLayer = $WaterLayer
@onready var hill_layer: TileMapLayer = $HillLayer
@onready var path_layer: TileMapLayer = $PathLayer
@onready var bridge_layer: TileMapLayer = $BridgeLayer
@onready var fence_layer: TileMapLayer = $FenceLayer
@onready var grid_cursor: WorldGridCursor = $WorldGridCursor
var cursor_hint := ""
var connected_farm_cells: Array[Vector2i] = []
var farm_plots_by_cell: Dictionary = {}
var terrain_refresh_queued := false


func _enter_tree() -> void:
	add_to_group("world_tilemap")


func _ready() -> void:
	call_deferred("_index_farm_plots")


func _process(_delta: float) -> void:
	_update_grid_cursor()


func _index_farm_plots() -> void:
	farm_plots_by_cell.clear()
	for node in get_tree().get_nodes_in_group("farm_plots"):
		var plot := node as FarmPlot
		farm_plots_by_cell[WorldGrid.world_to_cell(plot.global_position)] = plot
		if not plot.plot_state_changed.is_connected(_queue_terrain_refresh):
			plot.plot_state_changed.connect(_queue_terrain_refresh)
	_refresh_farming_terrain(true)


func _queue_terrain_refresh() -> void:
	if terrain_refresh_queued: return
	terrain_refresh_queued = true
	call_deferred("_run_queued_terrain_refresh")


func _run_queued_terrain_refresh() -> void:
	terrain_refresh_queued = false
	_refresh_farming_terrain()


func _refresh_farming_terrain(force := false) -> void:
	if not is_instance_valid(farming_layer):
		return
	var next_cells: Array[Vector2i] = []
	for node in get_tree().get_nodes_in_group("farm_plots"):
		var plot := node as FarmPlot
		if plot.state != FarmPlot.PlotState.EMPTY:
			next_cells.append(WorldGrid.world_to_cell(plot.global_position))
	next_cells.sort()
	if not force and next_cells == connected_farm_cells:
		return
	connected_farm_cells = next_cells
	farming_layer.clear()
	if not connected_farm_cells.is_empty():
		farming_layer.set_cells_terrain_connect(connected_farm_cells, 0, 0, true)


func register_farm_plot(plot: FarmPlot) -> void:
	var cell := WorldGrid.world_to_cell(plot.global_position)
	farm_plots_by_cell[cell] = plot
	if not plot.plot_state_changed.is_connected(_queue_terrain_refresh):
		plot.plot_state_changed.connect(_queue_terrain_refresh)
	plot.tree_exiting.connect(_on_farm_plot_exiting.bind(cell, plot), CONNECT_ONE_SHOT)
	_queue_terrain_refresh()


func unregister_farm_plot(plot: FarmPlot) -> void:
	_on_farm_plot_exiting(WorldGrid.world_to_cell(plot.global_position), plot)


func clear_farm_plot_index() -> void:
	farm_plots_by_cell.clear()
	connected_farm_cells.clear()
	_refresh_farming_terrain(true)


func get_farm_plot_at_cell(cell: Vector2i) -> FarmPlot:
	var plot := farm_plots_by_cell.get(cell) as FarmPlot
	return plot if is_instance_valid(plot) else null


func is_world_position_tillable(world_position: Vector2) -> bool:
	return is_cell_tillable(WorldGrid.world_to_cell(world_position))


func is_cell_tillable(cell: Vector2i) -> bool:
	return get_till_block_reason(cell).is_empty()


func get_till_block_reason(cell: Vector2i) -> String:
	var world_position := WorldGrid.cell_to_world(cell)
	if world_settings == null or not world_settings.world_bounds.grow(-WorldGrid.HALF_CELL).has_point(world_position):
		return "超出可操作的地图范围"
	if not _layer_has_world_cell(ground_layer, world_position):
		return "这里不是可开垦的草地"
	if _layer_has_world_cell(hill_layer, world_position):
		return "高地不能开垦"
	if _layer_has_world_cell(path_layer, world_position):
		return "道路不能开垦"
	if _layer_has_world_cell(bridge_layer, world_position):
		return "桥面不能开垦"
	if _layer_has_world_cell(fence_layer, world_position):
		return "围栏占用了这个格子"
	if get_farm_plot_at_cell(cell) != null:
		return "这里已经有农田"
	for layer_path in [
		"../../DynamicYSortGroup/ResourceNodes/StaticDecorations",
		"../../DynamicYSortGroup/ResourceNodes/HarvestableResources",
	]:
		var scene_layer := get_node_or_null(layer_path) as TileMapLayer
		if is_instance_valid(scene_layer) and _layer_has_world_cell(scene_layer, world_position):
			return "这里有资源或装饰物"
	if _has_blocking_world_object(world_position):
		return "这里被建筑、设施或资源占用"
	return ""


func is_walkable_world_position(world_position: Vector2, clearance := 7.0) -> bool:
	var offsets: Array[Vector2] = [Vector2.ZERO, Vector2(clearance, 0.0), Vector2(-clearance, 0.0), Vector2(0.0, clearance), Vector2(0.0, -clearance)]
	for offset in offsets:
		var sample: Vector2 = world_position + offset
		if not _layer_has_world_cell(ground_layer, sample) and not _layer_has_world_cell(bridge_layer, sample):
			return false
	return true


func is_buildable_world_position(world_position: Vector2) -> bool:
	return _layer_has_world_cell(ground_layer, world_position) \
		and not _layer_has_world_cell(hill_layer, world_position) \
		and not _layer_has_world_cell(path_layer, world_position) \
		and not _layer_has_world_cell(bridge_layer, world_position)


func _layer_has_world_cell(layer: TileMapLayer, world_position: Vector2) -> bool:
	if not is_instance_valid(layer):
		return false
	var map_cell := layer.local_to_map(layer.to_local(world_position))
	return layer.get_cell_source_id(map_cell) != -1


func _has_blocking_world_object(world_position: Vector2) -> bool:
	for group_name in [&"defenses", &"storage_chests", &"snare_traps", &"harvestable_resources", &"static_decorations", &"homestead_core"]:
		for node in get_tree().get_nodes_in_group(group_name):
			var object := node as Node2D
			if is_instance_valid(object) and object.global_position.distance_to(world_position) < FARM_CELL_SIZE * 0.7:
				return true
	var shape := RectangleShape2D.new()
	shape.size = Vector2(FARM_CELL_SIZE - 4.0, FARM_CELL_SIZE - 4.0)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, world_position)
	query.collision_mask = 3
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var player := get_tree().get_first_node_in_group("player") as CollisionObject2D
	if is_instance_valid(player):
		query.exclude = [player.get_rid()]
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 16):
		var collider := hit.get("collider") as Node
		if collider is CharacterBody2D:
			continue
		return true
	return false


func _on_farm_plot_exiting(cell: Vector2i, plot: FarmPlot) -> void:
	if farm_plots_by_cell.get(cell) == plot:
		farm_plots_by_cell.erase(cell)
	_queue_terrain_refresh()


func get_cursor_hint() -> String:
	return cursor_hint


func _update_grid_cursor() -> void:
	if not is_instance_valid(grid_cursor):
		return
	var mouse_position := get_global_mouse_position()
	if world_settings == null or not world_settings.world_bounds.has_point(mouse_position):
		grid_cursor.set_cursor(Vector2.ZERO, WorldGridCursor.CursorState.HIDDEN)
		cursor_hint = ""
		return
	var hovered_plot := _find_hovered_farm_plot(mouse_position)
	var player := get_tree().get_first_node_in_group("player") as Player
	if is_instance_valid(hovered_plot):
		var reachable: bool = is_instance_valid(player) and player.global_position.distance_to(hovered_plot.global_position) <= float(world_settings.farming_reach)
		grid_cursor.set_cursor(hovered_plot.global_position, WorldGridCursor.CursorState.INTERACTABLE if reachable else WorldGridCursor.CursorState.OUT_OF_REACH, FARM_CELL_SIZE)
		cursor_hint = "" if reachable else "目标太远，靠近后才能操作"
		return
	var snapped_position := WorldGrid.snap_world_position(mouse_position)
	var cell := WorldGrid.world_to_cell(snapped_position)
	var block_reason := get_till_block_reason(cell)
	if block_reason.is_empty():
		var reachable: bool = is_instance_valid(player) and player.global_position.distance_to(snapped_position) <= float(world_settings.farming_reach)
		grid_cursor.set_cursor(snapped_position, WorldGridCursor.CursorState.INTERACTABLE if reachable else WorldGridCursor.CursorState.OUT_OF_REACH, FARM_CELL_SIZE)
		cursor_hint = "选择石锄，左键开垦这格草地" if reachable else "目标太远，靠近后才能开垦"
	else:
		grid_cursor.set_cursor(snapped_position, WorldGridCursor.CursorState.BLOCKED, FARM_CELL_SIZE)
		cursor_hint = block_reason


func _find_hovered_farm_plot(mouse_position: Vector2) -> FarmPlot:
	var cell := WorldGrid.world_to_cell(mouse_position)
	var plot := farm_plots_by_cell.get(cell) as FarmPlot
	if plot == null or mouse_position.distance_to(plot.global_position) > FARM_CELL_SIZE * 0.5: return null
	return plot
