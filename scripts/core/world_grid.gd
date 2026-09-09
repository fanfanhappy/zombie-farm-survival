class_name WorldGrid
extends RefCounted

## 所有世界瓦片使用16像素原图、2倍显示、32像素逻辑格。
const ART_TILE_SIZE := Vector2i(16, 16)
const ART_SCALE := Vector2(2.0, 2.0)
const CELL_SIZE := 32.0
const HALF_CELL := CELL_SIZE * 0.5


static func snap_world_position(world_position: Vector2) -> Vector2:
	return Vector2(
		roundf(world_position.x / CELL_SIZE) * CELL_SIZE,
		roundf(world_position.y / CELL_SIZE) * CELL_SIZE
	)


static func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(roundi(world_position.x / CELL_SIZE), roundi(world_position.y / CELL_SIZE))


static func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_SIZE


## 以实际 TileMapLayer 为准换算格子，避免图层缩放、偏移或原生瓦片尺寸改变后错位。
static func layer_world_to_cell(layer: TileMapLayer, world_position: Vector2) -> Vector2i:
	if not is_instance_valid(layer):
		return world_to_cell(world_position)
	return layer.local_to_map(layer.to_local(world_position))


static func layer_cell_to_world(layer: TileMapLayer, cell: Vector2i) -> Vector2:
	if not is_instance_valid(layer):
		return cell_to_world(cell)
	return layer.to_global(layer.map_to_local(cell))


static func snap_to_layer(layer: TileMapLayer, world_position: Vector2) -> Vector2:
	return layer_cell_to_world(layer, layer_world_to_cell(layer, world_position))


static func get_layer_cell_size(layer: TileMapLayer) -> float:
	if not is_instance_valid(layer) or layer.tile_set == null:
		return CELL_SIZE
	var tile_width := float(layer.tile_set.tile_size.x)
	var origin := layer.to_global(Vector2.ZERO)
	return origin.distance_to(layer.to_global(Vector2(tile_width, 0.0)))
