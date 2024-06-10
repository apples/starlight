@tool
class_name IconLabelHighlight
extends Resource

@export var regex: String
@export var style: StyleBox

@export_group("Margins")
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var margin_left: int = 0
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var margin_top: int = 0
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var margin_right: int = 0
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var margin_bottom: int = 0
