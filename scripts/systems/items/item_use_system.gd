class_name ItemUseSystem
extends RefCounted


func handle_item_use(game: Node, item_id: String) -> void:
	var item_data: Dictionary = game.inventory.get_item_data(item_id)
	match str(item_data.get("category", "")):
		"placeable":
			if game.inventory_ui.is_backpack_open(): game.inventory_ui.close_backpack()
			game.placement_system.begin_placement(item_id)
		"weapon":
			game.player.equip_weapon(item_id, item_data.get("name", item_id), float(item_data.get("attack_damage", 25.0)))
			game.show_message("已装备：%s" % item_data.get("name", item_id))
		"seed": game.show_message("已选中：%s，靠近开垦后的农田进行播种" % item_data.get("name", item_id))
		"tool":
			var message := "已选中工具：%s" if game.get_selected_hotbar_item_id() == item_id else "请先把%s拖入快捷栏"
			game.show_message(message % item_data.get("name", item_id))
		"consumable", "ingredient": use_consumable(game, item_id)
		_: game.show_message("这个物品目前不能直接使用")


func use_consumable(game: Node, item_id: String) -> bool:
	var definition: ItemDefinition = game.inventory.item_database.get_definition(item_id)
	var effect: ConsumableEffectDefinition = definition.consumable_effect if definition != null else null
	if effect == null:
		game.show_message("这个物品没有配置使用效果")
		return false
	if effect.health_restore > 0.0 and game.player.health >= game.player.max_health and effect.hunger_restore <= 0.0 and effect.stamina_restore <= 0.0:
		game.show_message("生命值已经满了")
		return false
	if effect.hunger_restore > 0.0 and game.player.hunger >= game.player.max_hunger and effect.health_restore <= 0.0 and effect.stamina_restore <= 0.0:
		game.show_message("现在还不饿")
		return false
	if not game.spend_resource(item_id, 1):
		game.show_message("没有%s" % game.inventory.get_display_name(item_id))
		return false
	if effect.health_restore > 0.0: game.player.heal(effect.health_restore)
	if effect.stamina_restore > 0.0: game.player.restore_stamina(effect.stamina_restore)
	if effect.hunger_restore > 0.0: game.player.restore_hunger(effect.hunger_restore)
	if effect.thirst_restore > 0.0: game.player.restore_thirst(effect.thirst_restore)
	if effect.well_fed_duration > 0.0: game.player.apply_well_fed(effect.well_fed_duration)
	game.show_message(effect.use_message)
	return true


func apply_recipe_effect(game: Node, effect: Dictionary) -> void:
	if not effect.has("equip_weapon"): return
	var item_id := str(effect["equip_weapon"])
	var item_data: Dictionary = game.inventory.get_item_data(item_id)
	game.player.equip_weapon(item_id, item_data.get("name", item_id), float(effect.get("attack_damage", item_data.get("attack_damage", 25.0))))
