extends SceneTree

const ATLAS_PATH := "res://assets/art/environment/crops/crop_growth_atlas.png"
const CROP_SCENES := [
	"res://scenes/world/farming/crops/carrot_crop_visual.tscn",
	"res://scenes/world/farming/crops/potato_crop_visual.tscn",
	"res://scenes/world/farming/crops/medicinal_herb_crop_visual.tscn",
]

func _initialize() -> void:
	var atlas := load(ATLAS_PATH) as Texture2D
	if atlas == null or atlas.get_width() != 80 or atlas.get_height() != 240:
		push_error("CROP_VISUAL_ASSET_INVALID: crop_growth_atlas must be 80x240")
		quit(1)
		return
	for scene_path in CROP_SCENES:
		var scene := load(scene_path) as PackedScene
		if scene == null:
			push_error("CROP_VISUAL_SCENE_MISSING: " + scene_path)
			quit(1)
			return
		var visual := scene.instantiate()
		var stages := visual.get_children().filter(func(node): return node.name.begins_with("Stage"))
		if stages.size() != 5:
			push_error("CROP_VISUAL_STAGE_COUNT_INVALID: " + scene_path)
			visual.free()
			quit(1)
			return
		for stage in stages:
			if stage.texture != atlas or not stage.region_enabled or stage.region_rect.size != Vector2(16, 16):
				push_error("CROP_VISUAL_FRAME_INVALID: " + scene_path + ":" + stage.name)
				visual.free()
				quit(1)
				return
		visual.free()
	print("CROP_VISUAL_ASSETS_OK")
	quit(0)
