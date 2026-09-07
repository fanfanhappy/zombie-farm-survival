class_name HarvestableResource
extends StaticBody2D

@export_enum("wood", "stone", "herb") var resource_type := "wood"
var display_name := "树木"
var yield_amount := 3
var depleted := false
var work_required := 3.0
var work_remaining := 3.0
@onready var resource_sprite: Sprite2D = $ResourceSprite
@onready var depleted_sprite: Sprite2D = $DepletedSprite
@onready var work_progress: ProgressBar = $WorkProgress


func setup(type: String) -> void:
	resource_type = type
	match type:
		"wood": display_name = "树木"; yield_amount = 4; work_required = 3.0
		"stone": display_name = "石块"; yield_amount = 3; work_required = 4.0
		"herb": display_name = "草药"; yield_amount = 2; work_required = 1.0
	work_remaining = work_required
	add_to_group("mouse_action_targets")
	_update_visual_state()


func get_interaction_prompt() -> String:
	if depleted: return ""
	var progress := int((1.0 - work_remaining / work_required) * 100.0)
	return "左键/长按采集%s%s" % [display_name, "（%d%%）" % progress if progress > 0 else ""]


func can_mouse_interact(game: Node) -> bool:
	var required_tool := "axe" if resource_type == "wood" else ("pickaxe" if resource_type == "stone" else "")
	if not required_tool.is_empty() and game.get_active_tool_type() != required_tool:
		game.show_message("砍树需要选中石斧" if resource_type == "wood" else "采石需要选中石镐")
		return false
	return true


func get_stamina_cost() -> float:
	return 8.0 if resource_type != "herb" else 3.0


func interact(game: Node) -> void:
	if depleted: return
	if resource_type == "wood": game.player.play_tool_action("axe")
	var tool_type: String = game.get_active_tool_type()
	var correct_tool := (resource_type == "wood" and tool_type == "axe") or (resource_type == "stone" and tool_type == "pickaxe")
	var work_amount := 2.0 if correct_tool else 1.0
	work_remaining = maxf(work_remaining - work_amount, 0.0)
	if work_remaining > 0.0:
		game.show_message("采集中：%s %d%%%s" % [display_name, int((1.0 - work_remaining / work_required) * 100.0), "（工具效率提升）" if correct_tool else ""])
	else:
		depleted = true
		game.add_resource(resource_type, yield_amount)
		remove_from_group("mouse_action_targets")
		get_tree().create_timer(20.0).timeout.connect(_respawn)
	_update_visual_state()


func _respawn() -> void:
	depleted = false
	work_remaining = work_required
	add_to_group("mouse_action_targets")
	_update_visual_state()


func _update_visual_state() -> void:
	if not is_instance_valid(resource_sprite):
		return
	resource_sprite.visible = not depleted
	depleted_sprite.visible = depleted
	work_progress.max_value = work_required
	work_progress.value = work_remaining
	work_progress.visible = not depleted and work_remaining < work_required
