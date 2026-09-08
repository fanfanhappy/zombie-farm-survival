class_name PlaceableDefinition
extends Resource

@export var placement_type: StringName
@export var scene: PackedScene
@export var footprint := Vector2(32, 32)


func to_dictionary() -> Dictionary:
	return {"placement_type": String(placement_type), "scene": scene, "footprint": footprint}
