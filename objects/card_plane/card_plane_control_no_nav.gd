@tool
extends Control

@export var card: Card = null:
	get:
		return card
	set(value):
		card = value
		refresh()

@onready var sprite := $Sprite
@onready var viewport := $SubViewport
@onready var card_render: CardRender = %CardRender

func _ready():
	$Sprite.texture = $SubViewport.get_texture()
	refresh()

func refresh():
	if not is_inside_tree():
		return
	
	card_render.card = card
	viewport.render_target_update_mode = SubViewport.UpdateMode.UPDATE_ONCE
	
