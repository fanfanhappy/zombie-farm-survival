class_name WorldGridCursor
extends Node2D

enum CursorState { HIDDEN, INTERACTABLE, OUT_OF_REACH, BLOCKED }

var state := CursorState.HIDDEN
var cell_size := WorldGrid.CELL_SIZE

@export_group("可交互")
@export var interactable_fill := Color(0.35, 0.9, 0.42, 0.22)
@export var interactable_border := Color("#75ed7d")
@export_group("超出距离")
@export var out_of_reach_fill := Color(1.0, 0.72, 0.2, 0.2)
@export var out_of_reach_border := Color("#ffc45c")
@export_group("不可操作")
@export var blocked_fill := Color(0.95, 0.25, 0.22, 0.18)
@export var blocked_border := Color("#f06a63")

@onready var fill: Polygon2D = $Fill
@onready var border: Line2D = $Border
@onready var blocked_mark: Node2D = $BlockedMark


func set_cursor(at_position: Vector2, next_state: CursorState, next_cell_size := WorldGrid.CELL_SIZE) -> void:
	position = at_position
	visible = next_state != CursorState.HIDDEN
	if state == next_state and is_equal_approx(cell_size, next_cell_size):
		return
	state = next_state
	cell_size = next_cell_size
	scale = Vector2.ONE * (cell_size / WorldGrid.CELL_SIZE)
	var fill_color := interactable_fill
	var border_color := interactable_border
	match state:
		CursorState.OUT_OF_REACH:
			fill_color = out_of_reach_fill
			border_color = out_of_reach_border
		CursorState.BLOCKED:
			fill_color = blocked_fill
			border_color = blocked_border
	fill.color = fill_color
	border.default_color = border_color
	blocked_mark.visible = state == CursorState.BLOCKED
	for line in blocked_mark.get_children():
		(line as Line2D).default_color = border_color
