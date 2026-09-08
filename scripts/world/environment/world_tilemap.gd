class_name WorldTileMap
extends Node2D

const FARM_CELL_SIZE := WorldGrid.CELL_SIZE

@onready var farming_layer: TileMapLayer = $FarmingTerrainLayer
@onready var grid_cursor: WorldGridCursor = $WorldGridCursor
var cursor_hint := ""
var connected_farm_cells: Array[Vector2i] = []


func _process(_delta: float) -> void:
	_refresh_farming_terrain()
	_update_grid_cursor()


func _refresh_farming_terrain() -> void:
	if not is_instance_valid(farming_layer):
		return
	var next_cells: Array[Vector2i] = []
	for node in get_tree().get_nodes_in_group("farm_plots"):
		var plot := node as FarmPlot
		if plot.state != FarmPlot.PlotState.EMPTY:
			next_cells.append(WorldGrid.world_to_cell(plot.position))
	next_cells.sort()
	if next_cells == connected_farm_cells:
		return
	connected_farm_cells = next_cells
	farming_layer.clear()
	if not connected_farm_cells.is_empty():
		farming_layer.set_cells_terrain_connect(connected_farm_cells, 0, 0, true)


func get_cursor_hint() -> String:
	return cursor_hint


func _update_grid_cursor() -> void:
	if not is_instance_valid(grid_cursor):
		return
	var mouse_position := get_global_mouse_position()
	if not Rect2(0, 0, 1280, 800).has_point(mouse_position):
		grid_cursor.set_cursor(Vector2.ZERO, WorldGridCursor.CursorState.HIDDEN)
		cursor_hint = ""
		return
	var hovered_plot := _find_hovered_farm_plot(mouse_position)
	var player := get_tree().get_first_node_in_group("player") as Player
	if is_instance_valid(hovered_plot):
		var reachable := is_instance_valid(player) and player.global_position.distance_to(hovered_plot.global_position) <= 64.0
		grid_cursor.set_cursor(hovered_plot.global_position, WorldGridCursor.CursorState.INTERACTABLE if reachable else WorldGridCursor.CursorState.OUT_OF_REACH, FARM_CELL_SIZE)
		cursor_hint = "" if reachable else "目标太远，靠近后才能操作"
		return
	var snapped_position := WorldGrid.snap_world_position(mouse_position)
	grid_cursor.set_cursor(snapped_position, WorldGridCursor.CursorState.BLOCKED, FARM_CELL_SIZE)
	cursor_hint = "该区域不可耕作"


func _find_hovered_farm_plot(mouse_position: Vector2) -> FarmPlot:
	var hovered_plot: FarmPlot
	var nearest_distance := FARM_CELL_SIZE * 0.5
	for node in get_tree().get_nodes_in_group("farm_plots"):
		var plot := node as FarmPlot
		var distance := mouse_position.distance_to(plot.global_position)
		if distance <= nearest_distance:
			hovered_plot = plot
			nearest_distance = distance
	return hovered_plot
