class_name StorageItemEntry
extends Button

signal action_requested

@onready var item_name_label: Label = $Content/ItemName
@onready var amount_label: Label = $Content/Amount
@onready var action_label: Label = $Content/Action


func _ready() -> void:
	pressed.connect(action_requested.emit)


func configure(item_name: String, amount: int, action_text: String) -> void:
	item_name_label.text = item_name
	amount_label.text = "×%d" % amount
	action_label.text = action_text
