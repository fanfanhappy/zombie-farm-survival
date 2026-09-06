class_name HarvestableResource
extends StaticBody2D

var resource_type := "wood"
var display_name := "树木"
var yield_amount := 3
var depleted := false
var work_required := 3.0
var work_remaining := 3.0


func setup(type: String) -> void:
	# 草药可踩过；树木和矿石会阻挡玩家，但不会卡住僵尸。
	collision_layer = 0 if type == "herb" else 2
	collision_mask = 0
	resource_type = type
	match type:
		"wood": display_name = "树木"; yield_amount = 4; work_required = 3.0
		"stone": display_name = "石块"; yield_amount = 3; work_required = 4.0
		"herb": display_name = "草药"; yield_amount = 2; work_required = 1.0
	work_remaining = work_required
	add_to_group("interactables")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 15.0 if type == "wood" else (17.0 if type == "stone" else 8.0)
	shape.shape = circle
	add_child(shape)
	queue_redraw()


func get_interaction_prompt() -> String:
	if depleted: return ""
	var progress := int((1.0 - work_remaining / work_required) * 100.0)
	return "E 采集%s%s" % [display_name, "（%d%%）" % progress if progress > 0 else ""]


func get_stamina_cost() -> float:
	return 8.0 if resource_type != "herb" else 3.0


func interact(game: Node) -> void:
	if depleted: return
	var tool_type: String = game.get_active_tool_type()
	var correct_tool := (resource_type == "wood" and tool_type == "axe") or (resource_type == "stone" and tool_type == "pickaxe")
	var work_amount := 2.0 if correct_tool else 1.0
	work_remaining = maxf(work_remaining - work_amount, 0.0)
	if work_remaining > 0.0:
		game.show_message("采集中：%s %d%%%s" % [display_name, int((1.0 - work_remaining / work_required) * 100.0), "（工具效率提升）" if correct_tool else ""])
	else:
		depleted = true
		game.add_resource(resource_type, yield_amount)
		remove_from_group("interactables")
		get_tree().create_timer(20.0).timeout.connect(_respawn)
	queue_redraw()


func _respawn() -> void:
	depleted = false
	work_remaining = work_required
	add_to_group("interactables")
	queue_redraw()


func _draw() -> void:
	if depleted:
		draw_circle(Vector2.ZERO, 8.0, Color("#665444")); return
	match resource_type:
		"wood":
			draw_rect(Rect2(-5, 8, 10, 25), Color("#684b36"))
			draw_circle(Vector2(0, -2), 24.0, Color("#386641"))
			draw_circle(Vector2(-12, -9), 15.0, Color("#4f7d45"))
		"stone":
			draw_colored_polygon(PackedVector2Array([Vector2(-19, 11), Vector2(-11, -13), Vector2(12, -17), Vector2(22, 7), Vector2(10, 17)]), Color("#718078"))
		"herb":
			for angle in [0.0, 1.57, 3.14, 4.71]: draw_circle(Vector2.from_angle(angle) * 9.0, 7.0, Color("#63a758"))
			draw_circle(Vector2.ZERO, 4.0, Color("#e1d16f"))
	if work_remaining < work_required:
		var ratio := work_remaining / work_required
		draw_rect(Rect2(-20, -36, 40, 5), Color("#33282a"))
		draw_rect(Rect2(-20, -36, 40 * ratio, 5), Color("#e0b85e"))
