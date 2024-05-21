@tool
extends Control

@export var card: Card = null:
	set(value):
		card = value
		refresh()

@export var for_print: bool = false:
	set(value):
		for_print = value
		refresh()

@onready var sprite := $Sprite
@onready var viewport := $SubViewport
@onready var card_render: CardRender = %CardRender

func _ready():
	refresh()

func refresh():
	if not is_inside_tree():
		return
	
	card_render.card = card
	card_render.for_print = for_print
	viewport.render_target_update_mode = SubViewport.UpdateMode.UPDATE_ONCE
	
