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
@onready var ability0: Control = %Ability0
@onready var ability1: Control = %Ability1

func _ready():
	refresh()

func refresh():
	if card:
		background.texture = frame_texture
		cardface.visible = true
		artwork.texture = load(card.artwork_path)
		name_label.text = card.card_name
		ability0.card_ability = card.ability0
		ability1.card_ability = card.ability1
	else:
		background.texture = back_texture
		cardface.visible = false
		ability0.card_ability = null
		ability1.card_ability = null
	ability0.visible = ability0.card_ability != null
	ability1.visible = ability1.card_ability != null
