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
	assert(game.is_target_allowed_in_current_mode(game.get_node("GameWorld/DynamicYSortGroup/Facilities/WaterPump")))
	assert(game.is_target_allowed_in_current_mode(game.get_node("GameWorld/DynamicYSortGroup/Facilities/SleepPoint")))
	assert(not game.is_target_allowed_in_current_mode(game.homestead))

	print("FARMING_FOCUS_MODE_OK")
	game.queue_free()
	quit()
