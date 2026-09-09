@tool
class_name WorldBoundsController
extends StaticBody2D

const DEFAULT_WORLD_SETTINGS := preload("res://resources/settings/world_settings.tres")

@export_group("边界来源")
@export_node_path("TileMapLayer") var water_layer_path: NodePath
@export_node_path("Camera2D") var camera_path: NodePath
@export var world_settings: WorldSettings = DEFAULT_WORLD_SETTINGS
@export_range(4.0, 64.0, 1.0) var boundary_thickness := 16.0
@export_tool_button("根据水面同步边界") var sync_bounds_button: Callable = sync_from_water_layer


func _ready() -> void:
	if not Engine.is_editor_hint():
		sync_from_water_layer()


func sync_from_water_layer() -> void:
	var water_layer := get_node_or_null(water_layer_path) as TileMapLayer
	if water_layer == null or water_layer.tile_set == null:
		push_warning("无法同步世界边界：WaterLayer 或 TileSet 不存在")
		return
	var used_rect := water_layer.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		push_warning("无法同步世界边界：WaterLayer 尚未绘制任何水面")
		return
	var tile_size := water_layer.tile_set.tile_size
	var start := water_layer.to_global(Vector2(used_rect.position * tile_size))
	var finish := water_layer.to_global(Vector2(used_rect.end * tile_size))
	var bounds := Rect2(start.min(finish), (finish - start).abs())
	_apply_bounds(bounds)
	if Engine.is_editor_hint() and world_settings != null and not world_settings.resource_path.is_empty():
		ResourceSaver.save(world_settings, world_settings.resource_path)


func _apply_bounds(bounds: Rect2) -> void:
	if world_settings != null:
		world_settings.world_bounds = bounds
	var camera := get_node_or_null(camera_path) as Camera2D
	if camera != null:
		camera.limit_left = floori(bounds.position.x)
		camera.limit_top = floori(bounds.position.y)
		camera.limit_right = ceili(bounds.end.x)
		camera.limit_bottom = ceili(bounds.end.y)
	var half_thickness := boundary_thickness * 0.5
	_set_boundary("TopBoundary", Vector2(bounds.get_center().x, bounds.position.y + half_thickness), Vector2(bounds.size.x, boundary_thickness))
	_set_boundary("BottomBoundary", Vector2(bounds.get_center().x, bounds.end.y - half_thickness), Vector2(bounds.size.x, boundary_thickness))
	_set_boundary("LeftBoundary", Vector2(bounds.position.x + half_thickness, bounds.get_center().y), Vector2(boundary_thickness, bounds.size.y))
	_set_boundary("RightBoundary", Vector2(bounds.end.x - half_thickness, bounds.get_center().y), Vector2(boundary_thickness, bounds.size.y))


func _set_boundary(node_name: StringName, global_center: Vector2, size: Vector2) -> void:
	var collision := get_node_or_null(NodePath(String(node_name))) as CollisionShape2D
	if collision == null:
		return
	var rectangle := collision.shape as RectangleShape2D
	if rectangle == null or not rectangle.resource_local_to_scene:
		rectangle = RectangleShape2D.new()
		rectangle.resource_local_to_scene = true
		collision.shape = rectangle
	rectangle.size = size
	collision.position = to_local(global_center)
