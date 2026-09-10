class_name CropDefinition
extends Resource

@export_group("基础信息")
@export var crop_id: StringName
@export var display_name := "新作物"
@export var seed_item_id: StringName
@export var visual_scene: PackedScene

@export_group("生长与收获")
@export_range(1, 30, 1) var growth_days := 1
@export_range(1, 30, 1) var dry_tolerance_days := 2
@export_range(0, 1000, 1) var harvest_experience := 8
@export var harvest: Array[ItemAmount] = []


func to_dictionary() -> Dictionary:
	return {
		"id": String(crop_id),
		"name": display_name,
		"seed_item": String(seed_item_id),
		"visual_scene": visual_scene,
		"growth_days": growth_days,
		"dry_tolerance_days": dry_tolerance_days,
		"harvest_experience": harvest_experience,
		"harvest": ItemAmount.list_to_dictionary(harvest),
	}


func get_configuration_issues() -> Array[String]:
	var issues: Array[String] = []
	var label := display_name if not display_name.is_empty() else "未命名作物"
	if crop_id.is_empty():
		issues.append("%s：Crop Id 不能为空" % label)
	if seed_item_id.is_empty():
		issues.append("%s：Seed Item Id 不能为空" % label)
	if visual_scene == null:
		issues.append("%s：未配置 Visual Scene" % label)
	var harvest_items := ItemAmount.list_to_dictionary(harvest)
	if harvest_items.is_empty():
		issues.append("%s：Harvest 至少需要一个有效物品" % label)
	elif not seed_item_id.is_empty() and int(harvest_items.get(String(seed_item_id), 0)) <= 0:
		issues.append("%s：Harvest 没有返还自己的种子，无法长期循环" % label)
	return issues
