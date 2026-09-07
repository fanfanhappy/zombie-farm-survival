class_name InventoryUI
extends CanvasLayer

signal item_use_requested(item_id: String)
signal item_drop_requested(item_id: String)
signal inventory_closed

const SLOT_TEXTURE := preload("res://assets/art/ui/inventory/ui_inventory_slots.png")
const GENERAL_ICON_TEXTURE := preload("res://assets/art/ui/icons/item_general_icons.png")
const TOOL_ICON_TEXTURE := preload("res://assets/art/ui/icons/item_tool_material_icons.png")
const FARMING_ICON_TEXTURE := preload("res://assets/art/ui/icons/item_farming_icons.png")
const FOOD_ICON_TEXTURE := preload("res://assets/art/ui/icons/item_food_icons.png")
const EGG_ICON_TEXTURE := preload("res://assets/art/characters/egg_and_nest.png")


class DraggableItemSlot extends Button:
	var inventory_ui: InventoryUI
	var slot_kind := "inventory"
	var slot_index := -1
	var item_id := ""

	func configure(ui: InventoryUI, kind: String, index: int, id: String) -> void:
		inventory_ui = ui
		slot_kind = kind
		slot_index = index
		item_id = id

	func set_visual(icon_texture: Texture2D, amount: int, hotkey: String, selected: bool) -> void:
		text = ""
		inventory_ui.apply_slot_style(self, selected)
		var icon_rect := TextureRect.new()
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.set_anchors_preset(Control.PRESET_CENTER)
		icon_rect.offset_left = -18.0
		icon_rect.offset_top = -19.0
		icon_rect.offset_right = 18.0
		icon_rect.offset_bottom = 17.0
		icon_rect.texture = icon_texture
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(icon_rect)
		if amount > 0:
			var amount_label := Label.new()
			amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			amount_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			amount_label.offset_left = -34.0
			amount_label.offset_top = -23.0
			amount_label.offset_right = -5.0
			amount_label.offset_bottom = -3.0
			amount_label.text = "×%d" % amount
			amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			amount_label.add_theme_font_size_override("font_size", 13)
			amount_label.add_theme_color_override("font_color", Color("#fff4d2"))
			amount_label.add_theme_color_override("font_outline_color", Color("#4b2f2b"))
			amount_label.add_theme_constant_override("outline_size", 3)
			add_child(amount_label)
		if not hotkey.is_empty():
			var key_label := Label.new()
			key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			key_label.offset_left = 7.0
			key_label.offset_top = 4.0
			key_label.offset_right = 25.0
			key_label.offset_bottom = 23.0
			key_label.text = hotkey
			key_label.add_theme_font_size_override("font_size", 13)
			key_label.add_theme_color_override("font_color", Color("#5b3733"))
			add_child(key_label)

	func _get_drag_data(_at_position: Vector2) -> Variant:
		if item_id.is_empty():
			return null
		var preview := DraggableItemSlot.new()
		preview.custom_minimum_size = Vector2(64, 64)
		preview.inventory_ui = inventory_ui
		preview.set_visual(inventory_ui.get_item_icon(item_id), inventory_ui.inventory.get_amount(item_id), "", false)
		preview.tooltip_text = inventory_ui.inventory.get_display_name(item_id)
		set_drag_preview(preview)
		return {"source": slot_kind, "slot_index": slot_index, "item_id": item_id}

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return slot_kind == "hotbar" and data is Dictionary and data.has("item_id")

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		inventory_ui.handle_hotbar_drop(slot_index, data)

	func _gui_input(event: InputEvent) -> void:
		if slot_kind == "hotbar" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			inventory_ui.clear_hotbar_slot(slot_index)
			accept_event()


@onready var hotbar: HBoxContainer = $HotbarPanel/Margin/Hotbar
@onready var backpack_panel: PanelContainer = $BackpackPanel
@onready var capacity_label: Label = $BackpackPanel/Margin/Content/Header/Capacity
@onready var item_grid: GridContainer = $BackpackPanel/Margin/Content/ItemGrid
@onready var detail_name: Label = $BackpackPanel/Margin/Content/DetailPanel/Margin/Detail/ItemName
@onready var detail_description: Label = $BackpackPanel/Margin/Content/DetailPanel/Margin/Detail/Description
@onready var use_button: Button = $BackpackPanel/Margin/Content/DetailPanel/Margin/Detail/UseButton
@onready var drop_button: Button = $BackpackPanel/Margin/Content/DetailPanel/Margin/Detail/DropButton

var inventory: InventorySystem
var selected_item_id := ""
var selected_hotbar_index := -1


func setup(inventory_system: InventorySystem) -> void:
	inventory = inventory_system
	_apply_inventory_theme()
	inventory.inventory_changed.connect(refresh)
	$BackpackPanel/Margin/Content/Header/CloseButton.pressed.connect(close_backpack)
	use_button.pressed.connect(_on_use_pressed)
	drop_button.pressed.connect(_on_drop_pressed)
	refresh()


func toggle_backpack() -> void:
	if backpack_panel.visible: close_backpack()
	else: open_backpack()


func open_backpack() -> void:
	backpack_panel.visible = true
	refresh()


func close_backpack() -> void:
	backpack_panel.visible = false
	inventory_closed.emit()


func is_backpack_open() -> bool:
	return backpack_panel.visible


func refresh() -> void:
	if inventory == null: return
	_refresh_hotbar()
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
	if item_id.is_empty():
		return false
	item_use_requested.emit(item_id)
	return true


func get_selected_hotbar_item_id() -> String:
	if selected_hotbar_index < 0: return ""
	return inventory.get_hotbar_item(selected_hotbar_index)


func _refresh_hotbar() -> void:
	_clear_container(hotbar)
	for index in inventory.hotbar_capacity:
		var item_id := inventory.get_hotbar_item(index)
		var slot := DraggableItemSlot.new()
		slot.custom_minimum_size = Vector2(64, 64)
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
	var item_ids := inventory.get_sorted_item_ids()
	for item_id in item_ids:
		var data := inventory.get_item_data(item_id)
		var slot := DraggableItemSlot.new()
		slot.custom_minimum_size = Vector2(64, 64)
		slot.configure(self, "inventory", -1, item_id)
		slot.set_visual(get_item_icon(item_id), inventory.get_amount(item_id), "", selected_item_id == item_id)
		slot.tooltip_text = "%s\n拖动到下方快捷栏" % data.get("description", "")
		slot.pressed.connect(_select_item.bind(item_id))
		item_grid.add_child(slot)
	for empty_index in range(item_ids.size(), inventory.slot_capacity):
		var empty_slot := DraggableItemSlot.new()
		empty_slot.custom_minimum_size = Vector2(64, 64)
		empty_slot.configure(self, "inventory", empty_index, "")
		empty_slot.set_visual(null, 0, "", false)
		empty_slot.tooltip_text = "空背包格"
		empty_slot.disabled = true
		item_grid.add_child(empty_slot)
	if not selected_item_id.is_empty() and inventory.get_amount(selected_item_id) <= 0:
		selected_item_id = ""
	_update_detail()


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
	slot.add_theme_stylebox_override("normal", _create_slot_style(2 if selected else 0))
	slot.add_theme_stylebox_override("hover", _create_slot_style(1))
	slot.add_theme_stylebox_override("pressed", _create_slot_style(2))
	slot.add_theme_stylebox_override("focus", _create_slot_style(1))


func get_item_icon(item_id: String) -> Texture2D:
	match item_id:
		"watering_can": return _create_atlas_icon(TOOL_ICON_TEXTURE, Vector2i(0, 0))
		"stone_axe": return _create_atlas_icon(TOOL_ICON_TEXTURE, Vector2i(1, 0))
		"stone_pickaxe": return _create_atlas_icon(TOOL_ICON_TEXTURE, Vector2i(2, 0))
		"stone_hoe": return _create_atlas_icon(TOOL_ICON_TEXTURE, Vector2i(3, 0))
		"repair_hammer": return _create_atlas_icon(TOOL_ICON_TEXTURE, Vector2i(0, 1))
		"wooden_club": return _create_atlas_icon(TOOL_ICON_TEXTURE, Vector2i(1, 1))
		"wood": return _create_atlas_icon(TOOL_ICON_TEXTURE, Vector2i(0, 2))
		"stone": return _create_atlas_icon(TOOL_ICON_TEXTURE, Vector2i(2, 2))
		"scrap": return _create_atlas_icon(TOOL_ICON_TEXTURE, Vector2i(3, 2))
		"potato": return _create_atlas_icon(FARMING_ICON_TEXTURE, Vector2i(0, 0))
		"carrot": return _create_atlas_icon(FARMING_ICON_TEXTURE, Vector2i(1, 1))
		"egg": return _create_atlas_icon(EGG_ICON_TEXTURE, Vector2i(0, 0))
		"potato_seed": return _create_atlas_icon(FARMING_ICON_TEXTURE, Vector2i(0, 8))
		"carrot_seed": return _create_atlas_icon(FARMING_ICON_TEXTURE, Vector2i(1, 8))
		"herb", "herb_seed": return _create_atlas_icon(FARMING_ICON_TEXTURE, Vector2i(0, 5))
		"meal": return _create_atlas_icon(FOOD_ICON_TEXTURE, Vector2i(1, 0))
		"bandage": return _create_atlas_icon(GENERAL_ICON_TEXTURE, Vector2i(3, 2))
		"storage_chest": return _create_atlas_icon(GENERAL_ICON_TEXTURE, Vector2i(0, 0))
		"wood_fence": return _create_atlas_icon(GENERAL_ICON_TEXTURE, Vector2i(1, 2))
		"wood_spike": return _create_atlas_icon(GENERAL_ICON_TEXTURE, Vector2i(2, 2))
		"snare_trap": return _create_atlas_icon(GENERAL_ICON_TEXTURE, Vector2i(4, 2))
	return _create_atlas_icon(GENERAL_ICON_TEXTURE, Vector2i(0, 0))


func _create_atlas_icon(texture: Texture2D, cell: Vector2i) -> AtlasTexture:
	var icon := AtlasTexture.new()
	icon.atlas = texture
	icon.region = Rect2(cell * 16, Vector2i(16, 16))
	return icon


func _create_slot_style(column: int) -> StyleBoxTexture:
	var texture := AtlasTexture.new()
	texture.atlas = SLOT_TEXTURE
	texture.region = Rect2(column * 48, 96, 48, 48)
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 9.0
	style.texture_margin_top = 9.0
	style.texture_margin_right = 9.0
	style.texture_margin_bottom = 9.0
	return style


func _apply_inventory_theme() -> void:
	var backpack_style := _create_panel_style(Color("#5a3934e8"), Color("#d9ac78"), 4)
	var hotbar_style := _create_panel_style(Color("#3f2927dc"), Color("#b67b58"), 3)
	backpack_panel.add_theme_stylebox_override("panel", backpack_style)
	$HotbarPanel.add_theme_stylebox_override("panel", hotbar_style)
	$BackpackPanel/Margin/Content/DetailPanel.add_theme_stylebox_override("panel", _create_panel_style(Color("#3e2927d9"), Color("#95664f"), 2))
	$BackpackPanel/Margin/Content/Header/Title.add_theme_color_override("font_color", Color("#ffe5ae"))
	capacity_label.add_theme_color_override("font_color", Color("#e8cda5"))
	for button in [$BackpackPanel/Margin/Content/Header/CloseButton, use_button, drop_button]:
		button.add_theme_stylebox_override("normal", _create_panel_style(Color("#b77b55"), Color("#f0c68e"), 2))
		button.add_theme_stylebox_override("hover", _create_panel_style(Color("#d09260"), Color("#fff0bd"), 2))
		button.add_theme_stylebox_override("pressed", _create_panel_style(Color("#8f5a48"), Color("#f0c68e"), 2))
		button.add_theme_color_override("font_color", Color("#fff5dc"))


func _create_panel_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style
