class_name FarmingSystem
extends Node

const DEFAULT_CROP_DATABASE := preload("res://resources/crops/crop_database.tres")

@export var crop_database: CropDatabase = DEFAULT_CROP_DATABASE
var crop_catalog: Dictionary = {}


func _ready() -> void:
	_load_crop_catalog()


func get_crop_data(crop_id: String) -> Dictionary:
	return crop_catalog.get(crop_id, {})


func get_crop_from_seed(item_data: Dictionary) -> String:
	if item_data.get("category", "") != "seed": return ""
	return str(item_data.get("crop_id", ""))


func _load_crop_catalog() -> void:
	crop_catalog.clear()
	if crop_database == null:
		push_error("FarmingSystem 未配置作物数据库")
		return
	crop_catalog = crop_database.build_catalog()
