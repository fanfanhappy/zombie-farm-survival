class_name WorldSettings
extends Resource

@export_group("世界尺寸")
@export var world_bounds := Rect2(0, 0, 1280, 800)
@export_range(0.0, 256.0, 1.0) var player_margin := 24.0
@export_range(0.0, 256.0, 1.0) var placement_margin := 32.0

@export_group("交互距离")
@export_range(16.0, 512.0, 1.0) var farming_reach := 64.0
@export_range(16.0, 512.0, 1.0) var placement_reach := 240.0


func get_player_bounds() -> Rect2:
	return world_bounds.grow(-player_margin)


func get_placement_bounds() -> Rect2:
	return world_bounds.grow(-placement_margin)
