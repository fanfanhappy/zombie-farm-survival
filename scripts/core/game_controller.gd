extends Node2D

const DEFAULT_GAME_RULES := preload("res://resources/settings/game_rules.tres")
const GROUND_ITEM_SCENE := preload("res://scenes/world/items/ground_item.tscn")
const ZOMBIE_SCENE := preload("res://scenes/actors/zombies/zombie.tscn")
const DEFAULT_ENEMY_DATABASE := preload("res://resources/enemies/enemy_database.tres")
const CRAFTING_RECIPE_ENTRY_SCENE := preload("res://scenes/ui/components/crafting_recipe_entry.tscn")

@export var enemy_database: EnemyDatabase = DEFAULT_ENEMY_DATABASE
@export var game_rules: Resource = DEFAULT_GAME_RULES

@onready var player: Player = $GameWorld/DynamicYSortGroup/Player
@onready var darkness: CanvasModulate = $GameWorld/WorldLighting
@onready var status_hud: CharacterStatusHUD = $UI/HUD/StatusPanel
@onready var prompt_label: Label = $UI/HUD/Prompt
@onready var message_label: Label = $UI/HUD/Message
@onready var crafting_system: CraftingSystem = $GameSession/CraftingSystem
@onready var crafting_panel: PanelContainer = $UI/Menus/CraftingPanel
@onready var crafting_title: Label = $UI/Menus/CraftingPanel/Margin/Content/Title
@onready var recipe_list: VBoxContainer = $UI/Menus/CraftingPanel/Margin/Content/RecipeList
@onready var inventory: InventorySystem = $GameSession/InventorySystem
@onready var inventory_ui: InventoryUI = $UI/InventoryUI
@onready var storage_ui: StorageUI = $UI/Menus/StorageUI
@onready var placement_system: PlacementSystem = $GameSession/PlacementSystem
@onready var defense_upgrade_system: DefenseUpgradeSystem = $GameSession/DefenseUpgradeSystem
@onready var horde_system: HordeSystem = $GameSession/HordeSpawner
@onready var horde_label: Label = $UI/HUD/HordeStatus
@onready var farming_system: FarmingSystem = $GameSession/FarmingSystem
@onready var objective_system: ObjectiveSystem = $GameSession/ObjectiveSystem
@onready var objective_label: Label = $UI/HUD/ObjectiveStatus
@onready var weather_system: WeatherSystem = $GameSession/WeatherController
@onready var day_cycle_system: DayCycleSystem = $GameSession/DayCycleSystem
@onready var weather_label: Label = $UI/HUD/WeatherStatus
@onready var pause_overlay: ColorRect = $UI/Menus/PauseOverlay
@onready var pause_panel: PanelContainer = $UI/Menus/PauseOverlay/PausePanel
@onready var settings_ui: SettingsUI = $UI/Menus/SettingsUI
@onready var world_tile_map: WorldTileMap = $GameWorld/TerrainLayers/WorldTileMap
@onready var building_layer: Node2D = $GameWorld/DynamicYSortGroup/BuildingLayer
@onready var farm_plots_root: Node2D = $GameWorld/DynamicYSortGroup/FarmPlots
@onready var facilities_root: Node2D = $GameWorld/DynamicYSortGroup/Facilities
@onready var animals_root: Node2D = $GameWorld/DynamicYSortGroup/Animals
@onready var enemies_root: Node2D = $GameWorld/DynamicYSortGroup/Enemies
@onready var ground_items_root: Node2D = $GameWorld/DynamicYSortGroup/GroundItems

var starting_items: Dictionary = {}
var player_home := Vector2.ZERO
var day_length_seconds := 90.0
var day_start_progress := 7.0 / 24.0
var watering_can_capacity := 5
var day := 1
var day_progress := 7.0 / 24.0
var last_hour := -1
var night_spawned := false
var message_time := 0.0
var kills := 0
var homestead: HomesteadCore
var hordes_survived := 0
var mouse_action_held := false
var mouse_action_cooldown := 0.0
var watering_can_water := 5
var persistence := GamePersistence.new()
var targeting := WorldTargetingService.new()
var item_use_system := ItemUseSystem.new()


func _ready() -> void:
	_apply_game_rules()
	inventory.initialize(starting_items)
	inventory_ui.setup(inventory)
	storage_ui.setup(inventory)
	farming_system.setup(world_tile_map, farm_plots_root)
	storage_ui.storage_closed.connect(_on_storage_closed)
	inventory_ui.item_use_requested.connect(_on_inventory_item_use_requested)
	inventory_ui.item_drop_requested.connect(_on_inventory_item_drop_requested)
	inventory_ui.inventory_closed.connect(_on_inventory_closed)
	placement_system.setup(self, building_layer, inventory)
	horde_system.zombie_spawn_requested.connect(_spawn_zombie)
	horde_system.horde_started.connect(_on_horde_started)
	horde_system.wave_started.connect(_on_horde_wave_started)
	horde_system.horde_completed.connect(_on_horde_completed)
	objective_system.setup(self)
	objective_system.objective_text_changed.connect(_on_objective_text_changed)
	objective_system.objective_completed.connect(_on_objective_completed)
	weather_system.weather_changed.connect(_on_weather_changed)
	weather_system.choose_weather_for_day(day)
	player.interaction_requested.connect(_on_interaction_requested)
	player.attack_requested.connect(_on_attack_requested)
	player.health_changed.connect(_update_hud.unbind(2))
	player.stamina_changed.connect(_update_hud.unbind(2))
	player.hunger_changed.connect(_update_hud.unbind(2))
	player.thirst_changed.connect(_update_hud.unbind(2))
	player.level_changed.connect(_update_hud.unbind(3))
	player.action_failed.connect(show_message)
	player.died.connect(_on_player_died)
	_create_world_collisions()
	$UI/Menus/CraftingPanel/Margin/Content/Close.pressed.connect(close_crafting)
	$UI/Menus/PauseOverlay/PausePanel/Margin/Buttons/Resume.pressed.connect(_set_paused.bind(false))
	$UI/Menus/PauseOverlay/PausePanel/Margin/Buttons/Save.pressed.connect(save_game)
	$UI/Menus/PauseOverlay/PausePanel/Margin/Buttons/Load.pressed.connect(load_game)
	$UI/Menus/PauseOverlay/PausePanel/Margin/Buttons/Settings.pressed.connect(_open_settings)
	$UI/Menus/PauseOverlay/PausePanel/Margin/Buttons/Quit.pressed.connect(get_tree().quit)
	settings_ui.closed.connect(_on_settings_closed)
	_update_hud()
	var start_mode := SaveSystem.consume_start_mode()
	if start_mode == "continue": load_game()
	else: reset_for_new_game()


func reset_for_new_game() -> void:
	day = 1
	day_progress = day_start_progress
	last_hour = -1
	night_spawned = false
	kills = 0
	hordes_survived = 0
	horde_system.cancel_horde()
	for zombie in get_tree().get_nodes_in_group("zombies"): zombie.queue_free()
	for defense in get_tree().get_nodes_in_group("defenses"): defense.queue_free()
	for chest in get_tree().get_nodes_in_group("storage_chests"): chest.queue_free()
	for trap in get_tree().get_nodes_in_group("snare_traps"): trap.queue_free()
	for ground_item in get_tree().get_nodes_in_group("ground_items"): ground_item.queue_free()
	farming_system.reset_for_new_game()
	for chicken in get_tree().get_nodes_in_group("chickens"): (chicken as Chicken).reset_for_new_game()
	inventory.reset_for_new_game(starting_items)
	inventory.assign_hotbar_item(0, "wooden_club")
	inventory.assign_hotbar_item(1, "stone_axe")
	inventory.assign_hotbar_item(2, "stone_hoe")
	inventory.assign_hotbar_item(3, "watering_can")
	inventory_ui.reset_selection()
	watering_can_water = watering_can_capacity
	objective_system.reset_for_new_game()
	player.reset_for_new_game(player_home)
	if is_instance_valid(homestead): homestead.restore_full()
	weather_system.choose_weather_for_day(day)
	inventory_ui.close_backpack()
	storage_ui.close_storage()
	crafting_panel.visible = false
	placement_system.cancel_placement()
	_set_player_control(true)
	_update_hud()
	show_message("新游戏已重置：第一天，从零开始建设家园")


func _process(delta: float) -> void:
	_update_held_mouse_action(delta)
	day_cycle_system.update(self, delta)
	_update_lighting()
	_update_prompt()
	_update_hud()
	if message_time > 0.0:
		message_time -= delta
		if message_time <= 0.0: message_label.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		DisplayManager.toggle_fullscreen()
		get_viewport().set_input_as_handled()
		return
	if pause_overlay.visible:
		if event.is_action_pressed("ui_cancel"):
			if settings_ui.visible: settings_ui.close()
			else: _set_paused(false)
			get_viewport().set_input_as_handled()
		return
	if storage_ui.is_open():
		if event.is_action_pressed("ui_cancel"):
			storage_ui.close_storage(); get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and not inventory_ui.is_backpack_open() and not crafting_panel.visible and not placement_system.is_placing():
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			var direction := -1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1
			if not inventory_ui.cycle_hotbar(direction): show_message("快捷栏中没有可用物品")
			get_viewport().set_input_as_handled()
			return
	var hotbar_index := _get_pressed_hotbar_index(event)
	if hotbar_index >= 0 and not inventory_ui.is_backpack_open() and not crafting_panel.visible:
		if placement_system.is_placing(): placement_system.cancel_placement()
		if not inventory_ui.activate_hotbar_slot(hotbar_index): show_message("快捷槽 %d 是空的" % (hotbar_index + 1))
		get_viewport().set_input_as_handled()
		return
	if placement_system.is_placing():
		if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
			placement_system.cancel_placement(); get_viewport().set_input_as_handled(); return
		if event.is_action_pressed("use_bandage"):
			placement_system.rotate_preview(); get_viewport().set_input_as_handled(); return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not placement_system.try_place(): show_message("这里不能放置")
			get_viewport().set_input_as_handled(); return
		if event.is_action_pressed("toggle_inventory"):
			placement_system.cancel_placement()
	if event.is_action_pressed("toggle_inventory"):
		if crafting_panel.visible: close_crafting()
		inventory_ui.toggle_backpack()
		_set_player_control(not inventory_ui.is_backpack_open())
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and inventory_ui.is_backpack_open():
		inventory_ui.close_backpack()
		get_viewport().set_input_as_handled()
		return
	if inventory_ui.is_backpack_open():
		return
	if event.is_action_pressed("ui_cancel") and crafting_panel.visible:
		close_crafting(); get_viewport().set_input_as_handled(); return
	if crafting_panel.visible:
		get_viewport().set_input_as_handled(); return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_action_held = event.pressed
		if event.pressed:
			mouse_action_cooldown = 0.0
			_try_mouse_world_action(get_global_mouse_position())
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		_set_paused(true); get_viewport().set_input_as_handled(); return
	if event.is_action_pressed("use_bandage"): _use_bandage()
	elif event.is_action_pressed("eat_food"): _eat_meal()
	elif event.is_action_pressed("quick_save"): save_game()
	elif event.is_action_pressed("quick_load"): load_game()
	elif event.is_action_pressed("dismantle_structure"): _try_dismantle_nearest()
	elif event.is_action_pressed("upgrade_structure"): _try_upgrade_nearest()
	elif event.is_action_pressed("debug_time"):
		day_progress += 2.0 / 24.0
		show_message("测试：时间前进2小时")


func add_resource(type: String, amount: int, announce := true) -> int:
	var remaining := inventory.add_item(type, amount)
	var accepted := amount - remaining
	if announce and accepted > 0: show_message("获得 %s × %d" % [_resource_name(type), accepted])
	if remaining > 0:
		# 收获、任务和尸潮奖励都不能因背包已满而静默消失。
		var drop_position := player.global_position + player.facing_direction * 28.0
		_spawn_ground_item(type, remaining, drop_position)
		show_message("背包已满，%s × %d 已掉落在脚边" % [_resource_name(type), remaining])
	return accepted


func get_resource_amount(type: String) -> int:
	return inventory.get_amount(type)


func can_add_resource(type: String, amount: int) -> bool:
	return inventory.can_add_item(type, amount)


func spend_resource(type: String, amount: int) -> bool:
	return inventory.remove_item(type, amount)


func show_message(text: String) -> void:
	message_label.text = text
	message_time = 3.0


func _on_interaction_requested() -> void:
	var target := _nearest_interactable()
	if target and target.has_method("interact"):
		if target.has_method("can_interact") and not target.can_interact(self): return
		var stamina_cost := float(target.get_stamina_cost()) if target.has_method("get_stamina_cost") else 0.0
		if stamina_cost > 0.0 and not player.try_spend_stamina(stamina_cost):
			show_message("体力不足，休息片刻再继续")
			return
		target.interact(self)


func _on_attack_requested() -> void:
	var best_target: Zombie
	var best_distance := 60.0
	for node in get_tree().get_nodes_in_group("zombies"):
		var zombie := node as Zombie
		var offset := zombie.global_position - player.global_position
		var distance := offset.length()
		if distance < best_distance and (distance < 22.0 or offset.normalized().dot(player.facing_direction) > 0.15):
			best_target = zombie; best_distance = distance
	if best_target: best_target.take_damage(player.get_attack_damage(), player)


func _update_held_mouse_action(delta: float) -> void:
	if not mouse_action_held: return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		mouse_action_held = false
		return
	if pause_overlay.visible or storage_ui.is_open() or inventory_ui.is_backpack_open() or crafting_panel.visible or placement_system.is_placing(): return
	mouse_action_cooldown = maxf(mouse_action_cooldown - delta, 0.0)
	if mouse_action_cooldown <= 0.0:
		_try_mouse_world_action(get_global_mouse_position())


func _try_mouse_world_action(mouse_world_position: Vector2) -> void:
	var target := _nearest_mouse_target(mouse_world_position)
	if target:
		var target_reach := 70.0 if target is Zombie else 64.0
		if target is FarmPlot and player.world_settings != null:
			target_reach = float(player.world_settings.farming_reach)
		if player.global_position.distance_to(target.global_position) > target_reach:
			show_message("目标太远，靠近后再操作")
			mouse_action_cooldown = 0.35
			return
		if target is Zombie:
			if player.try_mouse_attack(target.global_position): mouse_action_cooldown = player.attack_cooldown
			else: mouse_action_cooldown = 0.1
			return
		if target.has_method("can_mouse_interact") and not target.can_mouse_interact(self):
			mouse_action_cooldown = 0.55
			return
		if target.has_method("can_interact") and not target.can_interact(self):
			mouse_action_cooldown = 0.55
			return
		var stamina_cost := float(target.get_stamina_cost()) if target.has_method("get_stamina_cost") else 0.0
		if stamina_cost > 0.0 and not player.try_spend_stamina(stamina_cost):
			show_message("体力不足，无法继续操作")
			mouse_action_cooldown = 0.55
			return
		player.facing_direction = player.global_position.direction_to(target.global_position)
		target.interact(self)
		mouse_action_cooldown = player.get_tool_action_duration()
		return
	if get_active_tool_type() == "hoe":
		var cell := world_tile_map.world_to_farm_cell(mouse_world_position)
		var cell_position := world_tile_map.farm_cell_to_world(cell)
		var block_reason := world_tile_map.get_till_block_reason(cell)
		if not block_reason.is_empty():
			show_message(block_reason)
			mouse_action_cooldown = 0.35
			return
		if player.global_position.distance_to(cell_position) > float(player.world_settings.farming_reach):
			show_message("目标太远，靠近后再开垦")
			mouse_action_cooldown = 0.35
			return
		var new_plot := farming_system.create_plot_at_cell(cell)
		if new_plot == null:
			show_message("这里暂时不能开垦")
			mouse_action_cooldown = 0.35
			return
		var stamina_cost := new_plot.get_stamina_cost()
		if stamina_cost > 0.0 and not player.try_spend_stamina(stamina_cost):
			farming_system.discard_new_plot(new_plot)
			show_message("体力不足，无法开垦")
			mouse_action_cooldown = 0.55
			return
		player.facing_direction = player.global_position.direction_to(cell_position)
		new_plot.interact(self)
		mouse_action_cooldown = player.get_tool_action_duration()
		return
	if player.global_position.distance_to(mouse_world_position) > 78.0:
		show_message("目标太远")
		mouse_action_cooldown = 0.35
		return
	if player.try_mouse_attack(mouse_world_position): mouse_action_cooldown = player.attack_cooldown
	else: mouse_action_cooldown = 0.1


func _nearest_mouse_target(mouse_world_position: Vector2) -> Node2D:
	return targeting.find_mouse_target(self, mouse_world_position)


func _on_player_died() -> void:
	show_message("你倒下了。清晨醒来时，部分物资遗失了。")
	if inventory.has_item("potato"): inventory.remove_item("potato", 1)
	for zombie in get_tree().get_nodes_in_group("zombies"): zombie.queue_free()
	player.revive(player_home)
	day_progress = day_start_progress


func _nearest_interactable() -> Node:
	return targeting.find_nearest_interactable(self)


func _update_prompt() -> void:
	if placement_system.is_placing():
		prompt_label.text = "左键放置　R旋转　右键/Esc取消"
		return
	var mouse_target := _nearest_mouse_target(get_global_mouse_position())
	if mouse_target is Zombie:
		prompt_label.text = "左键/长按攻击感染者"
		return
	if mouse_target and mouse_target.has_method("get_interaction_prompt"):
		prompt_label.text = mouse_target.get_interaction_prompt()
		return
	var target := _nearest_interactable()
	if target:
		prompt_label.text = target.get_interaction_prompt()
	elif is_instance_valid(world_tile_map):
		prompt_label.text = world_tile_map.get_cursor_hint()
	else:
		prompt_label.text = ""


func get_selected_hotbar_item_id() -> String:
	return inventory_ui.get_selected_hotbar_item_id()


func get_active_tool_type() -> String:
	var active_item_id := get_selected_hotbar_item_id()
	if not active_item_id.is_empty():
		var active_data := inventory.get_item_data(active_item_id)
		if active_data.has("tool_type"): return str(active_data["tool_type"])
	var weapon_data := inventory.get_item_data(player.equipped_weapon_id)
	return str(weapon_data.get("tool_type", ""))


func get_objective_metric(type: String, target: String) -> int:
	match type:
		"inventory": return inventory.get_amount(target)
		"tilled_plots":
			var count := 0
			for plot in get_tree().get_nodes_in_group("farm_plots"):
				if (plot as FarmPlot).state != FarmPlot.PlotState.EMPTY: count += 1
			return count
		"planted_plots":
			var count := 0
			for plot in get_tree().get_nodes_in_group("farm_plots"):
				if (plot as FarmPlot).state in [FarmPlot.PlotState.PLANTED, FarmPlot.PlotState.GROWING, FarmPlot.PlotState.READY]: count += 1
			return count
		"defenses": return get_tree().get_nodes_in_group("defenses").size()
		"kills": return kills
		"hordes_survived": return hordes_survived
	return 0


func _spawn_night_threat() -> void:
	if day % 7 == 0:
		horde_system.start_horde()
		return
	var count := 3 + mini(day, 5)
	show_message("天黑了，附近出现了感染者")
	for index in count:
		var enemy_id: StringName = &"fast_infected" if index % 5 == 4 else &"normal_infected"
		get_tree().create_timer(index * 0.4).timeout.connect(_spawn_zombie.bind(enemy_id))


func _spawn_zombie(enemy_kind: Variant = &"normal_infected", saved_position := Vector2.INF, saved_health := -1.0) -> void:
	var enemy_id := StringName("fast_infected" if enemy_kind is bool and enemy_kind else "normal_infected" if enemy_kind is bool else str(enemy_kind))
	var enemy_definition := enemy_database.get_definition(enemy_id)
	if enemy_definition == null:
		push_error("找不到敌人配置：%s" % enemy_id)
		return
	var zombie := ZOMBIE_SCENE.instantiate() as Zombie
	if saved_position.is_finite():
		zombie.position = saved_position
	else:
		var bounds: Rect2 = player.world_settings.get_player_bounds()
		match randi() % 4:
			0: zombie.position = Vector2(randf_range(bounds.position.x, bounds.end.x), bounds.position.y)
			1: zombie.position = Vector2(randf_range(bounds.position.x, bounds.end.x), bounds.end.y)
			2: zombie.position = Vector2(bounds.position.x, randf_range(bounds.position.y, bounds.end.y))
			_: zombie.position = Vector2(bounds.end.x, randf_range(bounds.position.y, bounds.end.y))
	enemies_root.add_child(zombie); zombie.setup(player, homestead, enemy_definition)
	if saved_health >= 0.0:
		zombie.health = clampf(saved_health, 0.1, zombie.max_health)
		zombie.health_bar.value = zombie.health
		zombie.health_bar.visible = zombie.health < zombie.max_health
	zombie.defeated.connect(_on_zombie_defeated)


func _on_zombie_defeated(_zombie: Zombie) -> void:
	kills += 1
	horde_system.notify_zombie_defeated()
	var experience_reward := _zombie.experience_reward
	var drop_data: Dictionary = _zombie.definition.roll_drop() if _zombie.definition != null else {}
	if not drop_data.is_empty():
		_spawn_ground_item(str(drop_data.get("item_id", "")), int(drop_data.get("amount", 1)), _zombie.global_position)
	var leveled_up := player.add_experience(experience_reward)
	if leveled_up:
		show_message("升级！达到%d级，生命、体力和伤害提升" % player.level)
		return
	if not drop_data.is_empty():
		show_message("击败感染者：经验+%d，战利品已掉落" % experience_reward)
	else: show_message("击败感染者：经验+%d" % experience_reward)


func _create_world_collisions() -> void:
	homestead = building_layer.get_node("Homestead") as HomesteadCore
	homestead.setup(Vector2(300, 220))
	homestead.destroyed.connect(_on_homestead_destroyed)
	var repair_point := facilities_root.get_node("HomesteadRepairPoint") as HomesteadRepairPoint
	repair_point.setup(homestead)

func _update_lighting() -> void:
	var hour := day_progress * 24.0
	var night_color := Color(0.48, 0.54, 0.68, 1.0)
	var dawn_color := Color(0.82, 0.78, 0.72, 1.0)
	if hour < 5.0:
		darkness.color = night_color
	elif hour < 7.0:
		darkness.color = dawn_color.lerp(Color.WHITE, (hour - 5.0) / 2.0)
	elif hour <= 19.0:
		darkness.color = Color.WHITE
	else:
		darkness.color = Color.WHITE.lerp(night_color, minf((hour - 19.0) / 2.5, 1.0))


func _update_hud() -> void:
	if not is_instance_valid(player): return
	status_hud.update_from_game(self)
	if horde_system.active:
		horde_label.text = horde_system.get_status_text()
	else:
		var days_until_horde := 7 - (((day - 1) % 7) + 1)
		horde_label.text = "今晚将有尸潮" if days_until_horde == 0 else "距离尸潮：%d天" % days_until_horde


func format_cost(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for type in cost: parts.append("%s×%d" % [_resource_name(type), cost[type]])
	return " ".join(parts)


func _resource_name(type: String) -> String:
	return inventory.get_display_name(type) if is_instance_valid(inventory) else type


func open_crafting(station_type: String, display_name: String) -> void:
	if inventory_ui.is_backpack_open(): inventory_ui.close_backpack()
	crafting_title.text = display_name
	for child in recipe_list.get_children(): child.queue_free()
	for recipe in crafting_system.get_recipes_for_station(station_type):
		var entry := CRAFTING_RECIPE_ENTRY_SCENE.instantiate() as CraftingRecipeEntry
		entry.configure(str(recipe["id"]), crafting_system.format_recipe(recipe, self))
		entry.craft_requested.connect(_craft_recipe)
		recipe_list.add_child(entry)
	crafting_panel.visible = true
	_set_player_control(false)


func close_crafting() -> void:
	crafting_panel.visible = false
	_set_player_control(true)


func _craft_recipe(recipe_id: String) -> void:
	if crafting_system.craft(recipe_id, self):
		_update_hud()
		for child in recipe_list.get_children():
			if child is Button:
				var recipe: Dictionary = crafting_system.recipes.get(recipe_id, {})
				if child.text.begins_with(recipe.get("name", "")): child.text = crafting_system.format_recipe(recipe, self)


func apply_recipe_effect(effect: Dictionary) -> void:
	item_use_system.apply_recipe_effect(self, effect)


func _use_bandage() -> void:
	item_use_system.use_consumable(self, "bandage")


func _eat_meal() -> void:
	item_use_system.use_consumable(self, "meal")


func _eat_potato() -> void:
	item_use_system.use_consumable(self, "potato")


func save_game() -> void:
	if horde_system.active:
		show_message("尸潮期间不能保存")
		return
	show_message("游戏已保存" if SaveSystem.save_game(persistence.create_save_data(self)) else "保存失败")


func load_game() -> void:
	var data := SaveSystem.load_game()
	if data.is_empty():
		show_message("没有找到存档")
		return
	persistence.restore_save_data(self, data)
	inventory_ui.reset_selection()
	_update_hud()
	show_message("存档已读取")


func _on_inventory_item_use_requested(item_id: String) -> void:
	item_use_system.handle_item_use(self, item_id)
	inventory_ui.refresh()


func _on_inventory_closed() -> void:
	_set_player_control(true)


func open_storage(chest: StorageChest) -> void:
	if inventory_ui.is_backpack_open(): inventory_ui.close_backpack()
	if crafting_panel.visible: close_crafting()
	storage_ui.open_storage(chest)
	_set_player_control(false)


func _on_storage_closed() -> void:
	_set_player_control(true)


func _on_inventory_item_drop_requested(item_id: String) -> void:
	if item_id == player.equipped_weapon_id:
		show_message("正在装备的武器不能丢弃，请先装备另一把武器")
		return
	if not inventory.remove_item(item_id, 1): return
	_spawn_ground_item(item_id, 1, player.global_position + player.facing_direction * 34.0)
	show_message("丢弃了%s ×1" % inventory.get_display_name(item_id))


func _spawn_ground_item(item_id: String, amount: int, at_position: Vector2) -> void:
	var ground_item := GROUND_ITEM_SCENE.instantiate() as GroundItem
	ground_item.position = at_position
	ground_items_root.add_child(ground_item)
	var item_data: Dictionary = inventory.get_item_data(item_id)
	ground_item.setup(item_id, amount, inventory.get_display_name(item_id), item_data.get("icon") as Texture2D)


func _try_dismantle_nearest() -> void:
	var nearest := _get_nearest_defense()
	if nearest: nearest.try_dismantle(self)
	else: show_message("附近没有可拆除的防御设施")


func _try_upgrade_nearest() -> void:
	var nearest := _get_nearest_defense()
	if nearest: defense_upgrade_system.try_upgrade(nearest, self)
	else: show_message("附近没有可升级的防御设施")


func _get_nearest_defense() -> DefenseStructure:
	return targeting.find_nearest_defense(self)


func _set_player_control(enabled: bool) -> void:
	player.set_physics_process(enabled)
	player.set_process_unhandled_input(enabled)


func _set_paused(paused: bool) -> void:
	pause_overlay.visible = paused
	pause_panel.visible = true
	settings_ui.visible = false
	Engine.time_scale = 0.0 if paused else 1.0
	_set_player_control(not paused)
	if paused: $UI/Menus/PauseOverlay/PausePanel/Margin/Buttons/Resume.grab_focus()


func _open_settings() -> void:
	pause_panel.visible = false
	settings_ui.open()


func _on_settings_closed() -> void:
	if pause_overlay.visible:
		pause_panel.visible = true
		$UI/Menus/PauseOverlay/PausePanel/Margin/Buttons/Settings.grab_focus()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _on_homestead_destroyed() -> void:
	show_message("农舍被攻破了。清晨，你修复了最基本的结构。")
	horde_system.cancel_horde()
	for zombie in get_tree().get_nodes_in_group("zombies"): zombie.queue_free()
	homestead.restore_full()
	day += 1
	day_progress = day_start_progress
	night_spawned = false


func _on_horde_started(_total_waves: int) -> void:
	show_message("警告：尸潮来袭！守住农舍！")


func _on_horde_wave_started(wave_number: int, total_waves: int) -> void:
	show_message("尸潮第%d/%d波开始" % [wave_number, total_waves])


func _on_horde_completed() -> void:
	hordes_survived += 1
	for item_id in horde_system.reward:
		add_resource(item_id, int(horde_system.reward[item_id]), false)
	show_message("天亮了，家还在。获得尸潮奖励：%s" % format_cost(horde_system.reward))
	day_progress = 0.99


func try_sleep() -> void:
	day_cycle_system.try_sleep(self)


func drink_from_water_pump() -> void:
	day_cycle_system.drink_from_water_pump(self)


func refill_watering_can() -> void:
	day_cycle_system.refill_watering_can(self)


func can_water_crop() -> bool:
	return day_cycle_system.can_water_crop(self)


func use_watering_can() -> void:
	watering_can_water = maxi(watering_can_water - 1, 0)


func _advance_to_next_day() -> void:
	day_cycle_system.advance_to_next_day(self)


func _apply_game_rules() -> void:
	if game_rules == null:
		push_error("Main 未配置 GameRulesDefinition")
		return
	starting_items = game_rules.get_starting_items()
	player_home = game_rules.player_home
	day_length_seconds = game_rules.day_length_seconds
	day_start_progress = game_rules.get_day_start_progress()
	watering_can_capacity = game_rules.watering_can_capacity
	day_progress = day_start_progress
	watering_can_water = watering_can_capacity


func _on_objective_text_changed(text: String) -> void:
	objective_label.text = text


func _on_objective_completed(title: String, reward_text: String) -> void:
	show_message("目标完成：%s　奖励：%s" % [title, reward_text])


func _on_weather_changed(_weather_id: String, weather_data: Dictionary) -> void:
	player.environment_thirst_multiplier = float(weather_data.get("thirst_multiplier", 1.0))
	weather_label.text = "天气：%s" % weather_data.get("name", "晴朗")


func _get_pressed_hotbar_index(event: InputEvent) -> int:
	for index in inventory.hotbar_capacity:
		if event.is_action_pressed("hotbar_slot_%d" % (index + 1)):
			return index
	return -1
