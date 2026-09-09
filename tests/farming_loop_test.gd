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
	var plot_position := WorldGrid.cell_to_world(tillable_cell)
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

	# 水体和道路由可视化 TileMapLayer 决定，不能被锄头覆盖。
	for blocked_layer_name in ["WaterLayer", "PathLayer"]:
		var blocked_layer := game.world_tile_map.get_node(blocked_layer_name) as TileMapLayer
		var blocked_map_cell := blocked_layer.get_used_cells()[0]
		var blocked_position := blocked_layer.to_global(blocked_layer.map_to_local(blocked_map_cell))
		assert(not game.world_tile_map.is_world_position_tillable(blocked_position))
	var resource_layer := game.get_node("GameWorld/DynamicYSortGroup/ResourceNodes/HarvestableResources") as TileMapLayer
	var resource_position := resource_layer.to_global(resource_layer.map_to_local(resource_layer.get_used_cells()[0]))
	assert(not game.world_tile_map.is_world_position_tillable(resource_position))

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


func _find_tillable_cell(world_tile_map: WorldTileMap) -> Vector2i:
	for y in range(1, 24):
		for x in range(1, 39):
			var cell := Vector2i(x, y)
			if world_tile_map.is_cell_tillable(cell):
				return cell
	return Vector2i(-999, -999)
