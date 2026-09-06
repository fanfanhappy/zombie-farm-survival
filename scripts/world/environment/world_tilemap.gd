class_name WorldTileMap
extends Node2D

const TILE_SIZE := Vector2i(16, 16)
const WORLD_SIZE := Vector2i(41, 26)

const GRASS_TEXTURE := preload("res://assets/art/environment/terrain/terrain_grass_tileset.png")
const WATER_TEXTURE := preload("res://assets/art/environment/terrain/terrain_water_tileset.png")
const PATH_TEXTURE := preload("res://assets/art/environment/farming/farm_tilled_dirt_clean_tileset.png")
const FENCE_TEXTURE := preload("res://assets/art/environment/defenses/defense_fence_tileset.png")

var ground_layer: TileMapLayer
var water_layer: TileMapLayer
var path_layer: TileMapLayer
var fence_layer: TileMapLayer
var grid_cursor: WorldGridCursor
var cursor_hint := ""


func _ready() -> void:
	ground_layer = _create_layer("GroundLayer", GRASS_TEXTURE, Vector2i(11, 7), -20)
	water_layer = _create_layer("WaterLayer", WATER_TEXTURE, Vector2i(4, 1), -19)
	path_layer = _create_layer("PathLayer", PATH_TEXTURE, Vector2i(11, 7), -18)
	fence_layer = _create_layer("FenceLayer", FENCE_TEXTURE, Vector2i(4, 4), -2)
	_build_ground()
	_build_pond()
	_build_pond_collision()
	_build_paths()
	_build_perimeter_fence()
	grid_cursor = WorldGridCursor.new()
	grid_cursor.name = "WorldGridCursor"
	grid_cursor.z_index = 8
	add_child(grid_cursor)


func _process(_delta: float) -> void:
	_update_grid_cursor()


func _create_layer(layer_name: String, texture: Texture2D, atlas_size: Vector2i, layer_z_index: int) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	# 让瓦片中心与现有32像素交互网格对齐。
	layer.position = Vector2(-16.0, -16.0)
	layer.scale = Vector2(2.0, 2.0)
	layer.z_index = layer_z_index
	var tiles := TileSet.new()
	tiles.tile_size = TILE_SIZE
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = TILE_SIZE
	for y in atlas_size.y:
		for x in atlas_size.x:
			atlas.create_tile(Vector2i(x, y))
	tiles.add_source(atlas, 0)
	layer.tile_set = tiles
	add_child(layer)
	return layer


func _build_ground() -> void:
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


func _build_pond_collision() -> void:
	var pond_body := StaticBody2D.new()
	pond_body.name = "PondCollision"
	pond_body.collision_layer = 1
	pond_body.collision_mask = 0
	add_child(pond_body)
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
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2((horizontal_range.y - horizontal_range.x + 1) * 32.0, 30.0)
		collision.position = Vector2((horizontal_range.x + horizontal_range.y) * 16.0, y * 32.0)
		collision.shape = shape
		pond_body.add_child(collision)


func _build_paths() -> void:
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
	var player := get_parent().get_node_or_null("Player") as Player
	if is_instance_valid(hovered_plot):
		var reachable := is_instance_valid(player) and player.global_position.distance_to(hovered_plot.global_position) <= 64.0
		grid_cursor.set_cursor(hovered_plot.global_position, WorldGridCursor.CursorState.INTERACTABLE if reachable else WorldGridCursor.CursorState.OUT_OF_REACH)
		cursor_hint = "" if reachable else "目标太远，靠近后才能操作"
		return
	var snapped_position := Vector2(roundf(mouse_position.x / 32.0) * 32.0, roundf(mouse_position.y / 32.0) * 32.0)
	grid_cursor.set_cursor(snapped_position, WorldGridCursor.CursorState.BLOCKED)
	cursor_hint = "该区域不可耕作"


func _find_hovered_farm_plot(mouse_position: Vector2) -> FarmPlot:
	var hovered_plot: FarmPlot
	var nearest_distance := 16.0
	for node in get_tree().get_nodes_in_group("farm_plots"):
		var plot := node as FarmPlot
		var distance := mouse_position.distance_to(plot.global_position)
		if distance <= nearest_distance:
			hovered_plot = plot
			nearest_distance = distance
	return hovered_plot
