class_name GamePersistence
extends RefCounted


func create_save_data(game: Node) -> Dictionary:
	return {
		"version": 19, "day": game.day, "day_progress": game.day_progress,
		"weather": game.weather_system.current_weather_id,
		"inventory": game.inventory.create_save_data(),
		"player_position": {"x": game.player.position.x, "y": game.player.position.y},
		"health": game.player.health, "max_health": game.player.max_health,
		"stamina": game.player.stamina, "max_stamina": game.player.max_stamina,
		"hunger": game.player.hunger, "thirst": game.player.thirst,
		"level": game.player.level, "experience": game.player.experience,
		"well_fed_time": game.player.well_fed_time,
		"homestead_health": game.homestead.health,
		"equipped_weapon_id": game.player.equipped_weapon_id,
		"weapon": game.player.equipped_weapon, "attack_damage": game.player.attack_damage,
		"kills": game.kills, "hordes_survived": game.hordes_survived,
		"defenses": serialize_defenses(game), "storage_chests": serialize_storage_chests(game),
		"snare_traps": serialize_snare_traps(game), "ground_items": serialize_ground_items(game),
		"farm_plots": serialize_farm_plots(game), "chickens": serialize_chickens(game),
		"watering_can_water": game.watering_can_water,
		"objectives": game.objective_system.create_save_data(),
	}


func restore_save_data(game: Node, data: Dictionary) -> void:
	game.day = int(data.get("day", 1))
	game.day_progress = float(data.get("day_progress", game.day_start_progress))
	game.weather_system.set_weather(str(data.get("weather", "clear")))
	var saved_inventory: Dictionary = data.get("inventory", data.get("resources", game.starting_items))
	game.inventory.restore_save_data(saved_inventory)
	var position_data: Dictionary = data.get("player_position", {})
	game.player.position = Vector2(float(position_data.get("x", game.player_home.x)), float(position_data.get("y", game.player_home.y)))
	game.player.max_health = float(data.get("max_health", game.player.max_health))
	game.player.max_stamina = float(data.get("max_stamina", game.player.max_stamina))
	game.player.health = clampf(float(data.get("health", game.player.max_health)), 0.0, game.player.max_health)
	game.player.stamina = clampf(float(data.get("stamina", game.player.max_stamina)), 0.0, game.player.max_stamina)
	game.player.hunger = clampf(float(data.get("hunger", game.player.max_hunger)), 0.0, game.player.max_hunger)
	game.player.thirst = clampf(float(data.get("thirst", game.player.max_thirst)), 0.0, game.player.max_thirst)
	game.player.level = int(data.get("level", 1))
	game.player.experience = int(data.get("experience", 0))
	game.player.well_fed_time = float(data.get("well_fed_time", 0.0))
	game.watering_can_water = clampi(int(data.get("watering_can_water", game.watering_can_capacity)), 0, game.watering_can_capacity)
	var weapon_id := str(data.get("equipped_weapon_id", "wooden_club"))
	if not game.inventory.has_item(weapon_id):
		weapon_id = String(game.player.definition.starting_weapon_id)
	var weapon_data: Dictionary = game.inventory.get_item_data(weapon_id)
	game.player.equip_weapon(weapon_id, weapon_data.get("name", data.get("weapon", "木棒")), float(weapon_data.get("attack_damage", data.get("attack_damage", 25.0))))
	game.homestead.health = clampf(float(data.get("homestead_health", game.homestead.max_health)), 1.0, game.homestead.max_health)
	game.homestead.repair(0.0)
	restore_defenses(game, data.get("defenses", []))
	restore_storage_chests(game, data.get("storage_chests", []))
	restore_snare_traps(game, data.get("snare_traps", []))
	restore_ground_items(game, data.get("ground_items", []))
	restore_farm_plots(game, data.get("farm_plots", []), int(data.get("version", 0)))
	restore_chickens(game, data.get("chickens", []), int(data.get("version", 0)))
	game.kills = int(data.get("kills", 0))
	game.hordes_survived = int(data.get("hordes_survived", 0))
	game.objective_system.restore_save_data(data.get("objectives", {}))


func serialize_defenses(game: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in game.get_tree().get_nodes_in_group("defenses"):
		var structure := node as DefenseStructure
		result.append({"type": structure.defense_type, "x": structure.position.x, "y": structure.position.y, "rotation": structure.rotation, "health": structure.health, "upgrade_level": structure.upgrade_level, "max_health": structure.max_health, "spike_damage": structure.spike_damage})
	return result


func restore_defenses(game: Node, entries: Array) -> void:
	_clear_group_immediately(game, "defenses")
	for entry in entries:
		if not entry is Dictionary: continue
		var type := str(entry.get("type", "fence"))
		var definition: Dictionary = game.placement_system.placeable_catalog.get(type, {})
		var scene := definition.get("scene") as PackedScene
		if scene == null: continue
		var structure := scene.instantiate() as DefenseStructure
		structure.position = Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))
		structure.rotation = float(entry.get("rotation", 0.0))
		game.building_layer.add_child(structure)
		structure.setup(type)
		structure.upgrade_level = int(entry.get("upgrade_level", 1))
		structure.max_health = float(entry.get("max_health", structure.max_health))
		structure.spike_damage = float(entry.get("spike_damage", structure.spike_damage))
		structure.health = float(entry.get("health", structure.max_health))
		structure.queue_redraw()


func serialize_storage_chests(game: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in game.get_tree().get_nodes_in_group("storage_chests"): result.append((node as StorageChest).create_save_data())
	return result


func restore_storage_chests(game: Node, entries: Array) -> void:
	_clear_group_immediately(game, "storage_chests")
	var scene := _get_placeable_scene(game, "storage_chest")
	if scene == null: return
	for entry in entries:
		if not entry is Dictionary: continue
		var chest := scene.instantiate() as StorageChest
		chest.position = Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))
		chest.rotation = float(entry.get("rotation", 0.0))
		game.building_layer.add_child(chest)
		chest.restore_items(entry.get("items", {}))


func serialize_snare_traps(game: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in game.get_tree().get_nodes_in_group("snare_traps"): result.append((node as SnareTrap).create_save_data())
	return result


func restore_snare_traps(game: Node, entries: Array) -> void:
	_clear_group_immediately(game, "snare_traps")
	var scene := _get_placeable_scene(game, "snare_trap")
	if scene == null: return
	for entry in entries:
		if not entry is Dictionary: continue
		var trap := scene.instantiate() as SnareTrap
		trap.position = Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))
		trap.rotation = float(entry.get("rotation", 0.0))
		trap.charges = int(entry.get("charges", SnareTrap.MAX_CHARGES))
		game.building_layer.add_child(trap)


func serialize_farm_plots(game: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in game.get_tree().get_nodes_in_group("farm_plots"): result.append((node as FarmPlot).create_save_data())
	return result


func restore_farm_plots(game: Node, entries: Array, save_version := 19) -> void:
	var plots := game.get_tree().get_nodes_in_group("farm_plots")
	if save_version >= 19:
		var plots_by_cell: Dictionary = {}
		for plot_node in plots:
			var plot := plot_node as FarmPlot
			plots_by_cell[WorldGrid.world_to_cell(plot.global_position)] = plot
		for entry in entries:
			if not entry is Dictionary: continue
			var cell := Vector2i(int(entry.get("cell_x", 0)), int(entry.get("cell_y", 0)))
			var target := plots_by_cell.get(cell) as FarmPlot
			if target != null: target.restore_save_data(entry, game.farming_system)
		return
	for index in mini(entries.size(), plots.size()):
		if entries[index] is Dictionary: (plots[index] as FarmPlot).restore_save_data(entries[index], game.farming_system)


func serialize_ground_items(game: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in game.get_tree().get_nodes_in_group("ground_items"): result.append((node as GroundItem).create_save_data())
	return result


func restore_ground_items(game: Node, entries: Array) -> void:
	_clear_group_immediately(game, "ground_items")
	for entry in entries:
		if entry is Dictionary: game._spawn_ground_item(str(entry.get("item_id", "wood")), int(entry.get("amount", 1)), Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0))))


func serialize_chickens(game: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in game.get_tree().get_nodes_in_group("chickens"): result.append((node as Chicken).create_save_data())
	return result


func restore_chickens(game: Node, entries: Array, save_version := 19) -> void:
	var chickens := game.get_tree().get_nodes_in_group("chickens")
	if save_version >= 19:
		var chickens_by_id: Dictionary = {}
		for chicken_node in chickens:
			var chicken := chicken_node as Chicken
			chickens_by_id[chicken.get_persistence_id()] = chicken
		for entry in entries:
			if not entry is Dictionary: continue
			var target := chickens_by_id.get(str(entry.get("persistence_id", ""))) as Chicken
			if target != null: target.restore_save_data(entry)
		return
	for index in mini(entries.size(), chickens.size()):
		if entries[index] is Dictionary: (chickens[index] as Chicken).restore_save_data(entries[index])


func _clear_group_immediately(game: Node, group_name: StringName) -> void:
	for node in game.get_tree().get_nodes_in_group(group_name):
		var parent := node.get_parent()
		if parent != null: parent.remove_child(node)
		node.queue_free()


func _get_placeable_scene(game: Node, placement_type: String) -> PackedScene:
	var definition: Dictionary = game.placement_system.placeable_catalog.get(placement_type, {})
	return definition.get("scene") as PackedScene
