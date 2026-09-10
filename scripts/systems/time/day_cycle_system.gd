class_name DayCycleSystem
extends Node


func update(game: Node, delta: float) -> void:
	if not (game.horde_system.active and game.day_progress >= 0.98):
		game.day_progress += delta / game.day_length_seconds
	if game.day_progress >= 1.0: advance_to_next_day(game)
	var hour := int(game.day_progress * 24.0)
	if hour != game.last_hour:
		game.last_hour = hour
		if hour >= game.game_rules.night_threat_hour and not game.night_spawned:
			game.night_spawned = true
			game._spawn_night_threat()


func try_sleep(game: Node) -> void:
	var hour: float = float(game.day_progress) * 24.0
	if game.horde_system.active:
		game.show_message("尸潮还没有结束，现在不能睡觉"); return
	if not game.get_tree().get_nodes_in_group("zombies").is_empty():
		game.show_message("附近还有感染者，无法安心休息"); return
	if hour < game.game_rules.earliest_sleep_hour:
		game.show_message("现在还太早，%02d:00以后可以休息" % game.game_rules.earliest_sleep_hour); return
	var farming_focus: bool = game.has_method("is_farming_focus_mode") and bool(game.is_farming_focus_mode())
	if not farming_focus:
		if game.player.hunger < game.game_rules.sleep_hunger_cost:
			game.show_message("太饿了，至少需要%d点饥饿才能休息" % game.game_rules.sleep_hunger_cost); return
		if game.player.thirst < game.game_rules.sleep_thirst_cost:
			game.show_message("太渴了，至少需要%d点口渴值才能休息" % game.game_rules.sleep_thirst_cost); return
		game.player.spend_hunger(game.game_rules.sleep_hunger_cost)
		game.player.spend_thirst(game.game_rules.sleep_thirst_cost)
	advance_to_next_day(game)
	game.player.restore_stamina(game.player.max_stamina)
	game.player.heal(game.game_rules.sleep_heal)
	game.show_message("进入下一天，农田已完成每日结算" if farming_focus else "休息了一夜，生命和体力得到恢复")


func drink_from_water_pump(game: Node) -> void:
	if game.player.thirst >= game.player.max_thirst:
		game.show_message("现在不渴"); return
	game.player.restore_thirst(game.player.max_thirst)
	game.show_message("饮用了干净的井水，口渴完全恢复")


func refill_watering_can(game: Node) -> void:
	if not game.inventory.has_item("watering_can"):
		game.show_message("背包里没有浇水壶"); return
	if game.watering_can_water >= game.watering_can_capacity:
		game.show_message("浇水壶已经装满"); return
	game.watering_can_water = game.watering_can_capacity
	game.show_message("浇水壶已经装满：%d/%d" % [game.watering_can_water, game.watering_can_capacity])


func can_water_crop(game: Node) -> bool:
	if game.get_active_tool_type() != "watering_can":
		game.show_message("需要先把浇水壶放入快捷栏并选中"); return false
	if game.watering_can_water <= 0:
		game.show_message("浇水壶空了，去取水泵旁装水"); return false
	return true


func advance_to_next_day(game: Node) -> void:
	game.day_progress = game.day_start_progress
	game.day += 1
	game.night_spawned = false
	for zombie in game.get_tree().get_nodes_in_group("zombies"): zombie.queue_free()
	var farm_results := {
		FarmPlot.DayResult.GREW: 0,
		FarmPlot.DayResult.READY_TO_HARVEST: 0,
		FarmPlot.DayResult.MISSED_WATER: 0,
		FarmPlot.DayResult.WITHERED: 0,
	}
	for plot_node in game.get_tree().get_nodes_in_group("farm_plots"):
		var result: FarmPlot.DayResult = (plot_node as FarmPlot).advance_day()
		if farm_results.has(result): farm_results[result] += 1
	for chicken in game.get_tree().get_nodes_in_group("chickens"): chicken.advance_day()
	game.weather_system.choose_weather_for_day(game.day)
	var rain_watered_count := 0
	if bool(game.weather_system.get_current_data().get("waters_crops", false)):
		for plot_node in game.get_tree().get_nodes_in_group("farm_plots"):
			if (plot_node as FarmPlot).water_from_rain(): rain_watered_count += 1
	if is_instance_valid(game.homestead): game.homestead.repair(10.0)
	game.show_message(_format_new_day_message(game.day, farm_results, rain_watered_count))


func _format_new_day_message(day: int, results: Dictionary, rain_watered_count: int) -> String:
	var details: Array[String] = []
	var grew := int(results.get(FarmPlot.DayResult.GREW, 0))
	var ready := int(results.get(FarmPlot.DayResult.READY_TO_HARVEST, 0))
	var missed := int(results.get(FarmPlot.DayResult.MISSED_WATER, 0))
	var withered := int(results.get(FarmPlot.DayResult.WITHERED, 0))
	if grew > 0: details.append("%d块生长" % grew)
	if ready > 0: details.append("%d块成熟" % ready)
	if missed > 0: details.append("%d块缺水停长" % missed)
	if withered > 0: details.append("%d块枯萎" % withered)
	if rain_watered_count > 0: details.append("降雨浇灌%d块" % rain_watered_count)
	return "第%d天开始了%s" % [day, "：" + "，".join(details) if not details.is_empty() else ""]
