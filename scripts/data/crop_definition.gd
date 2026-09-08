class_name CropDefinition
extends Resource

@export_group("基础信息")
@export var crop_id: StringName
@export var display_name := "新作物"
@export var seed_item_id: StringName
@export var visual_scene: PackedScene

@export_group("生长与收获")
@export_range(1, 30, 1) var growth_days := 1
@export var harvest: Array[ItemAmount] = []


func to_dictionary() -> Dictionary:
	return {
		"id": String(crop_id),
		"name": display_name,
		"seed_item": String(seed_item_id),
		"visual_scene": visual_scene,
		"growth_days": growth_days,
		"harvest": ItemAmount.list_to_dictionary(harvest),
	}
