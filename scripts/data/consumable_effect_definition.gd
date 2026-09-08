class_name ConsumableEffectDefinition
extends Resource

@export_range(0.0, 10000.0, 1.0) var health_restore := 0.0
@export_range(0.0, 10000.0, 1.0) var stamina_restore := 0.0
@export_range(0.0, 10000.0, 1.0) var hunger_restore := 0.0
@export_range(0.0, 10000.0, 1.0) var thirst_restore := 0.0
@export_range(0.0, 3600.0, 1.0) var well_fed_duration := 0.0
@export_multiline var use_message := "物品已使用"
