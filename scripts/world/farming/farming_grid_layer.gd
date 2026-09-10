@tool
class_name FarmingGridLayer
extends TileMapLayer

@export_group("编辑器预览")
@export var editor_tint := Color(1.0, 0.35, 0.2, 0.42)


func _ready() -> void:
	if Engine.is_editor_hint():
		self_modulate = editor_tint
	else:
		visible = false
