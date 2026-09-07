class_name HarvestableResource
extends StaticBody2D

@export_enum("wood", "stone", "herb") var resource_type := "wood"
var display_name := "树木"
var yield_amount := 3
var depleted := false
var breaking := false
var work_required := 3.0
var work_remaining := 3.0
@onready var resource_animation: AnimatedSprite2D = get_node_or_null("ResourceAnimation") as AnimatedSprite2D
@onready var resource_sprite: Sprite2D = get_node_or_null("ResourceSprite") as Sprite2D
@onready var depleted_sprite: Sprite2D = get_node_or_null("DepletedSprite") as Sprite2D
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
@onready var work_progress: ProgressBar = $WorkProgress


func _ready() -> void:
	# 支持从TileSet场景集合直接绘制生成，不再依赖主控制器额外初始化。
	add_to_group("harvestable_resources")
	setup(resource_type)


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
	if depleted or breaking: return ""
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
	if depleted or breaking: return
	if resource_type == "wood": game.player.play_tool_action("axe")
	var tool_type: String = game.get_active_tool_type()
	var correct_tool := (resource_type == "wood" and tool_type == "axe") or (resource_type == "stone" and tool_type == "pickaxe")
	var work_amount := 2.0 if correct_tool else 1.0
	work_remaining = maxf(work_remaining - work_amount, 0.0)
	if work_remaining > 0.0:
		_play_hit_animation()
		game.show_message("采集中：%s %d%%%s" % [display_name, int((1.0 - work_remaining / work_required) * 100.0), "（工具效率提升）" if correct_tool else ""])
	else:
		_finish_harvest(game)
	_update_visual_state()


func _play_hit_animation() -> void:
	if not is_instance_valid(resource_animation) or not resource_animation.sprite_frames.has_animation(&"hit"):
		return
	resource_animation.play(&"hit")
	await resource_animation.animation_finished
	if not breaking and not depleted:
		resource_animation.play(&"idle")


func _finish_harvest(game: Node) -> void:
	breaking = true
	remove_from_group("mouse_action_targets")
	work_progress.visible = false
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)
	game.show_message("%s正在被破坏……" % display_name)
	if is_instance_valid(resource_animation) and resource_animation.sprite_frames.has_animation(&"break"):
		resource_animation.play(&"break")
		await resource_animation.animation_finished
	depleted = true
	breaking = false
	if is_instance_valid(resource_animation) and resource_animation.sprite_frames.has_animation(&"depleted"):
		resource_animation.play(&"depleted")
	game.add_resource(resource_type, yield_amount)
	get_tree().create_timer(20.0).timeout.connect(_respawn)
	_update_visual_state()


func _respawn() -> void:
	depleted = false
	breaking = false
	work_remaining = work_required
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", false)
	add_to_group("mouse_action_targets")
	if is_instance_valid(resource_animation):
		resource_animation.play(&"idle")
	_update_visual_state()


func _update_visual_state() -> void:
	if is_instance_valid(resource_sprite):
		resource_sprite.visible = not depleted
	if is_instance_valid(depleted_sprite):
		depleted_sprite.visible = depleted
	work_progress.max_value = work_required
	work_progress.value = work_remaining
	work_progress.visible = not depleted and not breaking and work_remaining < work_required
