class_name WorldGridCursor
extends Node2D

enum CursorState { HIDDEN, INTERACTABLE, OUT_OF_REACH, BLOCKED }

var state := CursorState.HIDDEN


func set_cursor(at_position: Vector2, next_state: CursorState) -> void:
	position = at_position
	visible = next_state != CursorState.HIDDEN
	if state == next_state:
		return
	state = next_state
	queue_redraw()


func _draw() -> void:
	var fill_color := Color(0.35, 0.9, 0.42, 0.22)
	var border_color := Color("#75ed7d")
	match state:
		CursorState.OUT_OF_REACH:
			fill_color = Color(1.0, 0.72, 0.2, 0.2)
			border_color = Color("#ffc45c")
		CursorState.BLOCKED:
			fill_color = Color(0.95, 0.25, 0.22, 0.18)
			border_color = Color("#f06a63")
	draw_rect(Rect2(-16, -16, 32, 32), fill_color, true)
	draw_rect(Rect2(-15, -15, 30, 30), border_color, false, 2.0)
	if state == CursorState.BLOCKED:
		draw_line(Vector2(-9, -9), Vector2(9, 9), border_color, 1.5)
		draw_line(Vector2(9, -9), Vector2(-9, 9), border_color, 1.5)

