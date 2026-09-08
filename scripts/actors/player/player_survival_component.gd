class_name PlayerSurvivalComponent
extends Node

@export_group("饥饿")
@export var hunger_loss_per_second := 0.45
@export var sprint_hunger_multiplier := 1.6
@export var starvation_damage_per_second := 5.0

@export_group("口渴")
@export var thirst_loss_per_second := 0.7
@export var sprint_thirst_multiplier := 1.8
@export var dehydration_damage_per_second := 7.0


func update_survival(player: Player, delta: float, sprinting: bool) -> void:
	var hunger_multiplier := sprint_hunger_multiplier if sprinting else 1.0
	player.hunger = maxf(player.hunger - hunger_loss_per_second * hunger_multiplier * delta, 0.0)
	if player.hunger <= 0.0:
		player.take_damage(starvation_damage_per_second * delta)
	player.hunger_changed.emit(player.hunger, player.max_hunger)
	var thirst_multiplier := (sprint_thirst_multiplier if sprinting else 1.0) * player.environment_thirst_multiplier
	player.thirst = maxf(player.thirst - thirst_loss_per_second * thirst_multiplier * delta, 0.0)
	if player.thirst <= 0.0:
		player.take_damage(dehydration_damage_per_second * delta)
	player.thirst_changed.emit(player.thirst, player.max_thirst)
