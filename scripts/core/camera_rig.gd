class_name CameraRig
extends Node2D

@export_node_path("Node2D") var target_path: NodePath
@export var follow_offset := Vector2(0, -20)

@onready var target: Node2D = get_node_or_null(target_path) as Node2D


func _process(_delta: float) -> void:
	if is_instance_valid(target):
		global_position = target.global_position + follow_offset
