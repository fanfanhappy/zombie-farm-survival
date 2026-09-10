class_name FarmingSystem
extends Node

const DEFAULT_CROP_DATABASE := preload("res://resources/crops/crop_database.tres")
const DEFAULT_FARM_PLOT_SCENE := preload("res://scenes/world/farming/farm_plot.tscn")

@export_group("可视化资源")
@export var farm_plot_scene: PackedScene = DEFAULT_FARM_PLOT_SCENE
@export_group("作物数据")
@export var crop_database: CropDatabase = DEFAULT_CROP_DATABASE
var crop_catalog: Dictionary = {}
var world_tile_map: WorldTileMap
var farm_plots_parent: Node2D


func _ready() -> void:
	_load_crop_catalog()


func get_crop_data(crop_id: String) -> Dictionary:
	return crop_catalog.get(crop_id, {})


func get_crop_from_seed(item_data: Dictionary) -> String:
	if item_data.get("category", "") != "seed": return ""
	return str(item_data.get("crop_id", ""))


func setup(tile_map: WorldTileMap, plots_parent: Node2D) -> void:
	world_tile_map = tile_map
	farm_plots_parent = plots_parent
	world_tile_map._index_farm_plots()


func create_plot_at_cell(cell: Vector2i, validate := true) -> FarmPlot:
	if not is_instance_valid(world_tile_map) or not is_instance_valid(farm_plots_parent):
		return null
	var existing := world_tile_map.get_farm_plot_at_cell(cell)
	if existing != null:
		return existing
	if validate and not world_tile_map.is_cell_tillable(cell):
		return null
	if farm_plot_scene == null:
		push_error("FarmingSystem 未配置农田格场景")
		return null
	var instance := farm_plot_scene.instantiate()
	var plot := instance as FarmPlot
	if plot == null:
		instance.free()
		push_error("FarmingSystem 的农田格场景根节点必须使用 FarmPlot 脚本")
		return null
	farm_plots_parent.add_child(plot)
	plot.global_position = world_tile_map.farm_cell_to_world(cell)
	world_tile_map.register_farm_plot(plot)
	return plot


func create_plot_at_world_position(world_position: Vector2, validate := true) -> FarmPlot:
	if not is_instance_valid(world_tile_map):
		return null
	return create_plot_at_cell(world_tile_map.world_to_farm_cell(world_position), validate)


func reset_for_new_game() -> void:
	if not is_instance_valid(farm_plots_parent):
		return
	for child in farm_plots_parent.get_children():
		farm_plots_parent.remove_child(child)
		child.queue_free()
	world_tile_map.clear_farm_plot_index()


func discard_new_plot(plot: FarmPlot) -> void:
	if not is_instance_valid(plot):
		return
	world_tile_map.unregister_farm_plot(plot)
	var parent := plot.get_parent()
	if parent != null:
		parent.remove_child(plot)
	plot.queue_free()


func get_legacy_plot_cell(index: int) -> Vector2i:
	return Vector2i(7 + index % 9, 14 + index / 9)


func _load_crop_catalog() -> void:
	crop_catalog.clear()
	if crop_database == null:
		push_error("FarmingSystem 未配置作物数据库")
		return
	for issue in crop_database.get_configuration_issues():
		push_warning("种植配置：%s" % issue)
	crop_catalog = crop_database.build_catalog()
