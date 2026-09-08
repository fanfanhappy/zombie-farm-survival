class_name DraggableItemSlot
extends Button

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
	var icon_rect := get_node("Icon") as TextureRect
	var amount_label := get_node("Amount") as Label
	var key_label := get_node("Hotkey") as Label
	icon_rect.texture = icon_texture
	icon_rect.visible = icon_texture != null
	amount_label.visible = amount > 1
	amount_label.text = "×%d" % amount
	key_label.visible = not hotkey.is_empty()
	key_label.text = hotkey
	self_modulate = Color.WHITE if item_id.is_empty() or amount > 0 else Color(1, 1, 1, 0.42)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_id.is_empty():
		return null
	var preview := (load("res://scenes/ui/components/draggable_item_slot.tscn") as PackedScene).instantiate() as DraggableItemSlot
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
