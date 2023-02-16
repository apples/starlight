extends Control

@export var card: Card = null:
	get:
		return card
	set(value):
		card = value
		render.card = card

@onready var render := $CardRender
