class_name CropDatabase
extends Resource

@export var crops: Array[CropDefinition] = []


func build_catalog() -> Dictionary:
	var catalog: Dictionary = {}
	for crop in crops:
		if crop == null or crop.crop_id.is_empty():
			continue
		var id := String(crop.crop_id)
		if catalog.has(id):
			push_warning("作物数据库存在重复 ID：%s" % id)
		catalog[id] = crop.to_dictionary()
	return catalog
