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


func get_configuration_issues() -> Array[String]:
	var issues: Array[String] = []
	var known_ids: Dictionary = {}
	for index in crops.size():
		var crop := crops[index]
		if crop == null:
			issues.append("作物数据库第%d项为空" % (index + 1))
			continue
		issues.append_array(crop.get_configuration_issues())
		if crop.crop_id.is_empty():
			continue
		var id := String(crop.crop_id)
		if known_ids.has(id):
			issues.append("作物数据库存在重复 Crop Id：%s" % id)
		known_ids[id] = true
	return issues
