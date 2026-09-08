class_name InventoryVisualStyle
extends Resource

@export_group("物品格")
@export var slot_normal: StyleBox
@export var slot_hover: StyleBox
@export var slot_selected: StyleBox

@export_group("面板")
@export var backpack_panel: StyleBox
@export var hotbar_panel: StyleBox
@export var detail_panel: StyleBox

@export_group("按钮")
@export var button_normal: StyleBox
@export var button_hover: StyleBox
@export var button_pressed: StyleBox

@export_group("文字颜色")
@export var title_color := Color("#ffe5ae")
@export var capacity_color := Color("#e8cda5")
@export var button_text_color := Color("#fff5dc")
