extends SceneTree


func _init() -> void:
	var game_scene := load("res://scenes/game/game_world.tscn") as PackedScene
	var game := game_scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.reset_for_new_game()

	assert(game.is_farming_focus_mode())
	assert(not game.horde_label.visible)
	assert(not game.objective_label.visible)
	assert(not game.animals_root.visible)
	assert(not game.enemies_root.visible)
	assert(not game.player.survival_needs_enabled)
	assert(game.crafting_system.process_mode == Node.PROCESS_MODE_DISABLED)
	assert(game.placement_system.process_mode == Node.PROCESS_MODE_DISABLED)
	assert(game.horde_system.process_mode == Node.PROCESS_MODE_DISABLED)
	assert(game.objective_system.process_mode == Node.PROCESS_MODE_DISABLED)

	assert(game.inventory.has_item("stone_hoe"))
	assert(game.inventory.has_item("watering_can"))
	assert(game.inventory.has_item("potato_seed", 8))
	assert(not game.inventory.has_item("wooden_club"))
	assert(not game.inventory.has_item("stone_axe"))
	assert(not game.inventory.has_item("wood_fence"))
	assert(game.inventory.get_hotbar_item(2) == "stone_hoe")
	assert(game.inventory.get_hotbar_item(3) == "watering_can")
	assert(game.inventory.get_hotbar_item(4) == "potato_seed")

	game._spawn_night_threat()
	game._spawn_zombie(&"normal_infected")
	assert(get_nodes_in_group("zombies").is_empty())
	var water_pump := game.get_node("GameWorld/DynamicYSortGroup/Facilities/WaterPump") as WaterPump
	var sleep_point := game.get_node("GameWorld/DynamicYSortGroup/Facilities/SleepPoint") as SleepPoint
	assert(game.is_target_allowed_in_current_mode(water_pump))
	assert(game.is_target_allowed_in_current_mode(sleep_point))
	assert(water_pump.is_in_group("mouse_action_targets"))
	assert(sleep_point.is_in_group("mouse_action_targets"))
	assert(not game.is_target_allowed_in_current_mode(game.homestead))

	# 选中水壶后可直接点击取水泵补水。
	assert(game.inventory_ui.activate_hotbar_slot(3))
	game.watering_can_water = 0
	game.player.global_position = water_pump.global_position + Vector2(48.0, 0.0)
	game._try_mouse_world_action(water_pump.global_position)
	assert(game.watering_can_water == game.watering_can_capacity)

	# 专注模式暂停了生存需求，睡觉推进农田时不应再扣饥饿或口渴。
	game.day_progress = float(game.game_rules.earliest_sleep_hour) / 24.0
	game.player.hunger = 1.0
	game.player.thirst = 1.0
	var day_before_sleep: int = game.day
	game.player.global_position = sleep_point.global_position + Vector2(48.0, 0.0)
	game._try_mouse_world_action(sleep_point.global_position)
	assert(game.day == day_before_sleep + 1)
	assert(game.player.hunger == 1.0)
	assert(game.player.thirst == 1.0)

	print("FARMING_FOCUS_MODE_OK")
	game.queue_free()
	quit()
