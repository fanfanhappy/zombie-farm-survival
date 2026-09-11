class_name CropVisual
extends Node2D

@export_group("枯萎外观")
@export var withered_modulate := Color(0.48, 0.43, 0.34, 0.82)

@export_group("贴地对齐")
@export var auto_align_to_ground := true


func show_stage(stage_index: int) -> void:
	var stage_nodes := get_stage_nodes()
	if stage_nodes.is_empty():
		return
	var clamped_stage := clampi(stage_index, 0, stage_nodes.size() - 1)
	for index in stage_nodes.size():
		stage_nodes[index].visible = index == clamped_stage
		if auto_align_to_ground:
			_align_stage_bottom(stage_nodes[index])
	modulate = Color.WHITE


func show_withered() -> void:
	show_stage(get_last_stage_index())
	modulate = withered_modulate


func get_stage_count() -> int:
	return get_stage_nodes().size()


func get_last_stage_index() -> int:
	return maxi(get_stage_count() - 1, 0)


func get_stage_nodes() -> Array[CanvasItem]:
	var result: Array[CanvasItem] = []
	for child in get_children():
		if child is CanvasItem and String(child.name).begins_with("Stage"):
			result.append(child as CanvasItem)
	result.sort_custom(func(a: CanvasItem, b: CanvasItem) -> bool:
		return _stage_number(a) < _stage_number(b)
	)
	return result


func _stage_number(stage_node: CanvasItem) -> int:
	return int(String(stage_node.name).trim_prefix("Stage"))


func _align_stage_bottom(stage_node: CanvasItem) -> void:
	if not stage_node is Sprite2D:
		return
	var sprite := stage_node as Sprite2D
	if not sprite.centered:
		return
	var frame_height := 0.0
	if sprite.region_enabled:
		frame_height = sprite.region_rect.size.y
	elif sprite.texture:
		frame_height = sprite.texture.get_height()
	if frame_height <= 0.0:
		return
	sprite.position.y = -frame_height * 0.5
