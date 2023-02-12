extends Node3D

@export var card: Card = null:
	get:
		return card
	set(value):
		card = value
		call_deferred(&"refresh")

@export var highlight: CardRender.Highlight = CardRender.Highlight.OFF:
	get:
		return highlight
	set(value):
		highlight = value
		call_deferred(&"refresh")


func _ready():
	$Sprite3D.texture = $SubViewport.get_texture()
	refresh()

func refresh():
	$SubViewport/CardRender.card = card
	$SubViewport/CardRender.highlight = highlight
	$SubViewport.render_target_update_mode = SubViewport.UpdateMode.UPDATE_ONCE

