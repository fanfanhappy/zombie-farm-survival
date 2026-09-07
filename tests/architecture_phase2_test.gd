extends SceneTree


func _init() -> void:
	var scene := load("res://scenes/game/game_world.tscn") as PackedScene
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	assert(game.get_node("GameWorld/TerrainLayers/WorldTileMap") is WorldTileMap)
	assert(game.get_node("GameWorld/DynamicYSortGroup/Player") is Player)
	assert(game.get_node("GameWorld/DynamicYSortGroup").y_sort_enabled)
	assert(get_nodes_in_group("farm_plots").size() == 72)
	assert(get_nodes_in_group("chickens").size() == 3)
	assert(get_nodes_in_group("mouse_action_targets").size() >= 9)
	for plot in get_nodes_in_group("farm_plots"):
		assert(plot.get_parent().name == "FarmPlots")
	for chicken in get_nodes_in_group("chickens"):
		assert(chicken.get_parent().name == "Animals")
	game._spawn_zombie(false)
	game._spawn_ground_item("wood", 1, Vector2(300, 300))
	await process_frame
	assert(get_nodes_in_group("zombies")[0].get_parent().name == "Enemies")
	assert(get_nodes_in_group("ground_items")[0].get_parent().name == "GroundItems")
	print("ARCHITECTURE_PHASE2_OK")
	quit()
