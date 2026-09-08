extends SceneTree


func _init() -> void:
	var item_database := load("res://resources/items/item_database.tres") as ItemDatabase
	var item_catalog := item_database.build_catalog()
	assert(item_catalog.size() == 22)
	for item_id in item_catalog:
		assert(not str(item_id).is_empty())
		assert((item_catalog[item_id] as Dictionary).get("icon") is Texture2D)

	var recipe_catalog := (load("res://resources/recipes/recipe_database.tres") as RecipeDatabase).build_catalog()
	assert(recipe_catalog.size() == 11)
	for recipe in recipe_catalog.values():
		for item_id in (recipe as Dictionary).get("ingredients", {}): assert(item_catalog.has(item_id))
		for item_id in (recipe as Dictionary).get("results", {}): assert(item_catalog.has(item_id))

	var crop_catalog := (load("res://resources/crops/crop_database.tres") as CropDatabase).build_catalog()
	assert(crop_catalog.size() == 3)
	for crop in crop_catalog.values():
		var data := crop as Dictionary
		assert(item_catalog.has(data.get("seed_item")))
		assert(data.get("visual_scene") is PackedScene)
		for item_id in data.get("harvest", {}): assert(item_catalog.has(item_id))

	var placement_catalog := (load("res://resources/placements/placeable_database.tres") as PlaceableDatabase).build_catalog()
	assert(placement_catalog.size() == 4)
	for definition in placement_catalog.values(): assert((definition as Dictionary).get("scene") is PackedScene)

	var weather_catalog := (load("res://resources/weather/weather_database.tres") as WeatherDatabase).build_catalog()
	assert(weather_catalog.size() == 3)
	var total_weather_weight := 0
	for weather in weather_catalog.values(): total_weather_weight += int((weather as Dictionary).get("weight", 0))
	assert(total_weather_weight > 0)

	var objectives := (load("res://resources/objectives/objective_database.tres") as ObjectiveDatabase).build_list()
	assert(objectives.size() == 7)
	for objective in objectives:
		for item_id in (objective as Dictionary).get("reward", {}): assert(item_catalog.has(item_id))

	var horde := load("res://resources/hordes/first_horde.tres") as HordeDefinition
	assert(horde.waves.size() == 3)
	for reward_entry in horde.reward:
		assert(reward_entry is ItemAmount)
		assert(item_catalog.has(String((reward_entry as ItemAmount).item_id)))
	var enemy_database := load("res://resources/enemies/enemy_database.tres") as EnemyDatabase
	assert(enemy_database.enemies.size() == 2)
	for enemy in enemy_database.enemies:
		assert(enemy != null)
		assert(not enemy.enemy_id.is_empty())
		assert(enemy.max_health > 0.0)
		assert(enemy.move_speed > 0.0)
		if not enemy.drop_item_id.is_empty(): assert(item_catalog.has(String(enemy.drop_item_id)))
	for wave in horde.waves:
		assert(wave is HordeWaveDefinition)
		for enemy_entry in (wave as HordeWaveDefinition).enemies:
			assert(enemy_database.has_definition((enemy_entry as EnemySpawnEntry).enemy_id))

	var upgrades := (load("res://resources/defense_upgrades/defense_upgrade_database.tres") as DefenseUpgradeDatabase).build_catalog()
	assert(upgrades.size() == 2)
	print("RESOURCE_DATABASE_INTEGRITY_OK")
	quit()
