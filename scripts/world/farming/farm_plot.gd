class_name FarmPlot
extends Node2D

enum PlotState { EMPTY, TILLED, PLANTED, GROWING, READY }

var state := PlotState.EMPTY
var watered := false
var growth_days := 0
var crop_id := ""
var crop_data: Dictionary = {}
var highlight_state := 0


func _ready() -> void:
	# 农田与地面同层，玩家使用更高显示层避免被耕地遮挡。
	z_index = 0
	add_to_group("mouse_action_targets")
	add_to_group("farm_plots")
	queue_redraw()


func set_mouse_highlight(hovered: bool, reachable: bool) -> void:
	var next_state := (1 if reachable else 2) if hovered else 0
	if next_state == highlight_state: return
	highlight_state = next_state
	queue_redraw()


func get_interaction_prompt() -> String:
	match state:
		PlotState.EMPTY: return "左键/长按使用石锄开垦"
		PlotState.TILLED: return "左键播种（先选择种子）"
		PlotState.PLANTED, PlotState.GROWING: return "左键浇水" if not watered else "%s今天已浇水" % get_crop_name()
		PlotState.READY: return "左键收获%s" % get_crop_name()
	return ""


func get_stamina_cost() -> float:
	match state:
		PlotState.EMPTY: return 6.0
		PlotState.TILLED: return 2.0
		PlotState.PLANTED, PlotState.GROWING: return 3.0 if not watered else 0.0
		PlotState.READY: return 4.0
	return 0.0


func can_interact(game: Node) -> bool:
	if state == PlotState.EMPTY and game.get_active_tool_type() != "hoe":
		game.show_message("需要先把石锄放入快捷栏并选中")
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
			game.show_message("土地已经开垦")
		PlotState.TILLED:
			_try_plant_selected_seed(game)
		PlotState.PLANTED, PlotState.GROWING:
			if not watered:
				game.player.play_tool_action("water")
				game.use_watering_can()
				watered = true
				game.show_message("给%s浇水完成，水壶剩余%d/%d" % [get_crop_name(), game.watering_can_water, game.WATERING_CAN_CAPACITY])
		PlotState.READY:
			_harvest(game)
	queue_redraw()


func advance_day() -> void:
	if state in [PlotState.PLANTED, PlotState.GROWING] and watered:
		growth_days += 1
		watered = false
		state = PlotState.READY if growth_days >= int(crop_data.get("growth_days", 2)) else PlotState.GROWING
		queue_redraw()


func water_from_rain() -> void:
	if state in [PlotState.PLANTED, PlotState.GROWING]:
		watered = true
		queue_redraw()


func create_save_data() -> Dictionary:
	return {"state": state, "watered": watered, "growth_days": growth_days, "crop_id": crop_id}


func restore_save_data(data: Dictionary, farming_system: FarmingSystem) -> void:
	state = int(data.get("state", PlotState.EMPTY))
	watered = bool(data.get("watered", false))
	growth_days = int(data.get("growth_days", 0))
	crop_id = str(data.get("crop_id", ""))
	crop_data = farming_system.get_crop_data(crop_id).duplicate(true) if not crop_id.is_empty() else {}
	queue_redraw()


func reset_for_new_game() -> void:
	state = PlotState.EMPTY
	watered = false
	growth_days = 0
	crop_id = ""
	crop_data = {}
	queue_redraw()


func get_crop_name() -> String:
	return crop_data.get("name", "作物")


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
	game.show_message("种下了%s" % get_crop_name())


func _harvest(game: Node) -> void:
	var harvest: Dictionary = crop_data.get("harvest", {})
	for item_id in harvest:
		game.add_resource(item_id, int(harvest[item_id]), false)
	game.show_message("收获%s：%s" % [get_crop_name(), game.format_cost(harvest)])
	state = PlotState.TILLED
	watered = false
	growth_days = 0
	crop_id = ""
	crop_data = {}


func _draw() -> void:
	if state == PlotState.EMPTY:
		draw_line(Vector2(-7, 8), Vector2(-5, 3), Color("#668b49"), 1.0)
		draw_line(Vector2(8, -4), Vector2(6, -9), Color("#668b49"), 1.0)
	elif state == PlotState.TILLED:
		draw_rect(Rect2(-14, -14, 28, 28), Color("#76523e"))
		for y in [-8, 0, 8]: draw_line(Vector2(-11, y), Vector2(11, y), Color("#a77b58"), 2.0)
	elif state in [PlotState.PLANTED, PlotState.GROWING, PlotState.READY]:
		draw_rect(Rect2(-14, -14, 28, 28), Color("#76523e"))
		var size := 4.0 + growth_days * 3.0
		var leaf_color := Color("#%s" % crop_data.get("leaf_color", "65a653"))
		var produce_color := Color("#%s" % crop_data.get("produce_color", "d5b061"))
		draw_line(Vector2(0, 8), Vector2(0, -size), Color("#417747"), 3.0)
		draw_circle(Vector2(-5, -size + 3), size * 0.55, leaf_color)
		draw_circle(Vector2(5, -size + 1), size * 0.55, leaf_color.lightened(0.08))
		if state == PlotState.READY: draw_circle(Vector2(0, 5), 6.0, produce_color)
	if watered: draw_circle(Vector2(10, -10), 3.0, Color("#68b9d2"))
	if highlight_state > 0:
		var highlight_color := Color(1.0, 0.88, 0.3, 0.28) if highlight_state == 1 else Color(0.95, 0.28, 0.25, 0.24)
		var border_color := Color("#ffe36b") if highlight_state == 1 else Color("#ee6158")
		draw_rect(Rect2(-15, -15, 30, 30), highlight_color, true)
		draw_rect(Rect2(-15, -15, 30, 30), border_color, false, 2.0)
