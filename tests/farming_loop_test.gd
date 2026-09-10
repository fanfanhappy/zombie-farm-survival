extends SceneTree


func _init() -> void:
	var game_scene := load("res://scenes/game/game_world.tscn") as PackedScene
	var game := game_scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.reset_for_new_game()
	assert(get_nodes_in_group("farm_plots").is_empty())
	var tillable_cell := _find_tillable_cell(game.world_tile_map)
	assert(tillable_cell != Vector2i(-999, -999))
	var ground_layer := game.world_tile_map.get_node("GroundLayer") as TileMapLayer
	var farming_grid := game.get_node("GameWorld/LogicLayers/FarmingGrid") as TileMapLayer
	assert(not game.world_tile_map.has_explicit_farming_grid())
	var another_tillable_cell := _find_tillable_cell(game.world_tile_map, tillable_cell)
	assert(another_tillable_cell != Vector2i(-999, -999))
	farming_grid.set_cell(tillable_cell, ground_layer.get_cell_source_id(tillable_cell), ground_layer.get_cell_atlas_coords(tillable_cell), ground_layer.get_cell_alternative_tile(tillable_cell))
	assert(game.world_tile_map.has_explicit_farming_grid())
	assert(game.world_tile_map.is_cell_tillable(tillable_cell))
	assert(not game.world_tile_map.is_cell_tillable(another_tillable_cell))
	farming_grid.clear()
	assert(not game.world_tile_map.has_explicit_farming_grid())
	var plot_position: Vector2 = game.world_tile_map.farm_cell_to_world(tillable_cell)
	var initial_seed_amount: int = game.inventory.get_amount("potato_seed")
	var initial_potato_amount: int = game.inventory.get_amount("potato")
	var initial_experience: int = game.player.experience

	# 指向超出交互距离的农田只显示提示，不会误触发空挥攻击和体力消耗。
	assert(game.inventory_ui.activate_hotbar_slot(2))
	game.player.global_position = plot_position + Vector2(70.0, 0.0)
	var stamina_before_out_of_range: float = game.player.stamina
	game._try_mouse_world_action(plot_position)
	assert(get_nodes_in_group("farm_plots").is_empty())
	assert(game.player.stamina == stamina_before_out_of_range)
	game.player.global_position = plot_position + Vector2(32.0, 0.0)

	# 有效草地会在点击时动态创建农田并立即开垦。
	game._try_mouse_world_action(plot_position)
	var plot: FarmPlot = game.world_tile_map.get_farm_plot_at_cell(tillable_cell)
	assert(plot != null)
	assert(plot.state == FarmPlot.PlotState.TILLED)
	assert(not game.world_tile_map.is_cell_tillable(tillable_cell))

	# 水面现在是整张地图的视觉底图；只有上方存在草地的格子才是可开垦陆地。
	var water_layer := game.world_tile_map.get_node("WaterLayer") as TileMapLayer
	var water_only_cell := Vector2i(-999, -999)
	for map_cell in water_layer.get_used_cells():
		var world_position := water_layer.to_global(water_layer.map_to_local(map_cell))
		var ground_cell := ground_layer.local_to_map(ground_layer.to_local(world_position))
		if ground_layer.get_cell_source_id(ground_cell) < 0:
			water_only_cell = map_cell
			break
	assert(water_only_cell != Vector2i(-999, -999))
	var water_only_position := water_layer.to_global(water_layer.map_to_local(water_only_cell))
	assert(not game.world_tile_map.is_world_position_tillable(water_only_position))
	# 道路允许暂时为空；一旦绘制，任意道路格都必须阻止开垦。
	var path_layer := game.world_tile_map.get_node("PathLayer") as TileMapLayer
	if not path_layer.get_used_cells().is_empty():
		var path_cell := path_layer.get_used_cells()[0]
		var path_position := path_layer.to_global(path_layer.map_to_local(path_cell))
		assert(not game.world_tile_map.is_world_position_tillable(path_position))
	# 初始资源层保持为空；以后重新放置的可采集资源仍必须阻止开垦。
	var blocked_cell := _find_tillable_cell(game.world_tile_map, tillable_cell)
	assert(blocked_cell != Vector2i(-999, -999))
	var temporary_resource := Node2D.new()
	temporary_resource.add_to_group("harvestable_resources")
	game.get_node("GameWorld/DynamicYSortGroup/ResourceNodes").add_child(temporary_resource)
	temporary_resource.global_position = game.world_tile_map.farm_cell_to_world(blocked_cell)
	assert(not game.world_tile_map.is_cell_tillable(blocked_cell))
	temporary_resource.queue_free()

	# 已开垦农田没有物理碰撞，也必须阻止建筑放置覆盖。
	game.placement_system.placement_type = "fence"
	game.placement_system.global_position = plot_position
	assert(not game.placement_system._check_placement_valid())
	game.placement_system.placement_type = ""

	# 播种。
	game.inventory.assign_hotbar_item(4, "potato_seed")
	assert(game.inventory_ui.activate_hotbar_slot(4))
	assert(plot.can_interact(game))
	plot.interact(game)
	assert(plot.state == FarmPlot.PlotState.PLANTED)
	assert(plot.crop_id == "potato")
	assert(plot.crop_visual != null and plot.crop_visual.get_stage_count() == 5)
	assert(game.inventory.get_amount("potato_seed") == initial_seed_amount - 1)
	assert("0/2天" in plot.get_interaction_prompt())

	# 浇水后跨日生长；漏浇一天只停长，不立即死亡。
	assert(game.inventory_ui.activate_hotbar_slot(3))
	var water_before: int = game.watering_can_water
	assert(plot.can_interact(game))
	plot.interact(game)
	assert(plot.watered)
	assert(game.watering_can_water == water_before - 1)
	assert(plot.advance_day() == FarmPlot.DayResult.GREW)
	assert(plot.state == FarmPlot.PlotState.GROWING)
	assert(plot.growth_days == 1)
	assert(plot.advance_day() == FarmPlot.DayResult.MISSED_WATER)
	assert(plot.state == FarmPlot.PlotState.GROWING)
	assert(plot.growth_days == 1 and plot.dry_days == 1)

	# 降雨浇灌后，下一天成熟并可收获；种子能够自循环。
	assert(plot.water_from_rain())
	assert(plot.advance_day() == FarmPlot.DayResult.READY_TO_HARVEST)
	assert(plot.state == FarmPlot.PlotState.READY)
	plot.interact(game)
	assert(plot.state == FarmPlot.PlotState.TILLED)
	assert(game.inventory.get_amount("potato") == initial_potato_amount + 3)
	assert(game.inventory.get_amount("potato_seed") == initial_seed_amount)
	assert(game.player.experience > initial_experience)

	# 连续缺水达到作物容忍天数后枯萎，使用锄头可清理。
	game.inventory.assign_hotbar_item(4, "potato_seed")
	assert(game.inventory_ui.activate_hotbar_slot(4))
	plot.interact(game)
	for day_index in plot.get_dry_tolerance_days():
		plot.advance_day()
	assert(plot.state == FarmPlot.PlotState.WITHERED)
	assert("枯萎" in plot.get_interaction_prompt())
	assert(game.inventory_ui.activate_hotbar_slot(2))
	assert(plot.can_interact(game))
	plot.interact(game)
	assert(plot.state == FarmPlot.PlotState.TILLED)

	# 新字段可保存恢复，错误作物引用会安全回到已开垦状态。
	game.inventory.assign_hotbar_item(4, "potato_seed")
	assert(game.inventory_ui.activate_hotbar_slot(4))
	plot.interact(game)
	plot.advance_day()
	var saved_plot: Dictionary = plot.create_save_data()
	assert(saved_plot.get("dry_days") == 1)
	game.farming_system.reset_for_new_game()
	assert(get_nodes_in_group("farm_plots").is_empty())
	game.persistence.restore_farm_plots(game, [saved_plot], 22)
	plot = game.world_tile_map.get_farm_plot_at_cell(tillable_cell)
	assert(plot != null)
	assert(plot.crop_id == "potato" and plot.dry_days == 1)
	plot.restore_save_data({"state": FarmPlot.PlotState.GROWING, "crop_id": "missing_crop"}, game.farming_system)
	assert(plot.state == FarmPlot.PlotState.TILLED and plot.crop_id.is_empty())

	print("FARMING_LOOP_OK")
	game.queue_free()
	quit()


func _find_tillable_cell(world_tile_map: WorldTileMap, excluded := Vector2i(-999, -999)) -> Vector2i:
	for y in range(1, 24):
		for x in range(1, 39):
			var cell := Vector2i(x, y)
			if cell != excluded and world_tile_map.is_cell_tillable(cell):
				return cell
	return Vector2i(-999, -999)
