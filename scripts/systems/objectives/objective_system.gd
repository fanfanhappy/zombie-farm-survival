class_name ObjectiveSystem
extends Node

signal objective_text_changed(text: String)
signal objective_completed(title: String, reward_text: String)

const OBJECTIVE_DATA_PATH := "res://data/objectives/first_week_objectives.json"

var objectives: Array = []
var current_index := 0
var completed_ids: Array[String] = []
var game_world: Node
var evaluation_time := 0.0


func _ready() -> void:
	_load_objectives()


func _process(delta: float) -> void:
	if game_world == null or current_index >= objectives.size(): return
	evaluation_time -= delta
	if evaluation_time > 0.0: return
	evaluation_time = 0.2
	if _is_current_objective_complete(): _complete_current_objective()
	_emit_current_text()


func setup(game: Node) -> void:
	game_world = game
	_emit_current_text()


func create_save_data() -> Dictionary:
	return {"current_index": current_index, "completed_ids": completed_ids.duplicate()}


func reset_for_new_game() -> void:
	current_index = 0
	completed_ids.clear()
	evaluation_time = 0.0
	_emit_current_text()


func restore_save_data(data: Dictionary) -> void:
	current_index = clampi(int(data.get("current_index", 0)), 0, objectives.size())
	completed_ids.clear()
	for objective_id in data.get("completed_ids", []): completed_ids.append(str(objective_id))
	_emit_current_text()


func _is_current_objective_complete() -> bool:
	var objective: Dictionary = objectives[current_index]
	var condition: Dictionary = objective.get("condition", {})
	var current_value: int = game_world.get_objective_metric(str(condition.get("type", "")), str(condition.get("target", "")))
	return current_value >= int(condition.get("amount", 1))


func _complete_current_objective() -> void:
	var objective: Dictionary = objectives[current_index]
	var reward: Dictionary = objective.get("reward", {})
	for item_id in reward:
		game_world.add_resource(item_id, int(reward[item_id]), false)
	completed_ids.append(str(objective.get("id", "objective_%d" % current_index)))
	current_index += 1
	objective_completed.emit(str(objective.get("title", "目标完成")), game_world.format_cost(reward))


func _emit_current_text() -> void:
	if objectives.is_empty():
		objective_text_changed.emit("")
	elif current_index >= objectives.size():
		objective_text_changed.emit("第一周目标已全部完成")
	else:
		var objective: Dictionary = objectives[current_index]
		var condition: Dictionary = objective.get("condition", {})
		var current_value: int = game_world.get_objective_metric(str(condition.get("type", "")), str(condition.get("target", ""))) if game_world else 0
		var amount := int(condition.get("amount", 1))
		objective_text_changed.emit("当前目标：%s　%d/%d" % [objective.get("title", ""), mini(current_value, amount), amount])


func _load_objectives() -> void:
	if not FileAccess.file_exists(OBJECTIVE_DATA_PATH):
		push_error("目标数据不存在：%s" % OBJECTIVE_DATA_PATH)
		return
	var file := FileAccess.open(OBJECTIVE_DATA_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Array: objectives = parsed
	else: push_error("目标数据格式无效：%s" % OBJECTIVE_DATA_PATH)
