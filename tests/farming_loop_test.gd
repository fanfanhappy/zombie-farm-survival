extends SceneTree


func _init() -> void:
	var game_scene := load("res://scenes/game/game_world.tscn") as PackedScene
	var game := game_scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.reset_for_new_game()
	var plot := get_nodes_in_group("farm_plots")[0] as FarmPlot
	var initial_seed_amount: int = game.inventory.get_amount("potato_seed")
	var initial_potato_amount: int = game.inventory.get_amount("potato")
	var initial_experience: int = game.player.experience

	# 指向超出交互距离的农田只显示提示，不会误触发空挥攻击和体力消耗。
	assert(game.inventory_ui.activate_hotbar_slot(2))
	game.player.global_position = plot.global_position + Vector2(70.0, 0.0)
	var stamina_before_out_of_range: float = game.player.stamina
	game._try_mouse_world_action(plot.global_position)
	assert(plot.state == FarmPlot.PlotState.EMPTY)
	assert(game.player.stamina == stamina_before_out_of_range)
	game.player.global_position = plot.global_position + Vector2(32.0, 0.0)

	# 开垦。
	assert(plot.can_interact(game))
	plot.interact(game)
	assert(plot.state == FarmPlot.PlotState.TILLED)

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
	var saved_plot := plot.create_save_data()
	assert(saved_plot.get("dry_days") == 1)
	plot.reset_for_new_game()
	plot.restore_save_data(saved_plot, game.farming_system)
	assert(plot.crop_id == "potato" and plot.dry_days == 1)
	plot.restore_save_data({"state": FarmPlot.PlotState.GROWING, "crop_id": "missing_crop"}, game.farming_system)
	assert(plot.state == FarmPlot.PlotState.TILLED and plot.crop_id.is_empty())

	print("FARMING_LOOP_OK")
	game.queue_free()
	quit()
