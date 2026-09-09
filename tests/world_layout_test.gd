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
	assert(hill.position == Vector2(-16, -16))
	assert(hill.scale == Vector2(2, 2))
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
	for layer_name in ["StaticDecorations", "HarvestableResources"]:
		var layer := resource_root.get_node(layer_name) as TileMapLayer
		assert(not layer.get_used_cells().is_empty())
		for resource_cell in layer.get_used_cells():
			var position := layer.to_global(layer.map_to_local(resource_cell))
			var ground_cell := ground.local_to_map(ground.to_local(position))
			assert(ground.get_cell_source_id(ground_cell) >= 0)
	for chicken in get_nodes_in_group("chickens"):
		assert((chicken as Chicken).visible)
		assert(world_map.is_walkable_world_position((chicken as Chicken).global_position, 5.0))
	print("WORLD_LAYOUT_OK bounds=%s" % expected_bounds)
	quit()
