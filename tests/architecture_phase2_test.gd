extends SceneTree


func _init() -> void:
	var scene := load("res://scenes/game/game_world.tscn") as PackedScene
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	assert(game.get_node("GameWorld/TerrainLayers/WorldTileMap") is WorldTileMap)
	assert(game.get_node("GameSession/PlacementSystem") is PlacementSystem)
	assert(game.get_node("GameSession/HordeSpawner") is HordeSystem)
	assert(game.get_node("GameSession/WeatherController") is WeatherSystem)
	assert(game.get_node("GameWorld/TerrainLayers/WorldTileMap/GroundLayer") is TileMapLayer)
	assert(game.get_node("GameWorld/TerrainLayers/WorldTileMap/WaterLayer") is TileMapLayer)
	assert(game.get_node("GameWorld/TerrainLayers/WorldTileMap/PathLayer") is TileMapLayer)
	assert(game.get_node("GameWorld/TerrainLayers/WorldTileMap/FenceLayer") is TileMapLayer)
	assert(game.get_node("GameWorld/TerrainLayers/WorldTileMap/WorldGridCursor") is WorldGridCursor)
	assert(game.get_node("GameWorld/LogicLayers/PondCollision") is StaticBody2D)
	assert(game.get_node("GameWorld/LogicLayers/PondCollision").get_child_count() == 7)
	assert(game.get_node("GameWorld/LogicLayers/WorldBoundaries") is StaticBody2D)
	assert(game.get_node("GameWorld/LogicLayers/WorldBoundaries").get_child_count() == 4)
	assert(game.get_node("GameWorld/DynamicYSortGroup/Player") is Player)
	assert(game.get_node("GameWorld/DynamicYSortGroup").y_sort_enabled)
	assert(game.get_node("CameraRig") is CameraRig)
	assert(game.get_node("CameraRig/MainCamera") is Camera2D)
	assert(game.get_node("GameWorld/WorldLighting") is CanvasModulate)
	assert(game.get_node("ScreenEffects/DamageVignette") is ColorRect)
	assert(game.get_node("ScreenEffects/FadeTransition") is ColorRect)
	assert(game.get_node("UI/HUD") is Control)
	assert(game.get_node("UI/InventoryUI") is InventoryUI)
	assert(game.get_node("UI/Menus/StorageUI") is StorageUI)
	assert(game.get_node("UI/Menus/CraftingPanel") is PanelContainer)
	assert(game.get_node("UI/Menus/PauseOverlay") is ColorRect)
	assert(get_nodes_in_group("farm_plots").size() == 72)
	assert(get_nodes_in_group("chickens").size() == 3)
	assert(get_nodes_in_group("mouse_action_targets").size() >= 9)
	assert(get_nodes_in_group("harvestable_resources").size() == 9)
	var resource_layers := game.get_node("GameWorld/DynamicYSortGroup/ResourceNodes/WorldResourceLayer")
	assert(resource_layers.get_node("StaticDecorations") is TileMapLayer)
	assert(resource_layers.get_node("HarvestableResources") is TileMapLayer)
	var static_tree := (load("res://scenes/world/decorations/static_tree_decoration.tscn") as PackedScene).instantiate()
	root.add_child(static_tree)
	await process_frame
	assert(static_tree.is_in_group("static_decorations"))
	assert(not static_tree.has_method("interact"))
	for plot in get_nodes_in_group("farm_plots"):
		assert(plot.get_parent().name == "FarmPlots")
	for chicken in get_nodes_in_group("chickens"):
		assert(chicken.get_parent().name == "Animals")
	game._spawn_zombie(false)
	game._spawn_ground_item("wood", 1, Vector2(300, 300))
	await process_frame
	assert(get_nodes_in_group("zombies")[0].get_parent().name == "Enemies")
	assert(get_nodes_in_group("ground_items")[0].get_parent().name == "GroundItems")
	game.inventory.add_item("bandage", 3)
	game.inventory.assign_hotbar_item(4, "bandage")
	game.objective_system.current_index = 2
	var first_plot := get_nodes_in_group("farm_plots")[0] as FarmPlot
	first_plot.restore_save_data({"state": FarmPlot.PlotState.TILLED, "watered": true}, game.farming_system)
	var fence := load("res://scenes/world/defenses/fence.tscn").instantiate() as DefenseStructure
	game.building_layer.add_child(fence)
	fence.setup("fence")
	var chest := load("res://scenes/world/storage/storage_chest.tscn").instantiate() as StorageChest
	game.building_layer.add_child(chest)
	await process_frame
	assert(game._serialize_defenses().size() == 1)
	assert(game._serialize_storage_chests().size() == 1)
	assert(game._serialize_ground_items().size() == 1)
	assert(game._serialize_farm_plots().size() == 72)
	game.reset_for_new_game()
	assert(game.inventory.get_amount("bandage") == 0)
	assert(game.inventory.get_amount("stone_hoe") == 1)
	assert(game.inventory.get_hotbar_item(0) == "wooden_club")
	assert(game.inventory.get_hotbar_item(1) == "stone_hoe")
	assert(game.inventory.get_hotbar_item(2) == "watering_can")
	assert(game.inventory.get_hotbar_item(4).is_empty())
	assert(game.objective_system.current_index == 0)
	assert(first_plot.state == FarmPlot.PlotState.EMPTY)
	assert(game.player.position == game.PLAYER_HOME)
	await process_frame
	assert(get_nodes_in_group("zombies").is_empty())
	assert(get_nodes_in_group("ground_items").is_empty())
	assert(get_nodes_in_group("defenses").is_empty())
	assert(get_nodes_in_group("storage_chests").is_empty())
	assert(int(ProjectSettings.get_setting("display/window/size/mode")) == 3)
	assert(str(ProjectSettings.get_setting("display/window/stretch/mode")) == "canvas_items")
	var main_menu := (load("res://scenes/ui/main_menu.tscn") as PackedScene).instantiate()
	root.add_child(main_menu)
	await process_frame
	assert(main_menu.get_node("Center/Menu/Margin/Content/NewGameButton") is Button)
	assert(main_menu.get_node("Center/Menu/Margin/Content/ContinueButton") is Button)
	print("ARCHITECTURE_AND_NEW_GAME_REGRESSION_OK")
	quit()
