class_name FarmingSystem
extends Node

const DEFAULT_CROP_DATABASE := preload("res://resources/crops/crop_database.tres")
const FARM_PLOT_SCENE := preload("res://scenes/world/farming/farm_plot.tscn")

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
	var plot := FARM_PLOT_SCENE.instantiate() as FarmPlot
	farm_plots_parent.add_child(plot)
	plot.global_position = WorldGrid.cell_to_world(cell)
	world_tile_map.register_farm_plot(plot)
	return plot


func create_plot_at_world_position(world_position: Vector2, validate := true) -> FarmPlot:
	return create_plot_at_cell(WorldGrid.world_to_cell(world_position), validate)


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
	crop_catalog = crop_database.build_catalog()
