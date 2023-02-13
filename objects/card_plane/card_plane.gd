class_name CardPlane extends Node3D

@export var card: Card = null:
	get:
		return card
	set(value):
		card = value
		call_deferred("refresh")

@export var highlight: CardRender.Highlight = CardRender.Highlight.OFF:
	get:
		return highlight
	set(value):
		highlight = value
		call_deferred("refresh")

@export var show_card: bool = true:
	get:
		return show_card
	set(value):
		show_card = value
		call_deferred("refresh")

@export var location: BattleState.ZoneLocation = null:
	get:
		return location
	set(value):
		location = value
		call_deferred("refresh")

@onready var cursor_location := $CursorLocation

func _ready():
	$Sprite.texture = $SubViewport.get_texture()
	$CursorLocation.location = location
	refresh()

func refresh():
	$CursorLocation.location = location
	if show_card:
		$SubViewport/CardRender.card = card
		$SubViewport/CardRender.highlight = highlight
		$SubViewport.render_target_update_mode = SubViewport.UpdateMode.UPDATE_ONCE
		$Sprite.visible = true
	else:
		$Sprite.visible = false

