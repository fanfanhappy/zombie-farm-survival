extends Node2D

const PLAYER_HOME := Vector2(640, 460)
const DAY_LENGTH_SECONDS := 90.0
const DAY_START_PROGRESS := 7.0 / 24.0
const WATERING_CAN_CAPACITY := 5
const GROUND_ITEM_SCENE := preload("res://scenes/world/items/ground_item.tscn")
const ZOMBIE_SCENE := preload("res://scenes/actors/zombies/zombie.tscn")
const DEFAULT_ENEMY_DATABASE := preload("res://resources/enemies/enemy_database.tres")

@export var enemy_database: EnemyDatabase = DEFAULT_ENEMY_DATABASE

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

const STARTING_ITEMS := {"wooden_club": 1, "stone_axe": 1, "stone_hoe": 1, "watering_can": 1, "wood_fence": 3, "wood_spike": 2, "storage_chest": 1, "snare_trap": 1, "wood": 8, "stone": 4, "herb": 2, "potato": 2, "potato_seed": 4, "carrot_seed": 3, "herb_seed": 2}
var day := 1
var day_progress := DAY_START_PROGRESS
var last_hour := -1
var night_spawned := false
var message_time := 0.0
var kills := 0
var homestead: HomesteadCore
var hordes_survived := 0
var mouse_action_held := false
var mouse_action_cooldown := 0.0
var watering_can_water := WATERING_CAN_CAPACITY
var persistence := GamePersistence.new()
var targeting := WorldTargetingService.new()


func _ready() -> void:
	inventory.initialize(STARTING_ITEMS)
	inventory_ui.setup(inventory)
	storage_ui.setup(inventory)
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
	day_progress = DAY_START_PROGRESS
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
	for plot in get_tree().get_nodes_in_group("farm_plots"): (plot as FarmPlot).reset_for_new_game()
	for chicken in get_tree().get_nodes_in_group("chickens"): (chicken as Chicken).reset_for_new_game()
	inventory.reset_for_new_game(STARTING_ITEMS)
	inventory.assign_hotbar_item(0, "wooden_club")
	inventory.assign_hotbar_item(1, "stone_axe")
	inventory.assign_hotbar_item(2, "stone_hoe")
	inventory.assign_hotbar_item(3, "watering_can")
	watering_can_water = WATERING_CAN_CAPACITY
	objective_system.reset_for_new_game()
	player.reset_for_new_game(PLAYER_HOME)
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
	if not (horde_system.active and day_progress >= 0.98):
		day_progress += delta / DAY_LENGTH_SECONDS
	if day_progress >= 1.0:
		_advance_to_next_day()
	var hour := int(day_progress * 24.0)
	if hour != last_hour:
		last_hour = hour
		if hour >= 18 and not night_spawned:
			night_spawned = true
			_spawn_night_threat()
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
	if player.global_position.distance_to(mouse_world_position) > 78.0:
		show_message("目标太远")
		mouse_action_cooldown = 0.35
		return
	var target := _nearest_mouse_target(mouse_world_position)
	if target:
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
	if player.try_mouse_attack(mouse_world_position): mouse_action_cooldown = player.attack_cooldown
	else: mouse_action_cooldown = 0.1


func _nearest_mouse_target(mouse_world_position: Vector2) -> Node2D:
	return targeting.find_mouse_target(self, mouse_world_position)


func _on_player_died() -> void:
	show_message("你倒下了。清晨醒来时，部分物资遗失了。")
	if inventory.has_item("potato"): inventory.remove_item("potato", 1)
	for zombie in get_tree().get_nodes_in_group("zombies"): zombie.queue_free()
	player.revive(PLAYER_HOME)
	day_progress = DAY_START_PROGRESS


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


func _spawn_zombie(enemy_kind: Variant = &"normal_infected") -> void:
	var enemy_id := StringName("fast_infected" if enemy_kind is bool and enemy_kind else "normal_infected" if enemy_kind is bool else str(enemy_kind))
	var enemy_definition := enemy_database.get_definition(enemy_id)
	if enemy_definition == null:
		push_error("找不到敌人配置：%s" % enemy_id)
		return
	var zombie := ZOMBIE_SCENE.instantiate() as Zombie
	match randi() % 4:
		0: zombie.position = Vector2(randf_range(40, 1240), 40)
		1: zombie.position = Vector2(randf_range(40, 1240), 760)
		2: zombie.position = Vector2(40, randf_range(40, 760))
		_: zombie.position = Vector2(1240, randf_range(40, 760))
	enemies_root.add_child(zombie); zombie.setup(player, homestead, enemy_definition)
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
		var button := Button.new()
		button.text = crafting_system.format_recipe(recipe, self)
		button.custom_minimum_size.y = 42.0
		button.pressed.connect(_craft_recipe.bind(recipe["id"]))
		recipe_list.add_child(button)
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
	if effect.has("equip_weapon"):
		var item_id := str(effect["equip_weapon"])
		var item_data := inventory.get_item_data(item_id)
		player.equip_weapon(item_id, item_data.get("name", item_id), float(effect.get("attack_damage", item_data.get("attack_damage", 25.0))))


func _use_bandage() -> void:
	if player.health >= player.max_health: show_message("生命值已经满了"); return
	if not spend_resource("bandage", 1): show_message("没有绷带"); return
	player.heal(35.0); show_message("使用绷带，恢复35点生命")


func _eat_meal() -> void:
	if not spend_resource("meal", 1): show_message("没有炖菜"); return
	player.heal(20.0); player.restore_stamina(45.0); player.restore_hunger(60.0); player.apply_well_fed(60.0)
	show_message("吃下炖菜：饥饿+60，60秒内攻击+20%、体力恢复+35%")


func _eat_potato() -> void:
	if player.hunger >= player.max_hunger: show_message("现在还不饿"); return
	if not spend_resource("potato", 1): show_message("没有土豆"); return
	player.restore_hunger(18.0)
	show_message("吃下土豆，恢复18点饥饿")


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
	_update_hud()
	show_message("存档已读取")


func _serialize_defenses() -> Array[Dictionary]:
	return persistence.serialize_defenses(self)


func _restore_defenses(entries: Array) -> void:
	persistence.restore_defenses(self, entries)


func _serialize_storage_chests() -> Array[Dictionary]:
	return persistence.serialize_storage_chests(self)


func _restore_storage_chests(entries: Array) -> void:
	persistence.restore_storage_chests(self, entries)


func _serialize_snare_traps() -> Array[Dictionary]:
	return persistence.serialize_snare_traps(self)


func _restore_snare_traps(entries: Array) -> void:
	persistence.restore_snare_traps(self, entries)


func _serialize_farm_plots() -> Array[Dictionary]:
	return persistence.serialize_farm_plots(self)


func _serialize_ground_items() -> Array[Dictionary]:
	return persistence.serialize_ground_items(self)


func _serialize_chickens() -> Array[Dictionary]:
	return persistence.serialize_chickens(self)


func _restore_chickens(entries: Array) -> void:
	persistence.restore_chickens(self, entries)


func _restore_ground_items(entries: Array) -> void:
	persistence.restore_ground_items(self, entries)


func _restore_farm_plots(entries: Array) -> void:
	persistence.restore_farm_plots(self, entries)


func _on_inventory_item_use_requested(item_id: String) -> void:
	var item_data := inventory.get_item_data(item_id)
	if item_data.get("category", "") == "placeable":
		if inventory_ui.is_backpack_open(): inventory_ui.close_backpack()
		placement_system.begin_placement(item_id)
	elif item_data.get("category", "") == "weapon":
		player.equip_weapon(item_id, item_data.get("name", item_id), float(item_data.get("attack_damage", 25.0)))
		show_message("已装备：%s" % item_data.get("name", item_id))
	elif item_data.get("category", "") == "seed":
		show_message("已选中：%s，靠近开垦后的农田按E播种" % item_data.get("name", item_id))
	elif item_data.get("category", "") == "tool":
		if get_selected_hotbar_item_id() == item_id:
			show_message("已选中工具：%s" % item_data.get("name", item_id))
		else:
			show_message("请先把%s拖入快捷栏" % item_data.get("name", item_id))
	else:
		match item_id:
			"bandage": _use_bandage()
			"meal": _eat_meal()
			"potato": _eat_potato()
			_: show_message("这个物品目前不能直接使用")
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
	day_progress = DAY_START_PROGRESS
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
	var hour := day_progress * 24.0
	if horde_system.active:
		show_message("尸潮还没有结束，现在不能睡觉")
		return
	if not get_tree().get_nodes_in_group("zombies").is_empty():
		show_message("附近还有感染者，无法安心休息")
		return
	if hour < 18.0:
		show_message("现在还太早，18:00以后可以休息")
		return
	if player.hunger < 18.0:
		show_message("太饿了，至少需要18点饥饿才能休息")
		return
	if player.thirst < 15.0:
		show_message("太渴了，至少需要15点口渴值才能休息")
		return
	player.spend_hunger(18.0)
	player.spend_thirst(15.0)
	_advance_to_next_day()
	player.restore_stamina(player.max_stamina)
	player.heal(15.0)
	show_message("休息了一夜，生命和体力得到恢复")


func drink_from_water_pump() -> void:
	if player.thirst >= player.max_thirst:
		show_message("现在不渴")
		return
	player.restore_thirst(player.max_thirst)
	show_message("饮用了干净的井水，口渴完全恢复")


func refill_watering_can() -> void:
	if not inventory.has_item("watering_can"):
		show_message("背包里没有浇水壶")
		return
	if watering_can_water >= WATERING_CAN_CAPACITY:
		show_message("浇水壶已经装满")
		return
	watering_can_water = WATERING_CAN_CAPACITY
	show_message("浇水壶已经装满：%d/%d" % [watering_can_water, WATERING_CAN_CAPACITY])


func can_water_crop() -> bool:
	if get_active_tool_type() != "watering_can":
		show_message("需要先把浇水壶放入快捷栏并选中")
		return false
	if watering_can_water <= 0:
		show_message("浇水壶空了，去取水泵旁按E装水")
		return false
	return true


func use_watering_can() -> void:
	watering_can_water = maxi(watering_can_water - 1, 0)


func _advance_to_next_day() -> void:
	day_progress = DAY_START_PROGRESS
	day += 1
	night_spawned = false
	for remaining_zombie in get_tree().get_nodes_in_group("zombies"): remaining_zombie.queue_free()
	for plot in get_tree().get_nodes_in_group("farm_plots"): plot.advance_day()
	for chicken in get_tree().get_nodes_in_group("chickens"): chicken.advance_day()
	weather_system.choose_weather_for_day(day)
	if bool(weather_system.get_current_data().get("waters_crops", false)):
		for plot in get_tree().get_nodes_in_group("farm_plots"): plot.water_from_rain()
	if is_instance_valid(homestead): homestead.repair(10.0)
	show_message("第%d天开始了，作物已经生长" % day)


func _on_objective_text_changed(text: String) -> void:
	objective_label.text = text


func _on_objective_completed(title: String, reward_text: String) -> void:
	show_message("目标完成：%s　奖励：%s" % [title, reward_text])


func _on_weather_changed(_weather_id: String, weather_data: Dictionary) -> void:
	player.environment_thirst_multiplier = float(weather_data.get("thirst_multiplier", 1.0))
	weather_label.text = "天气：%s" % weather_data.get("name", "晴朗")


func _get_pressed_hotbar_index(event: InputEvent) -> int:
	for index in 7:
		if event.is_action_pressed("hotbar_slot_%d" % (index + 1)):
			return index
	return -1
