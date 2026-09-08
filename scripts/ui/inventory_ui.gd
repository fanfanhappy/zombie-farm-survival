class_name InventoryUI
extends Control

signal item_use_requested(item_id: String)
signal item_drop_requested(item_id: String)
signal inventory_closed

const ITEM_SLOT_SCENE := preload("res://scenes/ui/components/draggable_item_slot.tscn")
const DEFAULT_VISUAL_STYLE := preload("res://resources/themes/inventory_visual_style.tres")

@export var visual_style: Resource = DEFAULT_VISUAL_STYLE


@onready var hotbar: HBoxContainer = $HotbarPanel/Margin/Hotbar
@onready var backpack_panel: PanelContainer = $BackpackPanel
@onready var capacity_label: Label = $BackpackPanel/Margin/Content/Header/Capacity
@onready var item_grid: GridContainer = $BackpackPanel/Margin/Content/Body/LeftColumn/ItemScroll/ItemGrid
@onready var search_input: LineEdit = $BackpackPanel/Margin/Content/Body/LeftColumn/FilterBar/Search
@onready var category_filter: OptionButton = $BackpackPanel/Margin/Content/Body/LeftColumn/FilterBar/Category
@onready var detail_name: Label = $BackpackPanel/Margin/Content/Body/DetailPanel/Margin/Detail/ItemName
@onready var detail_description: Label = $BackpackPanel/Margin/Content/Body/DetailPanel/Margin/Detail/Description
@onready var use_button: Button = $BackpackPanel/Margin/Content/Body/DetailPanel/Margin/Detail/UseButton
@onready var drop_button: Button = $BackpackPanel/Margin/Content/Body/DetailPanel/Margin/Detail/DropButton

var inventory: InventorySystem
var selected_item_id := ""
var selected_hotbar_index := -1
var category_ids: Array[String] = ["", "weapon", "tool", "placeable", "material", "ingredient", "seed", "consumable"]


func setup(inventory_system: InventorySystem) -> void:
	inventory = inventory_system
	_apply_inventory_theme()
	inventory.inventory_changed.connect(refresh)
	$BackpackPanel/Margin/Content/Header/CloseButton.pressed.connect(close_backpack)
	use_button.pressed.connect(_on_use_pressed)
	drop_button.pressed.connect(_on_drop_pressed)
	search_input.text_changed.connect(_on_filter_changed.unbind(1))
	search_input.gui_input.connect(_on_search_gui_input)
	category_filter.item_selected.connect(_on_filter_changed.unbind(1))
	_setup_category_filter()
	refresh()


func toggle_backpack() -> void:
	if backpack_panel.visible: close_backpack()
	else: open_backpack()


func open_backpack() -> void:
	backpack_panel.visible = true
	refresh()
	search_input.grab_focus()


func close_backpack() -> void:
	backpack_panel.visible = false
	inventory_closed.emit()


func is_backpack_open() -> bool:
	return backpack_panel.visible


func refresh() -> void:
	if inventory == null: return
	_refresh_hotbar()
	if backpack_panel.visible:
		_refresh_backpack()


func handle_hotbar_drop(target_index: int, data: Dictionary) -> void:
	if data.get("source", "") == "hotbar":
		inventory.swap_hotbar_slots(int(data.get("slot_index", -1)), target_index)
	else:
		inventory.assign_hotbar_item(target_index, str(data.get("item_id", "")))
	selected_hotbar_index = target_index
	refresh()


func clear_hotbar_slot(slot_index: int) -> void:
	inventory.clear_hotbar_slot(slot_index)
	if selected_hotbar_index == slot_index: selected_hotbar_index = -1
	refresh()


func activate_hotbar_slot(slot_index: int) -> bool:
	var item_id := inventory.get_hotbar_item(slot_index)
	selected_hotbar_index = slot_index
	refresh()
	if item_id.is_empty() or inventory.get_amount(item_id) <= 0:
		return false
	item_use_requested.emit(item_id)
	return true


func get_selected_hotbar_item_id() -> String:
	if selected_hotbar_index < 0: return ""
	return inventory.get_hotbar_item(selected_hotbar_index)


func cycle_hotbar(direction: int) -> bool:
	if inventory == null or inventory.hotbar_capacity <= 0:
		return false
	var start_index := selected_hotbar_index
	if start_index < 0:
		start_index = -1 if direction > 0 else 0
	for step in inventory.hotbar_capacity:
		var candidate := posmod(start_index + direction * (step + 1), inventory.hotbar_capacity)
		if not inventory.get_hotbar_item(candidate).is_empty():
			return activate_hotbar_slot(candidate)
	return false


func reset_selection() -> void:
	selected_item_id = ""
	selected_hotbar_index = -1
	search_input.text = ""
	category_filter.select(0)
	refresh()


func _refresh_hotbar() -> void:
	_clear_container(hotbar)
	for index in inventory.hotbar_capacity:
		var item_id := inventory.get_hotbar_item(index)
		var slot := ITEM_SLOT_SCENE.instantiate() as DraggableItemSlot
		slot.configure(self, "hotbar", index, item_id)
		if item_id.is_empty():
			slot.set_visual(null, 0, str(index + 1), selected_hotbar_index == index)
			slot.tooltip_text = "从背包拖动物品到这里"
		else:
			slot.set_visual(get_item_icon(item_id), inventory.get_amount(item_id), str(index + 1), selected_hotbar_index == index)
			slot.tooltip_text = "%s\n右键清空快捷槽" % inventory.get_item_data(item_id).get("description", "")
			slot.pressed.connect(_on_hotbar_slot_pressed.bind(item_id))
		hotbar.add_child(slot)


func _refresh_backpack() -> void:
	capacity_label.text = "%d / %d 格" % [inventory.get_used_slots(), inventory.slot_capacity]
	_clear_container(item_grid)
	var item_ids := _get_filtered_item_ids()
	for item_id in item_ids:
		var data := inventory.get_item_data(item_id)
		var slot := ITEM_SLOT_SCENE.instantiate() as DraggableItemSlot
		slot.configure(self, "inventory", -1, item_id)
		slot.set_visual(get_item_icon(item_id), inventory.get_amount(item_id), "", selected_item_id == item_id)
		slot.tooltip_text = "%s\n拖动到下方快捷栏" % data.get("description", "")
		slot.pressed.connect(_select_item.bind(item_id))
		item_grid.add_child(slot)
	for empty_index in range(item_ids.size(), inventory.slot_capacity):
		var empty_slot := ITEM_SLOT_SCENE.instantiate() as DraggableItemSlot
		empty_slot.configure(self, "inventory", empty_index, "")
		empty_slot.set_visual(null, 0, "", false)
		empty_slot.tooltip_text = "空背包格"
		empty_slot.disabled = true
		item_grid.add_child(empty_slot)
	if not selected_item_id.is_empty() and inventory.get_amount(selected_item_id) <= 0:
		selected_item_id = ""
	_update_detail()


func _get_filtered_item_ids() -> Array[String]:
	var result: Array[String] = []
	var query := search_input.text.strip_edges().to_lower()
	var category_id := category_ids[category_filter.selected] if category_filter.selected >= 0 else ""
	for item_id in inventory.get_sorted_item_ids():
		var data := inventory.get_item_data(item_id)
		if not category_id.is_empty() and str(data.get("category", "")) != category_id:
			continue
		var searchable_text := "%s %s %s" % [data.get("name", item_id), item_id, data.get("description", "")]
		if not query.is_empty() and not searchable_text.to_lower().contains(query):
			continue
		result.append(item_id)
	return result


func _setup_category_filter() -> void:
	category_filter.clear()
	for label in ["全部类型", "武器", "工具", "可放置", "材料", "食材", "种子", "消耗品"]:
		category_filter.add_item(label)


func _on_filter_changed() -> void:
	if backpack_panel.visible:
		_refresh_backpack()


func _on_search_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		close_backpack()
		search_input.accept_event()


func _select_item(item_id: String) -> void:
	selected_item_id = item_id
	_refresh_backpack()


func _on_hotbar_slot_pressed(item_id: String) -> void:
	if backpack_panel.visible:
		_select_item(item_id)
	else:
		for index in inventory.hotbar_capacity:
			if inventory.get_hotbar_item(index) == item_id:
				activate_hotbar_slot(index)
				return


func _update_detail() -> void:
	if selected_item_id.is_empty():
		detail_name.text = "选择一个物品"
		detail_description.text = "点击物品查看说明，按住并拖动可放入快捷栏。"
		use_button.visible = false
		drop_button.visible = false
		return
	var data := inventory.get_item_data(selected_item_id)
	detail_name.text = "%s　×%d" % [data.get("name", selected_item_id), inventory.get_amount(selected_item_id)]
	detail_description.text = data.get("description", "暂无说明")
	use_button.visible = bool(data.get("usable", false))
	drop_button.visible = inventory.get_amount(selected_item_id) > 0
	match data.get("category", ""):
		"weapon": use_button.text = "装备"
		"tool": use_button.text = "放入快捷栏后选择"
		"placeable": use_button.text = "进入放置模式"
		"seed": use_button.text = "选中种子"
		_: use_button.text = "使用"


func _on_use_pressed() -> void:
	if not selected_item_id.is_empty(): item_use_requested.emit(selected_item_id)


func _on_drop_pressed() -> void:
	if not selected_item_id.is_empty(): item_drop_requested.emit(selected_item_id)


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func apply_slot_style(slot: Button, selected: bool) -> void:
	slot.add_theme_stylebox_override("normal", visual_style.slot_selected if selected else visual_style.slot_normal)
	slot.add_theme_stylebox_override("hover", visual_style.slot_hover)
	slot.add_theme_stylebox_override("pressed", visual_style.slot_selected)
	slot.add_theme_stylebox_override("focus", visual_style.slot_hover)


func get_item_icon(item_id: String) -> Texture2D:
	if inventory == null:
		return null
	return inventory.get_item_data(item_id).get("icon") as Texture2D


func _apply_inventory_theme() -> void:
	backpack_panel.add_theme_stylebox_override("panel", visual_style.backpack_panel)
	$HotbarPanel.add_theme_stylebox_override("panel", visual_style.hotbar_panel)
	$BackpackPanel/Margin/Content/Body/DetailPanel.add_theme_stylebox_override("panel", visual_style.detail_panel)
	$BackpackPanel/Margin/Content/Header/Title.add_theme_color_override("font_color", visual_style.title_color)
	capacity_label.add_theme_color_override("font_color", visual_style.capacity_color)
	for button in [$BackpackPanel/Margin/Content/Header/CloseButton, use_button, drop_button]:
		button.add_theme_stylebox_override("normal", visual_style.button_normal)
		button.add_theme_stylebox_override("hover", visual_style.button_hover)
		button.add_theme_stylebox_override("pressed", visual_style.button_pressed)
		button.add_theme_color_override("font_color", visual_style.button_text_color)
