@tool
class_name CardPlane extends Node3D

@export var card: Card = null:
	get:
		return card
	set(value):
		card = value
		refresh()

@export var highlight: CardRender.Highlight = CardRender.Highlight.OFF:
	get:
		return highlight
	set(value):
		highlight = value
		refresh()

@export var show_card: bool = true:
	get:
		return show_card
	set(value):
		show_card = value
		refresh()

@export var location: BattleState.ZoneLocation = null:
	get:
		return location
	set(value):
		location = value
		refresh()

@onready var sprite := $Sprite
@onready var cursor_location := $CursorLocation
@onready var subviewport := $SubViewport
@onready var card_render := $SubViewport/CardRender

func _ready():
	refresh()

func refresh():
	if not is_inside_tree():
		return
	
	cursor_location.location = location
	
	if show_card:
		card_render.card = card
		card_render.highlight = highlight
		subviewport.render_target_update_mode = SubViewport.UpdateMode.UPDATE_ONCE
		sprite.visible = true
	else:
		sprite.visible = false
