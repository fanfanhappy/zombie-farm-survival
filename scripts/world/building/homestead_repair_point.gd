class_name HomesteadRepairPoint
extends Node2D

var homestead: HomesteadCore


func setup(home: HomesteadCore) -> void:
	homestead = home
	add_to_group("interactables")
	queue_redraw()


func get_interaction_prompt() -> String:
	if not is_instance_valid(homestead) or homestead.health >= homestead.max_health: return ""
	return "E 维修农舍（%d/%d）" % [int(homestead.health), int(homestead.max_health)]


func get_stamina_cost() -> float:
	return 0.0


func interact(game: Node) -> void:
	if homestead.health >= homestead.max_health: return
	if game.get_active_tool_type() != "hammer":
		game.show_message("需要先在快捷栏选中维修锤")
		return
	var cost := {"wood": 2, "stone": 1}
	for item_id in cost:
		if game.get_resource_amount(item_id) < int(cost[item_id]):
			game.show_message("维修农舍需要%s" % game.format_cost(cost))
			return
	if not game.player.try_spend_stamina(6.0):
		game.show_message("体力不足，无法维修农舍")
		return
	for item_id in cost:
		game.spend_resource(item_id, int(cost[item_id]))
	homestead.repair(55.0)
	game.show_message("农舍耐久恢复到%d/%d" % [int(homestead.health), int(homestead.max_health)])


func _draw() -> void:
	draw_rect(Rect2(-17, -10, 34, 20), Color("#8a6845"))
	draw_rect(Rect2(-8, -17, 16, 7), Color("#9e815f"))
	draw_circle(Vector2(0, 0), 4.0, Color("#d8c07d"))
