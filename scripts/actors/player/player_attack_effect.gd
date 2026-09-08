class_name PlayerAttackEffect
extends Node2D


func update_effect(time_left: float, cooldown: float, facing_direction: Vector2) -> void:
	visible = time_left > cooldown - 0.14
	rotation = facing_direction.angle()
