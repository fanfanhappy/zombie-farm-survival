class_name SnareTrap
extends Area2D

const MAX_CHARGES := 3
var charges := MAX_CHARGES
var triggered_cooldown := 0.0
@onready var visual: Sprite2D = $Visual
@onready var charges_label: Label = $ChargesLabel


func _ready() -> void:
	add_to_group("snare_traps")
	body_entered.connect(_on_body_entered)
	_update_visual_state()


func _physics_process(delta: float) -> void:
	triggered_cooldown = maxf(triggered_cooldown - delta, 0.0)


func _on_body_entered(body: Node2D) -> void:
	if triggered_cooldown > 0.0 or charges <= 0 or not body is Zombie: return
	var zombie := body as Zombie
	zombie.take_damage(8.0)
	zombie.apply_slow(0.38, 4.0)
	charges -= 1
	triggered_cooldown = 0.6
	_update_visual_state()
	if charges <= 0:
		monitoring = false
		get_tree().create_timer(0.35).timeout.connect(queue_free)


func create_save_data() -> Dictionary:
	return {"x": position.x, "y": position.y, "rotation": rotation, "charges": charges}


func _update_visual_state() -> void:
	if not is_instance_valid(visual):
		return
	visual.modulate = Color.WHITE if charges > 0 else Color("#554d48")
	charges_label.text = str(charges)
