class_name CropVisual
extends Node2D


func show_stage(stage_index: int) -> void:
	var clamped_stage := clampi(stage_index, 0, 4)
	for index in 5:
		var stage_node := get_node_or_null("Stage%d" % index) as CanvasItem
		if stage_node:
			stage_node.visible = index == clamped_stage
