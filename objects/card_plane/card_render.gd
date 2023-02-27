@tool
class_name CardRender
extends Node2D

@export var frame_texture: Texture2D = null
@export var back_texture: Texture2D = null

@export var card: Card = null:
	get:
		return card
	set(value):
		card = value
		if is_inside_tree():
			refresh()

@export var poke: bool = false:
	set(_v):
		poke = false
		if is_inside_tree():
			refresh()

@onready var background: Sprite2D = $Background
@onready var cardface: Control = $CardFace
@onready var artwork: Sprite2D = $CardFace/Artwork
@onready var name_label: Label = $CardFace/Name
@onready var ability1: Control = %Ability1
@onready var ability2: Control = %Ability2

func _ready():
	refresh()

func refresh():
	if card:
		background.texture = frame_texture
		cardface.visible = true
		artwork.texture = card.artwork
		name_label.text = card.card_name
		ability1.card_ability = card.ability1
		ability2.card_ability = card.ability2
	else:
		background.texture = back_texture
		cardface.visible = false
		ability1.card_ability = null
		ability2.card_ability = null
	ability1.visible = ability1.card_ability != null
	ability2.visible = ability2.card_ability != null
