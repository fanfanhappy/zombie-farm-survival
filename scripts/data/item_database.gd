class_name ItemDatabase
extends Resource

@export var items: Array[ItemDefinition] = []


func build_catalog() -> Dictionary:
	var catalog: Dictionary = {}
	for item in items:
		if item == null or item.item_id.is_empty():
			continue
		var id := String(item.item_id)
		if catalog.has(id):
			push_warning("物品数据库存在重复 ID：%s" % id)
		catalog[id] = item.to_dictionary()
	return catalog


func get_definition(item_id: String) -> ItemDefinition:
	for item in items:
		if item != null and String(item.item_id) == item_id:
			return item
	return null
