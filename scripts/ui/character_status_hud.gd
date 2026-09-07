class_name CharacterStatusHUD
extends PanelContainer

@onready var day_time_label: Label = $Margin/Content/Header/DayTime
@onready var level_label: Label = $Margin/Content/Header/Level
@onready var health_bar: ProgressBar = $Margin/Content/Bars/Health/Bar
@onready var health_value: Label = $Margin/Content/Bars/Health/Value
@onready var stamina_bar: ProgressBar = $Margin/Content/Bars/Stamina/Bar
@onready var stamina_value: Label = $Margin/Content/Bars/Stamina/Value
@onready var hunger_bar: ProgressBar = $Margin/Content/Bars/Hunger/Bar
@onready var hunger_value: Label = $Margin/Content/Bars/Hunger/Value
@onready var thirst_bar: ProgressBar = $Margin/Content/Bars/Thirst/Bar
@onready var thirst_value: Label = $Margin/Content/Bars/Thirst/Value
@onready var experience_bar: ProgressBar = $Margin/Content/Experience/Bar
@onready var experience_value: Label = $Margin/Content/Experience/Value
@onready var equipment_label: Label = $Margin/Content/Equipment
@onready var warning_label: Label = $Margin/Content/Warning
@onready var buff_label: Label = $Margin/Content/Buff


func update_from_game(game: Node) -> void:
	var player: Player = game.player
	var total_minutes := int(game.day_progress * 1440.0)
	day_time_label.text = "第 %d 天　%02d:%02d" % [game.day, total_minutes / 60, total_minutes % 60]
	level_label.text = "等级 %d" % player.level
	_set_bar(health_bar, health_value, player.health, player.max_health)
	_set_bar(stamina_bar, stamina_value, player.stamina, player.max_stamina)
	_set_bar(hunger_bar, hunger_value, player.hunger, player.max_hunger)
	_set_bar(thirst_bar, thirst_value, player.thirst, player.max_thirst)
	_set_bar(experience_bar, experience_value, player.experience, player.get_next_level_experience())
	var home_health := int(game.homestead.health) if is_instance_valid(game.homestead) else 0
	var home_max := int(game.homestead.max_health) if is_instance_valid(game.homestead) else 0
	equipment_label.text = "武器：%s　农舍：%d/%d\n背包：%d/%d格　击杀：%d" % [player.equipped_weapon, home_health, home_max, game.inventory.get_used_slots(), game.inventory.slot_capacity, game.kills]
	var warnings: Array[String] = []
	if player.hunger <= 20.0:
		warnings.append("非常饥饿")
	if player.thirst <= 20.0:
		warnings.append("严重口渴")
	warning_label.visible = not warnings.is_empty()
	warning_label.text = "警告：%s" % " / ".join(warnings)
	var buffs: Array[String] = []
	if player.well_fed_time > 0.0:
		buffs.append("饱餐 %d秒" % int(ceil(player.well_fed_time)))
	if game.get_active_tool_type() == "watering_can":
		buffs.append("水壶 %d/%d" % [game.watering_can_water, game.WATERING_CAN_CAPACITY])
	buff_label.visible = not buffs.is_empty()
	buff_label.text = "　".join(buffs)


func _set_bar(bar: ProgressBar, value_label: Label, current: float, maximum: float) -> void:
	bar.max_value = maximum
	bar.value = current
	value_label.text = "%d/%d" % [int(current), int(maximum)]
