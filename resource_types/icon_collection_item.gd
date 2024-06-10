class_name IconCollectionItem
extends Resource

@export var name: String
@export var texture: Texture2D
@export var size: Vector2
@export_enum("Top:0", "Center:1", "Bottom:2") var alignment_image_point: int = 1
@export_enum("Top:0", "Center:4", "Baseline:8", "Bottom:12") var alignment_text_point: int = 4
