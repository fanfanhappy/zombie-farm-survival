class_name WorldGridCursor
extends Node2D

enum CursorState { HIDDEN, INTERACTABLE, OUT_OF_REACH, BLOCKED }

var state := CursorState.HIDDEN
var cell_size := 32.0


func set_cursor(at_position: Vector2, next_state: CursorState, next_cell_size := 32.0) -> void:
	position = at_position
	visible = next_state != CursorState.HIDDEN
	if state == next_state and is_equal_approx(cell_size, next_cell_size):
		return
	state = next_state
	cell_size = next_cell_size
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
	var half_size := cell_size * 0.5
	draw_rect(Rect2(-half_size, -half_size, cell_size, cell_size), fill_color, true)
	draw_rect(Rect2(-half_size + 1.0, -half_size + 1.0, cell_size - 2.0, cell_size - 2.0), border_color, false, 1.5)
	if state == CursorState.BLOCKED:
		var mark_half_size := maxf(3.0, half_size - 4.0)
		draw_line(Vector2(-mark_half_size, -mark_half_size), Vector2(mark_half_size, mark_half_size), border_color, 1.25)
		draw_line(Vector2(mark_half_size, -mark_half_size), Vector2(-mark_half_size, mark_half_size), border_color, 1.25)
