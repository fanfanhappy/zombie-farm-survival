extends SceneTree


func _init() -> void:
	var packed := load("res://scenes/game/game_world.tscn") as PackedScene
	assert(packed != null)
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var world_map := game.world_tile_map as WorldTileMap
	var water := world_map.get_node("WaterLayer") as TileMapLayer
	var ground := world_map.get_node("GroundLayer") as TileMapLayer
	var hill := world_map.get_node("HillLayer") as TileMapLayer
	var bridge := world_map.get_node("BridgeLayer") as TileMapLayer
	assert(not water.get_used_cells().is_empty())
	assert(not ground.get_used_cells().is_empty())
	assert(not water.collision_enabled)
	# HillLayer 保留用户在编辑器中绘制时的原始显示参数，不由代码强制缩放或偏移。
	assert(hill.position == Vector2.ZERO)
	assert(hill.scale == Vector2.ONE)
	var sample_ground_cell: Vector2i = ground.get_used_cells()[0]
	var sample_ground_world := world_map.farm_cell_to_world(sample_ground_cell)
	assert(world_map.world_to_farm_cell(sample_ground_world) == sample_ground_cell)
	assert(is_equal_approx(world_map.get_farm_cell_size(), 32.0))
	assert(bridge.tile_set != null)
	var used := water.get_used_rect()
	var tile_size := water.tile_set.tile_size
	var expected_start := water.to_global(Vector2(used.position * tile_size))
	var expected_end := water.to_global(Vector2(used.end * tile_size))
	var expected_bounds := Rect2(expected_start.min(expected_end), (expected_end - expected_start).abs())
	assert(world_map.world_settings.world_bounds.is_equal_approx(expected_bounds))
	var camera := game.get_node("CameraRig/MainCamera") as Camera2D
	assert(camera.limit_left == floori(expected_bounds.position.x))
	assert(camera.limit_top == floori(expected_bounds.position.y))
	assert(camera.limit_right == ceili(expected_bounds.end.x))
	assert(camera.limit_bottom == ceili(expected_bounds.end.y))
	assert(world_map.is_walkable_world_position(game.player.global_position))
	assert(game.get_node("UI").visible)
	assert(game.get_node("GameWorld/DynamicYSortGroup/BuildingLayer").visible)
	assert(game.get_node("GameWorld/DynamicYSortGroup/Facilities").visible)
	var resource_root := game.get_node("GameWorld/DynamicYSortGroup/ResourceNodes")
	assert(resource_root.get_child_count() == 0)
	assert(game.get_node("GameWorld/DynamicYSortGroup/BuildingLayer").get_child_count() == 0)
	assert(game.get_node("GameWorld/DynamicYSortGroup/Animals").get_child_count() == 0)
	assert(get_nodes_in_group("chickens").is_empty())
	print("WORLD_LAYOUT_OK bounds=%s" % expected_bounds)
	quit()
