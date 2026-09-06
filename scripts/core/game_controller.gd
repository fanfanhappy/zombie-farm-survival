extends Node2D

const PLAYER_HOME := Vector2(640, 460)
const DAY_LENGTH_SECONDS := 90.0
const WATERING_CAN_CAPACITY := 5

@onready var player: Player = $Player
@onready var darkness: CanvasModulate = $Darkness
@onready var status_label: Label = $HUD/StatusPanel/Margin/Status
@onready var prompt_label: Label = $HUD/Prompt
@onready var message_label: Label = $HUD/Message
@onready var help_label: Label = $HUD/HelpPanel/Margin/Help
@onready var crafting_system: CraftingSystem = $CraftingSystem
@onready var crafting_panel: PanelContainer = $HUD/CraftingPanel
@onready var crafting_title: Label = $HUD/CraftingPanel/Margin/Content/Title
@onready var recipe_list: VBoxContainer = $HUD/CraftingPanel/Margin/Content/RecipeList
@onready var inventory: InventorySystem = $InventorySystem
@onready var inventory_ui: InventoryUI = $InventoryUI
@onready var storage_ui: StorageUI = $StorageUI
@onready var placement_system: PlacementSystem = $PlacementSystem
@onready var defense_upgrade_system: DefenseUpgradeSystem = $DefenseUpgradeSystem
@onready var horde_system: HordeSystem = $HordeSystem
@onready var horde_label: Label = $HUD/HordeStatus
@onready var farming_system: FarmingSystem = $FarmingSystem
@onready var objective_system: ObjectiveSystem = $ObjectiveSystem
@onready var objective_label: Label = $HUD/ObjectiveStatus
@onready var weather_system: WeatherSystem = $WeatherSystem
@onready var weather_label: Label = $HUD/WeatherStatus
@onready var pause_overlay: ColorRect = $HUD/PauseOverlay

const STARTING_ITEMS := {"wooden_club": 1, "stone_hoe": 1, "watering_can": 1, "wood_fence": 3, "wood_spike": 2, "storage_chest": 1, "snare_trap": 1, "wood": 8, "stone": 4, "herb": 2, "potato": 2, "potato_seed": 4, "carrot_seed": 3, "herb_seed": 2}
var day := 1
var day_progress := 0.25
var last_hour := -1
var night_spawned := false
var message_time := 0.0
var kills := 0
var homestead: HomesteadCore
var hordes_survived := 0
var mouse_action_held := false
var mouse_action_cooldown := 0.0
var watering_can_water := WATERING_CAN_CAPACITY


func _ready() -> void:
	inventory.initialize(STARTING_ITEMS)
	inventory_ui.setup(inventory)
	storage_ui.setup(inventory)
	storage_ui.storage_closed.connect(_on_storage_closed)
	inventory_ui.item_use_requested.connect(_on_inventory_item_use_requested)
	inventory_ui.item_drop_requested.connect(_on_inventory_item_drop_requested)
	inventory_ui.inventory_closed.connect(_on_inventory_closed)
	placement_system.setup(self, inventory)
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
	_spawn_world_objects()
	_create_world_collisions()
	$HUD/CraftingPanel/Margin/Content/Close.pressed.connect(close_crafting)
	$HUD/PauseOverlay/PausePanel/Margin/Buttons/Resume.pressed.connect(_set_paused.bind(false))
	$HUD/PauseOverlay/PausePanel/Margin/Buttons/Save.pressed.connect(save_game)
	$HUD/PauseOverlay/PausePanel/Margin/Buttons/Load.pressed.connect(load_game)
	$HUD/PauseOverlay/PausePanel/Margin/Buttons/Quit.pressed.connect(get_tree().quit)
	_update_hud()
	var start_mode := SaveSystem.consume_start_mode()
	if start_mode == "continue": load_game()
	else: reset_for_new_game()


func reset_for_new_game() -> void:
	day = 1
	day_progress = 0.25
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
	inventory.reset_for_new_game(STARTING_ITEMS)
	inventory.assign_hotbar_item(0, "wooden_club")
	inventory.assign_hotbar_item(1, "stone_hoe")
	inventory.assign_hotbar_item(2, "watering_can")
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
	_update_farm_plot_highlights()
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
			_set_paused(false)
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


func add_resource(type: String, amount: int, announce := true) -> void:
	var remaining := inventory.add_item(type, amount)
	var accepted := amount - remaining
	if announce and accepted > 0: show_message("获得 %s × %d" % [_resource_name(type), accepted])
	if remaining > 0: show_message("背包已满，%s × %d 无法放入" % [_resource_name(type), remaining])


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
		mouse_action_cooldown = player.TOOL_ACTION_DURATION
		return
	if player.try_mouse_attack(mouse_world_position): mouse_action_cooldown = player.attack_cooldown
	else: mouse_action_cooldown = 0.1


func _nearest_mouse_target(mouse_world_position: Vector2) -> Node2D:
	var nearest: Node2D
	var nearest_cursor_distance := 28.0
	for node in get_tree().get_nodes_in_group("mouse_action_targets"):
		var target := node as Node2D
		var cursor_distance := mouse_world_position.distance_to(target.global_position)
		if cursor_distance < nearest_cursor_distance and player.global_position.distance_to(target.global_position) <= 64.0:
			nearest = target
			nearest_cursor_distance = cursor_distance
	for node in get_tree().get_nodes_in_group("zombies"):
		var zombie := node as Zombie
		var cursor_distance := mouse_world_position.distance_to(zombie.global_position)
		if cursor_distance < nearest_cursor_distance and player.global_position.distance_to(zombie.global_position) <= 70.0:
			nearest = zombie
			nearest_cursor_distance = cursor_distance
	return nearest


func _on_player_died() -> void:
	show_message("你倒下了。清晨醒来时，部分物资遗失了。")
	if inventory.has_item("potato"): inventory.remove_item("potato", 1)
	for zombie in get_tree().get_nodes_in_group("zombies"): zombie.queue_free()
	player.revive(PLAYER_HOME)
	day_progress = 0.25


func _nearest_interactable() -> Node:
	var nearest: Node
	var nearest_distance := 58.0
	for node in get_tree().get_nodes_in_group("interactables"):
		var distance := player.global_position.distance_to(node.global_position)
		if distance < nearest_distance:
			var prompt: String = node.get_interaction_prompt() if node.has_method("get_interaction_prompt") else ""
			if not prompt.is_empty(): nearest = node; nearest_distance = distance
	return nearest


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
	prompt_label.text = target.get_interaction_prompt() if target else ""


func _update_farm_plot_highlights() -> void:
	var mouse_world_position := get_global_mouse_position()
	for node in get_tree().get_nodes_in_group("farm_plots"):
		var plot := node as FarmPlot
		var hovered := mouse_world_position.distance_to(plot.global_position) <= 16.0
		var reachable := player.global_position.distance_to(plot.global_position) <= 64.0
		plot.set_mouse_highlight(hovered, reachable)


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
		get_tree().create_timer(index * 0.4).timeout.connect(_spawn_zombie.bind(index % 5 == 4))


func _spawn_zombie(fast: bool) -> void:
	var zombie := Zombie.new()
	match randi() % 4:
		0: zombie.position = Vector2(randf_range(40, 1240), 40)
		1: zombie.position = Vector2(randf_range(40, 1240), 760)
		2: zombie.position = Vector2(40, randf_range(40, 760))
		_: zombie.position = Vector2(1240, randf_range(40, 760))
	add_child(zombie); zombie.setup(player, homestead, fast)
	zombie.defeated.connect(_on_zombie_defeated)


func _on_zombie_defeated(_zombie: Zombie) -> void:
	kills += 1
	horde_system.notify_zombie_defeated()
	var experience_reward := _zombie.experience_reward
	var leveled_up := player.add_experience(experience_reward)
	if leveled_up:
		show_message("升级！达到%d级，生命、体力和伤害提升" % player.level)
		return
	if randf() < 0.45:
		add_resource("herb", 1, false); show_message("击败感染者：经验+%d，获得1份草药" % experience_reward)
	else: show_message("击败感染者：经验+%d" % experience_reward)


func _spawn_world_objects() -> void:
	for data in [["wood", Vector2(145, 175)], ["wood", Vector2(1080, 190)], ["wood", Vector2(1060, 565)], ["wood", Vector2(570, 170)], ["stone", Vector2(570, 520)], ["stone", Vector2(1030, 470)], ["stone", Vector2(620, 640)], ["herb", Vector2(530, 610)], ["herb", Vector2(1020, 620)]]:
		var node := HarvestableResource.new(); node.position = data[1]; add_child(node); node.setup(data[0])
	for row in 6:
		for column in 12:
			var plot := FarmPlot.new(); plot.position = Vector2(224 + column * 32, 428 + row * 32); add_child(plot)
	var workbench := CraftingStation.new(); workbench.position = Vector2(625, 330); add_child(workbench); workbench.setup("workbench")
	var kitchen := CraftingStation.new(); kitchen.position = Vector2(1040, 325); add_child(kitchen); kitchen.setup("kitchen")
	var sleep_point := SleepPoint.new(); sleep_point.position = Vector2(930, 425); add_child(sleep_point)
	var water_pump := WaterPump.new(); water_pump.position = Vector2(755, 435); add_child(water_pump)


func _create_world_collisions() -> void:
	_add_wall(Vector2(640, 5), Vector2(1280, 10)); _add_wall(Vector2(640, 795), Vector2(1280, 10))
	_add_wall(Vector2(5, 400), Vector2(10, 800)); _add_wall(Vector2(1275, 400), Vector2(10, 800))
	homestead = HomesteadCore.new()
	homestead.position = Vector2(840, 280)
	add_child(homestead)
	homestead.setup(Vector2(300, 220))
	homestead.destroyed.connect(_on_homestead_destroyed)
	var repair_point := HomesteadRepairPoint.new()
	repair_point.position = Vector2(840, 420)
	add_child(repair_point)
	repair_point.setup(homestead)


func _add_wall(at: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new(); body.position = at
	var collision := CollisionShape2D.new(); var rectangle := RectangleShape2D.new()
	rectangle.size = size; collision.shape = rectangle; body.add_child(collision); add_child(body)


func _update_lighting() -> void:
	var hour := day_progress * 24.0; var light := 1.0
	if hour < 5.0: light = 0.38
	elif hour < 7.0: light = lerpf(0.38, 1.0, (hour - 5.0) / 2.0)
	elif hour > 19.0: light = lerpf(1.0, 0.38, minf((hour - 19.0) / 2.5, 1.0))
	darkness.color = Color(light, light, lerpf(light, 0.58, 1.0 - light), 1.0)


func _update_hud() -> void:
	if not is_instance_valid(player): return
	var total_minutes := int(day_progress * 1440.0)
	var home_health := int(homestead.health) if is_instance_valid(homestead) else 0
	var home_max := int(homestead.max_health) if is_instance_valid(homestead) else 0
	status_label.text = "第 %d 天  %02d:%02d　等级 %d（%d/%d经验）\n生命 %d/%d　体力 %d/%d\n饥饿 %d/%d　口渴 %d/%d\n农舍 %d/%d　武器 %s\n背包 %d/%d 格　击杀 %d" % [day, total_minutes / 60, total_minutes % 60, player.level, player.experience, player.get_next_level_experience(), int(player.health), int(player.max_health), int(player.stamina), int(player.max_stamina), int(player.hunger), int(player.max_hunger), int(player.thirst), int(player.max_thirst), home_health, home_max, player.equipped_weapon, inventory.get_used_slots(), inventory.slot_capacity, kills]
	if player.hunger <= 20.0: status_label.text += "\n⚠ 非常饥饿"
	if player.thirst <= 20.0: status_label.text += "\n⚠ 严重口渴"
	help_label.text = "WASD 移动　Shift 冲刺　鼠标操作/攻击　Esc 暂停　F11 全屏\nE 使用设施　B 背包　数字键快捷栏　U 升级　X 拆除\n鼠标：点击或长按目标　放置：左键确认 R旋转 右键取消"
	if player.well_fed_time > 0.0:
		status_label.text += "\n饱餐：%d秒（攻击+20%% / 恢复+35%%）" % int(ceil(player.well_fed_time))
	if get_active_tool_type() == "watering_can":
		status_label.text += "\n水壶：%d/%d" % [watering_can_water, WATERING_CAN_CAPACITY]
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
	if horde_system.active: show_message("尸潮期间不能保存"); return
	var data := {"version": 15, "day": day, "day_progress": day_progress, "weather": weather_system.current_weather_id, "inventory": inventory.create_save_data(), "player_position": {"x": player.position.x, "y": player.position.y}, "health": player.health, "max_health": player.max_health, "stamina": player.stamina, "max_stamina": player.max_stamina, "hunger": player.hunger, "thirst": player.thirst, "level": player.level, "experience": player.experience, "well_fed_time": player.well_fed_time, "homestead_health": homestead.health, "equipped_weapon_id": player.equipped_weapon_id, "weapon": player.equipped_weapon, "attack_damage": player.attack_damage, "kills": kills, "hordes_survived": hordes_survived, "defenses": _serialize_defenses(), "storage_chests": _serialize_storage_chests(), "ground_items": _serialize_ground_items(), "farm_plots": _serialize_farm_plots(), "objectives": objective_system.create_save_data()}
	data["version"] = 17
	data["snare_traps"] = _serialize_snare_traps()
	data["watering_can_water"] = watering_can_water
	show_message("游戏已保存" if SaveSystem.save_game(data) else "保存失败")


func load_game() -> void:
	var data := SaveSystem.load_game()
	if data.is_empty(): show_message("没有找到存档"); return
	day = int(data.get("day", 1)); day_progress = float(data.get("day_progress", 0.25))
	weather_system.set_weather(str(data.get("weather", "clear")))
	var saved_inventory: Dictionary = data.get("inventory", data.get("resources", STARTING_ITEMS))
	inventory.restore_save_data(saved_inventory)
	var position_data: Dictionary = data.get("player_position", {})
	player.position = Vector2(float(position_data.get("x", PLAYER_HOME.x)), float(position_data.get("y", PLAYER_HOME.y)))
	player.max_health = float(data.get("max_health", player.max_health))
	player.max_stamina = float(data.get("max_stamina", player.max_stamina))
	player.health = clampf(float(data.get("health", player.max_health)), 0.0, player.max_health)
	player.stamina = clampf(float(data.get("stamina", player.max_stamina)), 0.0, player.max_stamina)
	player.hunger = float(data.get("hunger", player.max_hunger))
	player.thirst = float(data.get("thirst", player.max_thirst))
	player.level = int(data.get("level", 1))
	player.experience = int(data.get("experience", 0))
	player.well_fed_time = float(data.get("well_fed_time", 0.0))
	watering_can_water = clampi(int(data.get("watering_can_water", WATERING_CAN_CAPACITY)), 0, WATERING_CAN_CAPACITY)
	var weapon_id := str(data.get("equipped_weapon_id", "wooden_club"))
	if not inventory.has_item(weapon_id): inventory.add_item(weapon_id, 1)
	var weapon_data := inventory.get_item_data(weapon_id)
	player.equip_weapon(weapon_id, weapon_data.get("name", data.get("weapon", "木棒")), float(weapon_data.get("attack_damage", data.get("attack_damage", 25.0))))
	homestead.health = clampf(float(data.get("homestead_health", homestead.max_health)), 1.0, homestead.max_health)
	homestead.repair(0.0)
	_restore_defenses(data.get("defenses", []))
	_restore_storage_chests(data.get("storage_chests", []))
	_restore_snare_traps(data.get("snare_traps", []))
	_restore_ground_items(data.get("ground_items", []))
	_restore_farm_plots(data.get("farm_plots", []))
	kills = int(data.get("kills", 0)); hordes_survived = int(data.get("hordes_survived", 0))
	objective_system.restore_save_data(data.get("objectives", {}))
	_update_hud(); show_message("存档已读取")


func _serialize_defenses() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in get_tree().get_nodes_in_group("defenses"):
		var structure := node as DefenseStructure
		result.append({"type": structure.defense_type, "x": structure.position.x, "y": structure.position.y, "rotation": structure.rotation, "health": structure.health, "upgrade_level": structure.upgrade_level, "max_health": structure.max_health, "spike_damage": structure.spike_damage})
	return result


func _restore_defenses(saved_defenses: Array) -> void:
	for node in get_tree().get_nodes_in_group("defenses"): node.queue_free()
	for entry in saved_defenses:
		if not entry is Dictionary: continue
		var structure := DefenseStructure.new()
		structure.position = Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))
		structure.rotation = float(entry.get("rotation", 0.0))
		add_child(structure)
		structure.setup(str(entry.get("type", "fence")))
		structure.upgrade_level = int(entry.get("upgrade_level", 1))
		structure.max_health = float(entry.get("max_health", structure.max_health))
		structure.spike_damage = float(entry.get("spike_damage", structure.spike_damage))
		structure.health = float(entry.get("health", structure.max_health))
		structure.queue_redraw()


func _serialize_storage_chests() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in get_tree().get_nodes_in_group("storage_chests"):
		result.append((node as StorageChest).create_save_data())
	return result


func _restore_storage_chests(saved_chests: Array) -> void:
	for node in get_tree().get_nodes_in_group("storage_chests"): node.queue_free()
	for entry in saved_chests:
		if not entry is Dictionary: continue
		var chest := StorageChest.new()
		chest.position = Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))
		chest.rotation = float(entry.get("rotation", 0.0))
		add_child(chest)
		chest.restore_items(entry.get("items", {}))


func _serialize_snare_traps() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in get_tree().get_nodes_in_group("snare_traps"):
		result.append((node as SnareTrap).create_save_data())
	return result


func _restore_snare_traps(saved_traps: Array) -> void:
	for node in get_tree().get_nodes_in_group("snare_traps"): node.queue_free()
	for entry in saved_traps:
		if not entry is Dictionary: continue
		var trap := SnareTrap.new()
		trap.position = Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))
		trap.rotation = float(entry.get("rotation", 0.0))
		trap.charges = int(entry.get("charges", SnareTrap.MAX_CHARGES))
		add_child(trap)


func _serialize_farm_plots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in get_tree().get_nodes_in_group("farm_plots"):
		result.append((node as FarmPlot).create_save_data())
	return result


func _serialize_ground_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in get_tree().get_nodes_in_group("ground_items"):
		result.append((node as GroundItem).create_save_data())
	return result


func _restore_ground_items(saved_items: Array) -> void:
	for node in get_tree().get_nodes_in_group("ground_items"): node.queue_free()
	for entry in saved_items:
		if not entry is Dictionary: continue
		_spawn_ground_item(str(entry.get("item_id", "wood")), int(entry.get("amount", 1)), Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0))))


func _restore_farm_plots(saved_plots: Array) -> void:
	var plots := get_tree().get_nodes_in_group("farm_plots")
	for index in mini(saved_plots.size(), plots.size()):
		if saved_plots[index] is Dictionary:
			(plots[index] as FarmPlot).restore_save_data(saved_plots[index], farming_system)


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
	var ground_item := GroundItem.new()
	ground_item.position = at_position
	add_child(ground_item)
	ground_item.setup(item_id, amount, inventory.get_display_name(item_id))


func _try_dismantle_nearest() -> void:
	var nearest := _get_nearest_defense()
	if nearest: nearest.try_dismantle(self)
	else: show_message("附近没有可拆除的防御设施")


func _try_upgrade_nearest() -> void:
	var nearest := _get_nearest_defense()
	if nearest: defense_upgrade_system.try_upgrade(nearest, self)
	else: show_message("附近没有可升级的防御设施")


func _get_nearest_defense() -> DefenseStructure:
	var nearest: DefenseStructure
	var nearest_distance := 58.0
	for node in get_tree().get_nodes_in_group("defenses"):
		var structure := node as DefenseStructure
		var distance := player.global_position.distance_to(structure.global_position)
		if distance < nearest_distance:
			nearest = structure
			nearest_distance = distance
	return nearest


func _set_player_control(enabled: bool) -> void:
	player.set_physics_process(enabled)
	player.set_process_unhandled_input(enabled)


func _set_paused(paused: bool) -> void:
	pause_overlay.visible = paused
	Engine.time_scale = 0.0 if paused else 1.0
	_set_player_control(not paused)
	if paused: $HUD/PauseOverlay/PausePanel/Margin/Buttons/Resume.grab_focus()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _on_homestead_destroyed() -> void:
	show_message("农舍被攻破了。清晨，你修复了最基本的结构。")
	horde_system.cancel_horde()
	for zombie in get_tree().get_nodes_in_group("zombies"): zombie.queue_free()
	homestead.restore_full()
	day += 1
	day_progress = 0.25
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
	day_progress = 0.25
	day += 1
	night_spawned = false
	for remaining_zombie in get_tree().get_nodes_in_group("zombies"): remaining_zombie.queue_free()
	for plot in get_tree().get_nodes_in_group("farm_plots"): plot.advance_day()
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


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 800), Color("#82a85d"))
	for x in range(0, 1280, 32): draw_line(Vector2(x, 0), Vector2(x, 800), Color("#789d55"), 1.0)
	for y in range(0, 800, 32): draw_line(Vector2(0, y), Vector2(1280, y), Color("#789d55"), 1.0)
	draw_rect(Rect2(690, 170, 300, 220), Color("#c69b66"))
	draw_colored_polygon(PackedVector2Array([Vector2(660, 190), Vector2(840, 80), Vector2(1020, 190)]), Color("#7e4a3e"))
	draw_rect(Rect2(815, 310, 52, 80), Color("#604638"))
	draw_rect(Rect2(730, 240, 54, 46), Color("#9fd1d5")); draw_rect(Rect2(895, 240, 54, 46), Color("#9fd1d5"))
	var fence := Color("#71533b")
	draw_rect(Rect2(110, 105, 1040, 14), fence); draw_rect(Rect2(110, 105, 14, 590), fence)
	draw_rect(Rect2(1136, 105, 14, 590), fence); draw_rect(Rect2(110, 681, 450, 14), fence); draw_rect(Rect2(720, 681, 430, 14), fence)
