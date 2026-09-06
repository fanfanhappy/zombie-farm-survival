class_name DefenseUpgradeSystem
extends Node

const CATALOG_PATH := "res://data/building/defense_upgrades.json"
const MAX_LEVEL := 3
var catalog: Dictionary = {}


func _ready() -> void:
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_error("防御升级目录不存在：%s" % CATALOG_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary: catalog = parsed


func get_upgrade_data(structure: DefenseStructure) -> Dictionary:
	var type_data: Dictionary = catalog.get(structure.defense_type, {})
	return type_data.get("levels", {}).get(str(structure.upgrade_level + 1), {})


func get_upgrade_cost(structure: DefenseStructure) -> Dictionary:
	return get_upgrade_data(structure).get("cost", {})


func try_upgrade(structure: DefenseStructure, game: Node) -> bool:
	if structure.upgrade_level >= MAX_LEVEL:
		game.show_message("该防御设施已经达到最高等级")
		return false
	if game.get_active_tool_type() != "hammer":
		game.show_message("需要先在快捷栏选中维修锤")
		return false
	var upgrade_data := get_upgrade_data(structure)
	var cost: Dictionary = upgrade_data.get("cost", {})
	for item_id in cost:
		if game.get_resource_amount(item_id) < int(cost[item_id]):
			game.show_message("升级材料不足：%s" % game.format_cost(cost))
			return false
	if not game.player.try_spend_stamina(8.0):
		game.show_message("体力不足，无法升级")
		return false
	for item_id in cost: game.spend_resource(item_id, int(cost[item_id]))
	structure.apply_upgrade(structure.upgrade_level + 1, upgrade_data)
	game.show_message("%s已升级至%d级，耐久提升到%d" % [structure.get_display_name(), structure.upgrade_level, int(structure.max_health)])
	return true
