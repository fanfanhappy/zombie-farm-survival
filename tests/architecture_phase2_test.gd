extends SceneTree

class HarvestGameMock:
	extends Node
	var received: Dictionary = {}
	func show_message(_message: String) -> void: pass
	func add_resource(resource_type: String, amount: int, _show_message := true) -> void:
		received[resource_type] = int(received.get(resource_type, 0)) + amount


func _init() -> void:
	for obsolete_scene_path in [
		"res://scenes/world/environment/pond_collision.tscn",
		"res://scenes/world/environment/world_boundaries.tscn",
		"res://scenes/world/environment/world_resource_layer.tscn",
	]:
		assert(not FileAccess.file_exists(obsolete_scene_path))
	assert(load("res://scenes/world/environment/world_grid_cursor.tscn") is PackedScene)
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
	if game.is_farming_focus_mode():
		_validate_farming_focus_architecture(game)
		print("FARMING_FOCUS_ARCHITECTURE_OK")
		game.queue_free()
		quit()
		return
	assert(game.get_node("GameWorld/TerrainLayers/WorldTileMap") is WorldTileMap)
	assert(game.get_node("GameSession/PlacementSystem") is PlacementSystem)
	assert(game.placement_system.placeable_catalog.size() == 4)
	assert((game.placement_system.placeable_catalog.get("fence") as Dictionary).get("scene") is PackedScene)
	assert(game.get_node("GameSession/HordeSpawner") is HordeSystem)
	assert(game.get_node("GameSession/WeatherController") is WeatherSystem)
	assert(game.weather_system.catalog.size() == 3)
	assert(game.objective_system.objectives.size() == 7)
	assert(game.horde_system.waves.size() == 3)
	assert(game.enemy_database.enemies.size() == 2)
	var normal_enemy: EnemyDefinition = game.enemy_database.get_definition(&"normal_infected")
	assert(normal_enemy != null)
	assert(normal_enemy.max_health == 50.0)
	assert(not normal_enemy.loot_table.is_empty())
	assert((normal_enemy.loot_table[0] as LootEntry).item_id == &"herb")
	assert(game.defense_upgrade_system.catalog.size() == 2)
	assert(game.crafting_system.recipes.size() == 11)
	assert(game.crafting_system.get_recipes_for_station("workbench").size() == 10)
	assert(game.farming_system.crop_catalog.size() == 3)
	var potato_data: Dictionary = game.farming_system.get_crop_data("potato")
	assert(potato_data.get("visual_scene") is PackedScene)
	assert(int(potato_data.get("growth_days")) == 2)
	assert((potato_data.get("harvest") as Dictionary).get("potato") == 3)
	var ground_layer := game.get_node("GameWorld/TerrainLayers/WorldTileMap/GroundLayer") as TileMapLayer
	assert(ground_layer != null)
	assert(not ground_layer.get_used_cells().is_empty())
	var water_layer := game.get_node("GameWorld/TerrainLayers/WorldTileMap/WaterLayer") as TileMapLayer
	assert(water_layer != null)
	assert(water_layer.tile_set.get_physics_layers_count() == 1)
	var water_atlas := water_layer.tile_set.get_source(0) as TileSetAtlasSource
	assert(water_atlas != null)
	var water_tile_data := water_atlas.get_tile_data(Vector2i.ZERO, 0)
	assert(water_tile_data.get_collision_polygons_count(0) == 1)
	assert(not water_layer.get_used_cells().is_empty())
	var path_layer := game.get_node("GameWorld/TerrainLayers/WorldTileMap/PathLayer") as TileMapLayer
	assert(path_layer != null)
	assert(not path_layer.get_used_cells().is_empty())
	var fence_layer := game.get_node("GameWorld/TerrainLayers/WorldTileMap/FenceLayer") as TileMapLayer
	assert(fence_layer != null)
	assert(not fence_layer.get_used_cells().is_empty())
	var farming_layer := game.get_node("GameWorld/TerrainLayers/WorldTileMap/FarmingTerrainLayer") as TileMapLayer
	assert(farming_layer != null)
	var farming_atlas := farming_layer.tile_set.get_source(0) as TileSetAtlasSource
	assert(farming_atlas != null)
	assert(farming_atlas.get_tiles_count() > 0)
	assert(game.get_node("GameWorld/TerrainLayers/WorldTileMap/WorldGridCursor") is WorldGridCursor)
	assert(not game.has_node("GameWorld/LogicLayers/PondCollision"))
	assert(game.get_node("GameWorld/LogicLayers/WorldBoundaries") is StaticBody2D)
	assert(game.get_node("GameWorld/LogicLayers/WorldBoundaries").get_child_count() == 4)
	assert(game.get_node("GameWorld/DynamicYSortGroup/Player") is Player)
	assert(game.get_node("GameWorld/DynamicYSortGroup/Player/PlayerAnimation") is PlayerAnimationController)
	assert(game.get_node("GameWorld/DynamicYSortGroup/Player/AttackEffect") is PlayerAttackEffect)
	assert(game.get_node("GameWorld/DynamicYSortGroup/Player/InputComponent") is PlayerInputComponent)
	assert(game.get_node("GameWorld/DynamicYSortGroup/Player/SurvivalComponent") is PlayerSurvivalComponent)
	assert(game.get_node("GameWorld/DynamicYSortGroup").y_sort_enabled)
	assert(game.get_node("CameraRig") is CameraRig)
	assert(game.get_node("CameraRig/MainCamera") is Camera2D)
	assert(game.get_node("GameWorld/WorldLighting") is CanvasModulate)
	assert(game.get_node("ScreenEffects/DamageVignette") is ColorRect)
	assert(game.get_node("ScreenEffects/FadeTransition") is ColorRect)
	assert(game.get_node("UI/HUD") is Control)
	assert(not game.has_node("UI/HUD/HelpPanel"))
	var objective_status := game.get_node("UI/HUD/ObjectiveStatus") as Label
	assert(objective_status != null)
	assert(objective_status.get_theme_font_size("font_size") <= 12)
	var status_panel := game.get_node("UI/HUD/StatusPanel") as Control
	assert(status_panel.size.x <= 240.0 and status_panel.size.y <= 130.0, "状态面板实际尺寸：%s" % status_panel.size)
	assert(game.get_node("UI/HUD/StatusPanel/Margin/Content/Vitals") is GridContainer)
	assert(game.get_node("UI/HUD/StatusPanel/Margin/Content/Header/Context") is Label)
	assert(not game.has_node("UI/HUD/StatusPanel/Margin/Content/Equipment"))
	assert(status_panel.get_global_rect().end.y + 2.0 <= objective_status.get_global_rect().position.y)
	assert(game.get_node("UI/InventoryUI") is InventoryUI)
	assert(game.get_node("UI/InventoryUI/HotbarPanel") is PanelContainer)
	assert(game.get_node("UI/InventoryUI/HotbarPanel/Margin/Hotbar") is HBoxContainer)
	assert(game.get_node("UI/InventoryUI/BackpackPanel") is PanelContainer)
	assert(game.get_node("UI/InventoryUI/BackpackPanel/Margin/Content/Body") is HBoxContainer)
	assert(game.get_node("UI/InventoryUI/BackpackPanel/Margin/Content/Body/LeftColumn/ItemScroll") is ScrollContainer)
	assert(game.get_node("UI/InventoryUI/BackpackPanel/Margin/Content/Body/LeftColumn/FilterBar/Search") is LineEdit)
	assert(game.get_node("UI/InventoryUI/BackpackPanel/Margin/Content/Body/LeftColumn/FilterBar/Category") is OptionButton)
	assert(game.inventory.hotbar_capacity == 9)
	assert(game.inventory_ui.hotbar.get_child_count() == 9)
	assert((game.inventory_ui.hotbar.get_child(0) as Control).size.x <= 52.0)
	game.inventory_ui.open_backpack()
	await process_frame
	var backpack_rect: Rect2 = game.inventory_ui.backpack_panel.get_global_rect()
	var hotbar_rect: Rect2 = game.get_node("UI/InventoryUI/HotbarPanel").get_global_rect()
	assert(backpack_rect.size.x <= 700.0 and backpack_rect.size.y <= 390.0, "背包实际尺寸：%s" % backpack_rect.size)
	assert(hotbar_rect.size.x <= 560.0 and hotbar_rect.size.y <= 66.0, "快捷栏实际尺寸：%s" % hotbar_rect.size)
	assert(backpack_rect.position.x >= 8.0)
	assert(backpack_rect.position.y >= 8.0)
	assert(backpack_rect.end.x <= game.get_viewport_rect().size.x - 8.0)
	assert(backpack_rect.end.y + 4.0 <= hotbar_rect.position.y)
	game.inventory_ui.close_backpack()
	assert(InputMap.has_action("hotbar_slot_8"))
	assert(InputMap.has_action("hotbar_slot_9"))
	assert(game.inventory_ui.cycle_hotbar(1))
	assert(game.inventory_ui.selected_hotbar_index == 0)
	game.inventory_ui.reset_selection()
	assert(game.get_node("UI/Menus/StorageUI") is StorageUI)
	assert(game.get_node("UI/Menus/CraftingPanel") is PanelContainer)
	assert(game.get_node("UI/Menus/PauseOverlay") is ColorRect)
	assert(game.get_node("UI/Menus/SettingsUI") is SettingsUI)
	assert(game.get_node("UI/Menus/PauseOverlay/PausePanel/Margin/Buttons/Settings") is Button)
	assert(get_nodes_in_group("farm_plots").is_empty())
	assert(farming_layer.get_used_cells().is_empty())
	assert(get_nodes_in_group("chickens").size() == 3)
	var resource_layers := game.get_node("GameWorld/DynamicYSortGroup/ResourceNodes")
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
	var spawned_zombie := get_nodes_in_group("zombies")[0] as Zombie
	assert(spawned_zombie.get_parent().name == "Enemies")
	assert(spawned_zombie.definition == normal_enemy)
	assert(spawned_zombie.get_node("HealthBar") is ProgressBar)
	var spawned_ground_item := get_nodes_in_group("ground_items")[0] as GroundItem
	assert(spawned_ground_item.get_parent().name == "GroundItems")
	assert(spawned_ground_item.icon is Texture2D)
	assert(spawned_ground_item.get_node("ItemIcon").texture == spawned_ground_item.icon)
	game.inventory.add_item("bandage", 3)
	game.inventory.assign_hotbar_item(8, "bandage")
	game.inventory_ui.search_input.text = "bandage"
	assert(game.inventory_ui._get_filtered_item_ids() == ["bandage"])
	game.inventory_ui.search_input.text = ""
	game.inventory_ui.category_filter.select(2)
	var filtered_tools: Array[String] = game.inventory_ui._get_filtered_item_ids()
	assert(not filtered_tools.is_empty())
	for item_id in filtered_tools: assert(game.inventory.get_item_data(item_id).get("category") == "tool")
	game.inventory_ui.category_filter.select(0)
	game.objective_system.current_index = 2
	var first_plot: FarmPlot = game.farming_system.create_plot_at_cell(Vector2i(7, 14), false)
	first_plot.restore_save_data({"state": FarmPlot.PlotState.TILLED, "watered": true}, game.farming_system)
	var second_plot: FarmPlot = game.farming_system.create_plot_at_cell(Vector2i(8, 14), false)
	second_plot.restore_save_data({"state": FarmPlot.PlotState.TILLED}, game.farming_system)
	await process_frame
	var fence := load("res://scenes/world/defenses/fence.tscn").instantiate() as DefenseStructure
	game.building_layer.add_child(fence)
	fence.setup("fence")
	var chest := load("res://scenes/world/storage/storage_chest.tscn").instantiate() as StorageChest
	game.building_layer.add_child(chest)
	await process_frame
	assert(game.persistence.serialize_defenses(game).size() == 1)
	assert(game.persistence.serialize_storage_chests(game).size() == 1)
	assert(game.persistence.serialize_ground_items(game).size() == 1)
	assert(game.persistence.serialize_farm_plots(game).size() == 2)
	var complete_save_data: Dictionary = game.persistence.create_save_data(game)
	assert(int(complete_save_data.get("version")) == 22)
	assert(complete_save_data.get("enemies") is Array)
	var saved_plot := (complete_save_data.get("farm_plots") as Array)[0] as Dictionary
	assert(saved_plot.has("cell_x") and saved_plot.has("cell_y"))
	var saved_chicken := (complete_save_data.get("chickens") as Array)[0] as Dictionary
	assert(not str(saved_chicken.get("persistence_id", "")).is_empty())
	assert((complete_save_data.get("inventory") as Dictionary).has("items"))
	assert(game.inventory.remove_item("bandage", 3))
	assert(game.inventory.get_hotbar_item(8).is_empty())
	(normal_enemy.loot_table[0] as LootEntry).chance = 1.0
	var ground_item_count := get_nodes_in_group("ground_items").size()
	spawned_zombie.take_damage(spawned_zombie.max_health, game.player)
	await process_frame
	assert(get_nodes_in_group("ground_items").size() == ground_item_count + 1)
	var found_enemy_drop := false
	for ground_item in get_nodes_in_group("ground_items"):
		if (ground_item as GroundItem).item_id == "herb": found_enemy_drop = true
	assert(found_enemy_drop)
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
	assert(game.inventory.get_hotbar_item(8).is_empty())
	assert(game.inventory_ui.selected_hotbar_index == -1)
	assert(game.objective_system.current_index == 0)
	assert(get_nodes_in_group("farm_plots").is_empty())
	assert(farming_layer.get_used_cells().is_empty())
	assert(game.player.position == game.player_home)
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
	assert(main_menu.get_node("Center/Menu/Margin/Content/SettingsButton") is Button)
	assert(main_menu.get_node("SettingsUI") is SettingsUI)
	assert(not main_menu.has_node("Center/Menu/Margin/Content/FullscreenHint"))
	var main_menu_panel := main_menu.get_node("Center/Menu") as Control
	assert(main_menu_panel.size.x <= 430.0 and main_menu_panel.size.y <= 350.0, "主菜单实际尺寸：%s" % main_menu_panel.size)
	var settings_panel := main_menu.get_node("SettingsUI/Dimmer/Center/Panel") as Control
	assert(settings_panel.custom_minimum_size.x <= 560.0 and settings_panel.custom_minimum_size.y <= 440.0)
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


func _validate_farming_focus_architecture(game: Node) -> void:
	assert(game.get_node("GameWorld/TerrainLayers/WorldTileMap") is WorldTileMap)
	assert(game.get_node("GameSession/FarmingSystem") is FarmingSystem)
	assert(game.get_node("GameWorld/LogicLayers/FarmingGrid") is FarmingGridLayer)
	assert(game.get_node("GameWorld/DynamicYSortGroup/FarmPlots") is Node2D)
	assert(game.get_node("GameWorld/DynamicYSortGroup/ResourceNodes").get_child_count() == 0)
	assert(game.get_node("GameWorld/DynamicYSortGroup/BuildingLayer").get_child_count() == 0)
	assert(game.get_node("GameWorld/DynamicYSortGroup/Animals").get_child_count() == 0)
	var facilities := game.get_node("GameWorld/DynamicYSortGroup/Facilities")
	assert(facilities.get_child_count() == 2)
	assert(facilities.get_node("SleepPoint") is SleepPoint)
	assert(facilities.get_node("WaterPump") is WaterPump)
