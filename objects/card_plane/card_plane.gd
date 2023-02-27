@tool
class_name CardPlane extends Node3D

@export var card: Card = null:
	get:
		return card
	set(value):
		card = value
		refresh()

@export var show_card: bool = true:
	get:
		return show_card
	set(value):
		show_card = value
		refresh()

@export var location: ZoneLocation = null:
	get:
		return location
	set(value):
		location = value
		refresh()

@export_flags("Battle", "Player", "Opponent", "Field", "Hand", "Actions") var cursor_layers: int = 0

@onready var subviewport := $SubViewport
@onready var card_render := $SubViewport/CardRender
@onready var sprite := $Sprite
@onready var cursor_location := %CursorLocation
@onready var action_root := %ActionRoot

func _ready():
	cursor_location.layers = cursor_layers
	refresh()

func refresh():
	if not is_inside_tree():
		return
	
	cursor_location.location = location
	
	if show_card:
		card_render.card = card
		subviewport.render_target_update_mode = SubViewport.UpdateMode.UPDATE_ONCE
		sprite.visible = true
	else:
		sprite.visible = false
