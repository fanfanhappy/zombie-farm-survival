class_name PlayerInputComponent
extends Node


func get_move_direction(input_locked: bool) -> Vector2:
	if input_locked:
		return Vector2.ZERO
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var arrows := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	return (keyboard + arrows).limit_length(1.0)


func is_sprint_requested(direction: Vector2) -> bool:
	return direction != Vector2.ZERO and Input.is_action_pressed("sprint")


func is_interact_pressed(event: InputEvent) -> bool:
	return event.is_action_pressed("interact")
