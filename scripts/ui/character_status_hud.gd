class_name CharacterStatusHUD
extends PanelContainer

@onready var day_time_label: Label = $Margin/Content/Header/DayTime
@onready var level_label: Label = $Margin/Content/Header/Level
@onready var health_bar: ProgressBar = $Margin/Content/Vitals/Health/Bar
@onready var stamina_bar: ProgressBar = $Margin/Content/Vitals/Stamina/Bar
@onready var hunger_bar: ProgressBar = $Margin/Content/Vitals/Hunger/Bar
@onready var thirst_bar: ProgressBar = $Margin/Content/Vitals/Thirst/Bar
@onready var experience_bar: ProgressBar = $Margin/Content/Experience/Bar
@onready var context_label: Label = $Margin/Content/Header/Context


func update_from_game(game: Node) -> void:
	var player: Player = game.player
	var total_minutes := int(game.day_progress * 1440.0)
	day_time_label.text = "第 %d 天　%02d:%02d" % [game.day, total_minutes / 60, total_minutes % 60]
	level_label.text = "等级 %d" % player.level
	_set_bar(health_bar, player.health, player.max_health)
	_set_bar(stamina_bar, player.stamina, player.max_stamina)
	_set_bar(hunger_bar, player.hunger, player.max_hunger)
	_set_bar(thirst_bar, player.thirst, player.max_thirst)
	_set_bar(experience_bar, player.experience, player.get_next_level_experience())
	var context_parts: Array[String] = []
	if player.hunger <= 20.0:
		context_parts.append("饥饿")
	if player.thirst <= 20.0:
		context_parts.append("口渴")
	if player.well_fed_time > 0.0:
		context_parts.append("饱餐 %d秒" % int(ceil(player.well_fed_time)))
	if game.get_active_tool_type() == "watering_can":
		context_parts.append("水壶 %d/%d" % [game.watering_can_water, game.watering_can_capacity])
	context_label.visible = not context_parts.is_empty()
	context_label.text = "　".join(context_parts)


func _set_bar(bar: ProgressBar, current: float, maximum: float) -> void:
	bar.max_value = maximum
	bar.value = current
	bar.tooltip_text = "%d / %d" % [int(current), int(maximum)]
