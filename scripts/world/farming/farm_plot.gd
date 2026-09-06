class_name FarmPlot
extends Node2D

enum PlotState { EMPTY, TILLED, PLANTED, GROWING, READY }

var state := PlotState.EMPTY
var watered := false
var growth_days := 0
var crop_id := ""
var crop_data: Dictionary = {}


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("farm_plots")
	queue_redraw()


func get_interaction_prompt() -> String:
	match state:
		PlotState.EMPTY: return "E 开垦土地"
		PlotState.TILLED: return "E 播种（先在快捷栏选择种子）"
		PlotState.PLANTED, PlotState.GROWING: return "E 浇水" if not watered else "%s今天已浇水" % get_crop_name()
		PlotState.READY: return "E 收获%s" % get_crop_name()
	return ""


func get_stamina_cost() -> float:
	match state:
		PlotState.EMPTY: return 6.0
		PlotState.TILLED: return 2.0
		PlotState.PLANTED, PlotState.GROWING: return 3.0 if not watered else 0.0
		PlotState.READY: return 4.0
	return 0.0


func interact(game: Node) -> void:
	match state:
		PlotState.EMPTY:
			state = PlotState.TILLED
			game.show_message("土地已经开垦")
		PlotState.TILLED:
			_try_plant_selected_seed(game)
		PlotState.PLANTED, PlotState.GROWING:
			if not watered:
				watered = true
				game.show_message("给%s浇水完成" % get_crop_name())
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
	draw_rect(Rect2(-14, -14, 28, 28), Color("#76523e"))
	if state == PlotState.EMPTY:
		draw_line(Vector2(-10, 0), Vector2(10, 0), Color("#99745a"), 2.0)
	elif state == PlotState.TILLED:
		for y in [-8, 0, 8]: draw_line(Vector2(-11, y), Vector2(11, y), Color("#a77b58"), 2.0)
	elif state in [PlotState.PLANTED, PlotState.GROWING, PlotState.READY]:
		var size := 4.0 + growth_days * 3.0
		var leaf_color := Color("#%s" % crop_data.get("leaf_color", "65a653"))
		var produce_color := Color("#%s" % crop_data.get("produce_color", "d5b061"))
		draw_line(Vector2(0, 8), Vector2(0, -size), Color("#417747"), 3.0)
		draw_circle(Vector2(-5, -size + 3), size * 0.55, leaf_color)
		draw_circle(Vector2(5, -size + 1), size * 0.55, leaf_color.lightened(0.08))
		if state == PlotState.READY: draw_circle(Vector2(0, 5), 6.0, produce_color)
	if watered: draw_circle(Vector2(10, -10), 3.0, Color("#68b9d2"))
