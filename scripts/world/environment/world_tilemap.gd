class_name WorldTileMap
extends Node2D

const FARM_CELL_SIZE := WorldGrid.CELL_SIZE
const WORLD_SIZE := Vector2i(41, 26)

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var water_layer: TileMapLayer = $WaterLayer
@onready var path_layer: TileMapLayer = $PathLayer
@onready var farming_layer: TileMapLayer = $FarmingTerrainLayer
@onready var fence_layer: TileMapLayer = $FenceLayer
@onready var grid_cursor: WorldGridCursor = $WorldGridCursor
var cursor_hint := ""
var connected_farm_cells: Array[Vector2i] = []


func _ready() -> void:
	_build_ground()
	_build_pond()
	_build_paths()
	_build_perimeter_fence()


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


func _build_ground() -> void:
	if not ground_layer.get_used_cells().is_empty():
		return
	for y in WORLD_SIZE.y:
		for x in WORLD_SIZE.x:
			# 底部一排是可无缝铺设的草地，少量变化避免大面积重复感。
			var variant: int = absi((x * 17 + y * 31 + x * y * 3) % 23)
			var atlas_coord := Vector2i(0, 5)
			if variant == 3:
				atlas_coord = Vector2i(1, 5)
			elif variant == 11:
				atlas_coord = Vector2i(2, 5)
			ground_layer.set_cell(Vector2i(x, y), 0, atlas_coord)


func _build_pond() -> void:
	if not water_layer.get_used_cells().is_empty():
		return
	# 错落的行宽形成自然水塘轮廓，避开农田与主要建筑动线。
	var pond_rows := {
		4: Vector2i(7, 10),
		5: Vector2i(6, 11),
		6: Vector2i(5, 12),
		7: Vector2i(5, 12),
		8: Vector2i(6, 12),
		9: Vector2i(7, 11),
		10: Vector2i(8, 10),
	}
	for y in pond_rows:
		var horizontal_range: Vector2i = pond_rows[y]
		for x in range(horizontal_range.x, horizontal_range.y + 1):
			water_layer.set_cell(Vector2i(x, y), 0, Vector2i((x + y) % 4, 0))


func _build_paths() -> void:
	if not path_layer.get_used_cells().is_empty():
		return
	var path_cells: Dictionary = {}
	# 从南门通往农舍，再向西分出一条农田支路。
	for y in range(13, 22):
		path_cells[Vector2i(20, y)] = true
		path_cells[Vector2i(21, y)] = true
	for x in range(19, 28):
		path_cells[Vector2i(x, 13)] = true
		path_cells[Vector2i(x, 14)] = true
	for x in range(19, 21):
		path_cells[Vector2i(x, 17)] = true
	for cell in path_cells:
		path_layer.set_cell(cell, 0, Vector2i(0, 5))


func _build_perimeter_fence() -> void:
	if not fence_layer.get_used_cells().is_empty():
		return
	for x in range(4, 36):
		fence_layer.set_cell(Vector2i(x, 3), 0, Vector2i(2, 1))
		if x < 18 or x > 21:
			fence_layer.set_cell(Vector2i(x, 21), 0, Vector2i(2, 1))
	for y in range(4, 21):
		fence_layer.set_cell(Vector2i(3, y), 0, Vector2i(0, 2))
		fence_layer.set_cell(Vector2i(36, y), 0, Vector2i(0, 2))


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
