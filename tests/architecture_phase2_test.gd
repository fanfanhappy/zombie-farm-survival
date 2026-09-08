extends SceneTree

class HarvestGameMock:
	extends Node
	var received: Dictionary = {}
	func show_message(_message: String) -> void: pass
	func add_resource(resource_type: String, amount: int, _show_message := true) -> void:
		received[resource_type] = int(received.get(resource_type, 0)) + amount


func _init() -> void:
	_validate_sprite_frames("res://resources/animations/player_sprite_frames.tres", [
		&"idle_down", &"idle_left", &"idle_right", &"idle_up",
		&"walk_down", &"walk_left", &"walk_right", &"walk_up",
		&"axe_down", &"axe_left", &"axe_right", &"axe_up",
		&"hoe_down", &"hoe_left", &"hoe_right", &"hoe_up",
		&"water_down", &"water_left", &"water_right", &"water_up",
	])
	_validate_sprite_frames("res://resources/animations/chicken_sprite_frames.tres", [&"chicken_a", &"chicken_b"])
	_validate_sprite_frames("res://resources/animations/tree_harvest_sprite_frames.tres", [&"idle", &"hit", &"break", &"depleted"])
	_validate_sprite_frames("res://resources/animations/stone_harvest_sprite_frames.tres", [&"idle", &"hit", &"break", &"depleted"])
	var scene := load("res://scenes/game/game_world.tscn") as PackedScene
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	assert(game.get_node("GameWorld/TerrainLayers/WorldTileMap") is WorldTileMap)
	assert(game.get_node("GameSession/PlacementSystem") is PlacementSystem)
	assert(game.placement_system.placeable_catalog.size() == 4)
	assert((game.placement_system.placeable_catalog.get("fence") as Dictionary).get("scene") is PackedScene)
	assert(game.get_node("GameSession/HordeSpawner") is HordeSystem)
	assert(game.get_node("GameSession/WeatherController") is WeatherSystem)
	assert(game.weather_system.catalog.size() == 3)
	assert(game.objective_system.objectives.size() == 7)
	assert(game.horde_system.waves.size() == 3)
	assert(game.defense_upgrade_system.catalog.size() == 2)
	assert(game.crafting_system.recipes.size() == 11)
	assert(game.crafting_system.get_recipes_for_station("workbench").size() == 10)
	assert(game.farming_system.crop_catalog.size() == 3)
	var potato_data: Dictionary = game.farming_system.get_crop_data("potato")
	assert(potato_data.get("visual_scene") is PackedScene)
	assert(int(potato_data.get("growth_days")) == 2)
	assert((potato_data.get("harvest") as Dictionary).get("potato") == 3)
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
	assert(game.get_node("UI/InventoryUI/HotbarPanel") is PanelContainer)
	assert(game.get_node("UI/InventoryUI/BackpackPanel") is PanelContainer)
	assert(game.get_node("UI/Menus/StorageUI") is StorageUI)
	assert(game.get_node("UI/Menus/CraftingPanel") is PanelContainer)
	assert(game.get_node("UI/Menus/PauseOverlay") is ColorRect)
	assert(get_nodes_in_group("farm_plots").size() == 72)
	assert(get_nodes_in_group("chickens").size() == 3)
	var resource_layers := game.get_node("GameWorld/DynamicYSortGroup/ResourceNodes/WorldResourceLayer")
	assert(resource_layers.get_node("StaticDecorations") is TileMapLayer)
	var harvestable_layer := resource_layers.get_node("HarvestableResources") as TileMapLayer
	assert(harvestable_layer != null)
	assert(get_nodes_in_group("harvestable_resources").size() == harvestable_layer.get_used_cells().size())
	assert(not get_nodes_in_group("harvestable_resources").is_empty())
	for harvestable in get_nodes_in_group("harvestable_resources"):
		assert(harvestable.has_method("interact"))
		if harvestable.resource_type in ["wood", "stone"]:
			assert(harvestable.get_node("ResourceAnimation") is AnimatedSprite2D)
	var static_tree := (load("res://scenes/world/decorations/static_tree_decoration.tscn") as PackedScene).instantiate()
	root.add_child(static_tree)
	await process_frame
	assert(static_tree.is_in_group("static_decorations"))
	assert(not static_tree.has_method("interact"))
	var harvest_mock := HarvestGameMock.new()
	root.add_child(harvest_mock)
	var animated_tree := (load("res://scenes/world/resources/tree_resource.tscn") as PackedScene).instantiate() as HarvestableResource
	root.add_child(animated_tree)
	await process_frame
	animated_tree.resource_animation.speed_scale = 100.0
	animated_tree._finish_harvest(harvest_mock)
	await create_timer(0.1).timeout
	assert(animated_tree.depleted)
	assert(harvest_mock.received.get("wood", 0) == animated_tree.yield_amount)
	assert(animated_tree.resource_animation.animation == &"depleted")
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
	assert(game.inventory.item_catalog.size() == 22)
	assert(game.inventory.get_amount("stone_axe") == 1)
	assert(game.inventory.get_item_data("stone_axe").get("tool_type") == "axe")
	assert(game.inventory.get_item_data("stone_axe").get("icon") is Texture2D)
	assert(game.inventory.get_amount("stone_hoe") == 1)
	assert(game.inventory.get_hotbar_item(0) == "wooden_club")
	assert(game.inventory.get_hotbar_item(1) == "stone_axe")
	assert(game.inventory.get_hotbar_item(2) == "stone_hoe")
	assert(game.inventory.get_hotbar_item(3) == "watering_can")
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


func _validate_sprite_frames(resource_path: String, required_animations: Array[StringName]) -> void:
	var frames := load(resource_path) as SpriteFrames
	assert(is_instance_valid(frames))
	for animation_name in required_animations:
		assert(frames.has_animation(animation_name))
		assert(frames.get_frame_count(animation_name) > 0)
		assert(frames.get_animation_speed(animation_name) > 0.0)
		for frame_index in frames.get_frame_count(animation_name):
			var texture := frames.get_frame_texture(animation_name, frame_index)
			assert(is_instance_valid(texture))
			if texture is AtlasTexture:
				var atlas_texture := texture as AtlasTexture
				assert(is_instance_valid(atlas_texture.atlas))
				var atlas_size := atlas_texture.atlas.get_size()
				assert(atlas_texture.region.position.x >= 0.0 and atlas_texture.region.position.y >= 0.0)
				assert(atlas_texture.region.end.x <= atlas_size.x and atlas_texture.region.end.y <= atlas_size.y)
