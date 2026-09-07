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
