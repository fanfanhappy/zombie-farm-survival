class_name FarmPlot
extends Node2D

signal plot_state_changed

const DEFAULT_ACTION_SETTINGS := preload("res://resources/settings/farming_action_settings.tres")

enum PlotState { EMPTY, TILLED, PLANTED, GROWING, READY, WITHERED }
enum DayResult { NONE, GREW, READY_TO_HARVEST, MISSED_WATER, WITHERED }

const CELL_SIZE := WorldGrid.CELL_SIZE
var state := PlotState.EMPTY
var watered := false
var growth_days := 0
var dry_days := 0
var crop_id := ""
var crop_data: Dictionary = {}
var highlight_state := 0
var crop_visual: CropVisual

@export_group("格子高亮")
@export var reachable_fill_color := Color(1.0, 0.88, 0.3, 0.28)
@export var reachable_border_color := Color("#ffe36b")
@export var blocked_fill_color := Color(0.95, 0.28, 0.25, 0.24)
@export var blocked_border_color := Color("#ee6158")
@export_group("玩法设置")
@export var action_settings: FarmingActionSettings = DEFAULT_ACTION_SETTINGS


func _ready() -> void:
	# 农田与地面同层，玩家使用更高显示层避免被耕地遮挡。
	z_index = 0
	add_to_group("mouse_action_targets")
	add_to_group("farm_plots")
	_refresh_crop_visual()
	_refresh_state_visuals()


func set_mouse_highlight(hovered: bool, reachable: bool) -> void:
	var next_state := (1 if reachable else 2) if hovered else 0
	if next_state == highlight_state: return
	highlight_state = next_state
	_refresh_state_visuals()


func get_interaction_prompt() -> String:
	match state:
		PlotState.EMPTY: return "左键/长按使用石锄开垦"
		PlotState.TILLED: return "左键播种（先选择种子）"
		PlotState.PLANTED, PlotState.GROWING:
			var progress := "%s · 生长 %d/%d天" % [get_crop_name(), growth_days, get_required_growth_days()]
			if watered: return "%s · 今日已浇水，明日生长" % progress
			return "%s · 缺水%d/%d天 · 左键浇水" % [progress, dry_days, get_dry_tolerance_days()]
		PlotState.READY: return "%s已成熟 · 左键收获" % get_crop_name()
		PlotState.WITHERED: return "%s已枯萎 · 选择石锄清理" % get_crop_name()
	return ""


func get_stamina_cost() -> float:
	match state:
		PlotState.EMPTY: return action_settings.till_cost
		PlotState.TILLED: return action_settings.plant_cost
		PlotState.PLANTED, PlotState.GROWING: return action_settings.water_cost if not watered else 0.0
		PlotState.READY: return action_settings.harvest_cost
		PlotState.WITHERED: return action_settings.clear_withered_cost
	return 0.0


func can_interact(game: Node) -> bool:
	if state == PlotState.EMPTY and game.get_active_tool_type() != "hoe":
		game.show_message("需要先把石锄放入快捷栏并选中")
		return false
	if state == PlotState.WITHERED and game.get_active_tool_type() != "hoe":
		game.show_message("作物已经枯萎，需要选择石锄清理")
		return false
	if state == PlotState.TILLED:
		var selected_item_id: String = game.get_selected_hotbar_item_id()
		if selected_item_id.is_empty() or game.inventory.get_item_data(selected_item_id).get("category", "") != "seed":
			game.show_message("需要先把种子放入快捷栏并选中")
			return false
	if state in [PlotState.PLANTED, PlotState.GROWING]:
		if watered:
			game.show_message("%s今天已经浇过水了" % get_crop_name())
			return false
		if not game.can_water_crop(): return false
	return true


func interact(game: Node) -> void:
	match state:
		PlotState.EMPTY:
			game.player.play_tool_action("hoe")
			state = PlotState.TILLED
			game.show_message("土地已经开垦%s" % _grant_experience(game, action_settings.till_experience))
		PlotState.TILLED:
			_try_plant_selected_seed(game)
		PlotState.PLANTED, PlotState.GROWING:
			if not watered:
				game.player.play_tool_action("water")
				game.use_watering_can()
				watered = true
				dry_days = 0
				game.show_message("给%s浇水完成，水壶剩余%d/%d%s" % [get_crop_name(), game.watering_can_water, game.watering_can_capacity, _grant_experience(game, action_settings.water_experience)])
		PlotState.READY:
			_harvest(game)
		PlotState.WITHERED:
			game.player.play_tool_action("hoe")
			var withered_name := get_crop_name()
			_clear_crop(PlotState.TILLED)
			game.show_message("已清理枯萎的%s，可以重新播种" % withered_name)
	_refresh_crop_visual()
	_refresh_state_visuals()
	plot_state_changed.emit()


func advance_day() -> DayResult:
	if state not in [PlotState.PLANTED, PlotState.GROWING]:
		return DayResult.NONE
	var result := DayResult.NONE
	if watered:
		growth_days += 1
		dry_days = 0
		watered = false
		state = PlotState.READY if growth_days >= get_required_growth_days() else PlotState.GROWING
		result = DayResult.READY_TO_HARVEST if state == PlotState.READY else DayResult.GREW
	else:
		dry_days += 1
		if dry_days >= get_dry_tolerance_days():
			state = PlotState.WITHERED
			result = DayResult.WITHERED
		else:
			result = DayResult.MISSED_WATER
	_refresh_crop_visual()
	_refresh_state_visuals()
	plot_state_changed.emit()
	return result


func water_from_rain() -> bool:
	if state not in [PlotState.PLANTED, PlotState.GROWING]:
		return false
	watered = true
	dry_days = 0
	_refresh_state_visuals()
	plot_state_changed.emit()
	return true


func create_save_data() -> Dictionary:
	var cell := WorldGrid.world_to_cell(global_position)
	return {"cell_x": cell.x, "cell_y": cell.y, "state": state, "watered": watered, "growth_days": growth_days, "dry_days": dry_days, "crop_id": crop_id}


func restore_save_data(data: Dictionary, farming_system: FarmingSystem) -> void:
	state = clampi(int(data.get("state", PlotState.EMPTY)), PlotState.EMPTY, PlotState.WITHERED)
	watered = bool(data.get("watered", false))
	growth_days = maxi(int(data.get("growth_days", 0)), 0)
	dry_days = maxi(int(data.get("dry_days", 0)), 0)
	crop_id = str(data.get("crop_id", ""))
	crop_data = farming_system.get_crop_data(crop_id).duplicate(true) if not crop_id.is_empty() else {}
	if state in [PlotState.PLANTED, PlotState.GROWING, PlotState.READY, PlotState.WITHERED] and crop_data.is_empty():
		_clear_crop(PlotState.TILLED)
	elif state in [PlotState.EMPTY, PlotState.TILLED]:
		_clear_crop(state)
	_refresh_crop_visual()
	_refresh_state_visuals()
	plot_state_changed.emit()


func reset_for_new_game() -> void:
	state = PlotState.EMPTY
	watered = false
	growth_days = 0
	dry_days = 0
	crop_id = ""
	crop_data = {}
	_refresh_crop_visual()
	_refresh_state_visuals()
	plot_state_changed.emit()


func get_crop_name() -> String:
	return crop_data.get("name", "作物")


func get_required_growth_days() -> int:
	return maxi(int(crop_data.get("growth_days", 1)), 1)


func get_dry_tolerance_days() -> int:
	return maxi(int(crop_data.get("dry_tolerance_days", 2)), 1)


func _try_plant_selected_seed(game: Node) -> void:
	var seed_item_id: String = game.get_selected_hotbar_item_id()
	if seed_item_id.is_empty():
		game.show_message("请先把种子放入快捷栏并选中")
		return
	var item_data: Dictionary = game.inventory.get_item_data(seed_item_id)
	var selected_crop_id: String = game.farming_system.get_crop_from_seed(item_data)
	if selected_crop_id.is_empty():
		game.show_message("当前选中的不是种子")
		return
	if not game.spend_resource(seed_item_id, 1):
		game.show_message("种子数量不足")
		return
	crop_id = selected_crop_id
	crop_data = game.farming_system.get_crop_data(crop_id).duplicate(true)
	state = PlotState.PLANTED
	watered = false
	growth_days = 0
	dry_days = 0
	_refresh_crop_visual()
	game.show_message("种下了%s，记得今天浇水%s" % [get_crop_name(), _grant_experience(game, action_settings.plant_experience)])


func _harvest(game: Node) -> void:
	var harvest: Dictionary = crop_data.get("harvest", {})
	var overflow := 0
	for item_id in harvest:
		var amount := int(harvest[item_id])
		overflow += amount - int(game.add_resource(item_id, amount, false))
	var crop_name := get_crop_name()
	var experience := int(crop_data.get("harvest_experience", 0))
	_clear_crop(PlotState.TILLED)
	var overflow_text := "，背包溢出的收获已掉在脚边" if overflow > 0 else ""
	game.show_message("收获%s：%s%s%s" % [crop_name, game.format_cost(harvest), _grant_experience(game, experience), overflow_text])


func _clear_crop(next_state: PlotState) -> void:
	state = next_state
	watered = false
	growth_days = 0
	dry_days = 0
	crop_id = ""
	crop_data = {}
	_refresh_crop_visual()


func _grant_experience(game: Node, amount: int) -> String:
	if amount <= 0 or not is_instance_valid(game.player):
		return ""
	var leveled_up: bool = game.player.add_experience(amount)
	return "，经验+%d%s" % [amount, "，升级至%d级" % game.player.level if leveled_up else ""]


func _refresh_crop_visual() -> void:
	if is_instance_valid(crop_visual):
		crop_visual.queue_free()
		crop_visual = null
	if crop_id.is_empty():
		return
	var visual_scene := crop_data.get("visual_scene") as PackedScene
	if visual_scene == null:
		return
	crop_visual = visual_scene.instantiate() as CropVisual
	add_child(crop_visual)
	if state == PlotState.WITHERED:
		crop_visual.show_withered()
		return
	var stage := 0
	if state == PlotState.READY:
		stage = 4
	elif state == PlotState.GROWING:
		stage = clampi(ceili(float(growth_days) / float(get_required_growth_days()) * 3.0), 1, 3)
	crop_visual.show_stage(stage)


func _refresh_state_visuals() -> void:
	var water_marker := get_node_or_null("StatusVisuals/WateredIndicator") as CanvasItem
	if water_marker:
		water_marker.visible = watered
	var highlight := get_node_or_null("Highlight") as CanvasItem
	if not highlight:
		return
	highlight.visible = highlight_state > 0
	var reachable := highlight_state == 1
	var fill := highlight.get_node("Fill") as Polygon2D
	var border := highlight.get_node("Border") as Line2D
	fill.color = reachable_fill_color if reachable else blocked_fill_color
	border.default_color = reachable_border_color if reachable else blocked_border_color
