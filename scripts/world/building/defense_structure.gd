class_name DefenseStructure
extends StaticBody2D

var defense_type := "fence"
var max_health := 100.0
var health := 100.0
var upgrade_level := 1
var spike_damage := 10.0


func setup(type: String) -> void:
	collision_layer = 1
	collision_mask = 0
	defense_type = type
	if type == "spike": max_health = 60.0; health = 60.0
	add_to_group("defenses")
	add_to_group("interactables")
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(48, 20) if type == "fence" else Vector2(32, 32)
	collision.shape = rectangle
	add_child(collision)
	queue_redraw()


func take_damage(amount: float) -> void:
	health -= amount; queue_redraw()
	if health <= 0.0: queue_free()


func get_interaction_prompt() -> String:
	if health >= max_health:
		return "U 升级%s（等级%d）" % [get_display_name(), upgrade_level] if upgrade_level < 3 else ""
	var repair_prompt := "E 维修%s（%d/%d）" % [get_display_name(), int(health), int(max_health)]
	return repair_prompt + ("　U升级" if upgrade_level < 3 else "")


func get_stamina_cost() -> float:
	return 0.0


func interact(game: Node) -> void:
	if health >= max_health: return
	if game.get_active_tool_type() != "hammer":
		game.show_message("需要先在快捷栏选中维修锤")
		return
	var repair_cost := {"wood": 1} if defense_type == "fence" else {"wood": 1, "stone": 1}
	for item_id in repair_cost:
		if game.get_resource_amount(item_id) < int(repair_cost[item_id]):
			game.show_message("维修材料不足：%s" % game.format_cost(repair_cost))
			return
	if not game.player.try_spend_stamina(4.0):
		game.show_message("体力不足，无法维修")
		return
	for item_id in repair_cost:
		game.spend_resource(item_id, int(repair_cost[item_id]))
	health = minf(health + 40.0, max_health)
	game.show_message("维修完成，耐久恢复到%d/%d" % [int(health), int(max_health)])
	queue_redraw()


func get_item_id() -> String:
	return "wood_fence" if defense_type == "fence" else "wood_spike"


func get_display_name() -> String:
	return "木栅栏" if defense_type == "fence" else "木尖刺"


func apply_upgrade(new_level: int, upgrade_data: Dictionary) -> void:
	upgrade_level = clampi(new_level, 1, 3)
	max_health = float(upgrade_data.get("max_health", max_health))
	spike_damage = float(upgrade_data.get("spike_damage", spike_damage))
	health = max_health
	queue_redraw()


func try_dismantle(game: Node) -> bool:
	if game.get_active_tool_type() != "hammer":
		game.show_message("需要先在快捷栏选中维修锤")
		return false
	var item_id := get_item_id()
	if not game.can_add_resource(item_id, 1):
		game.show_message("背包已满，无法收回设施")
		return false
	if not game.player.try_spend_stamina(4.0):
		game.show_message("体力不足，无法拆除")
		return false
	game.add_resource(item_id, 1, false)
	game.show_message("已拆除并收回%s" % game.inventory.get_display_name(item_id))
	queue_free()
	return true



func _draw() -> void:
	if defense_type == "fence":
		draw_rect(Rect2(-24, -8, 48, 16), [Color("#765237"), Color("#846547"), Color("#66706d")][upgrade_level - 1])
		for x in [-18, 0, 18]: draw_rect(Rect2(x - 3, -13, 6, 26), Color("#9b7047"))
	else:
		for x in [-10, 0, 10]: draw_colored_polygon(PackedVector2Array([Vector2(x - 5, 13), Vector2(x, -14), Vector2(x + 5, 13)]), [Color("#a58a65"), Color("#b6a276"), Color("#9ca7a3")][upgrade_level - 1])
	draw_string(ThemeDB.fallback_font, Vector2(-5, 28), "Lv%d" % upgrade_level, HORIZONTAL_ALIGNMENT_CENTER, 18, 11, Color.WHITE)
	var ratio := clampf(health / max_health, 0.0, 1.0)
	if ratio < 1.0:
		draw_rect(Rect2(-15, -24, 30, 4), Color("#3b2625"))
		draw_rect(Rect2(-15, -24, 30 * ratio, 4), Color("#7cc35b"))
