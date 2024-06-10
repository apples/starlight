@tool
class_name IconLabelSettings
extends Resource

@export var font: Font = null

@export_custom(PROPERTY_HINT_NONE, "suffix:px") var font_size: int = 0

@export var color: Color = Color.WHITE

@export_custom(PROPERTY_HINT_NONE, "suffix:px") var line_spacing: int = 0

@export var icon_collection: IconCollection = null
