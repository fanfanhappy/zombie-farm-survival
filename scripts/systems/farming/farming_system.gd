class_name FarmingSystem
extends Node

const CROP_CATALOG_PATH := "res://data/crops/crop_catalog.json"

var crop_catalog: Dictionary = {}


func _ready() -> void:
	_load_crop_catalog()


func get_crop_data(crop_id: String) -> Dictionary:
	return crop_catalog.get(crop_id, {})


func get_crop_from_seed(item_data: Dictionary) -> String:
	if item_data.get("category", "") != "seed": return ""
	return str(item_data.get("crop_id", ""))


func _load_crop_catalog() -> void:
	if not FileAccess.file_exists(CROP_CATALOG_PATH):
		push_error("作物目录不存在：%s" % CROP_CATALOG_PATH)
		return
	var file := FileAccess.open(CROP_CATALOG_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		crop_catalog = parsed
	else:
		push_error("作物目录格式无效：%s" % CROP_CATALOG_PATH)

