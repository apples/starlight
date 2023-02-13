@tool
class_name CardRender
extends Node2D

enum Highlight {
	OFF,
	YELLOW,
	BLUE,
}

@export var frame_texture: Texture2D = null
@export var back_texture: Texture2D = null

@export var card: Card = null:
	get:
		return card
	set(value):
		card = value
		call_deferred(&"refresh")

@export var highlight: Highlight = Highlight.OFF:
	get:
		return highlight
	set(value):
		highlight = value
		call_deferred(&"refresh")

@onready var background: Sprite2D = $Background
@onready var cardface: Node2D = $CardFace
@onready var artwork: Sprite2D = $CardFace/Artwork
@onready var name_label: Label = $CardFace/Name
@onready var ability1description_label: Label = $CardFace/Ability1Description
@onready var ability2description_label: Label = $CardFace/Ability2Description

func _ready():
	call_deferred(&"refresh")

func refresh():
	if card:
		background.texture = frame_texture
		cardface.visible = true
		artwork.texture = card.artwork
		name_label.text = card.card_name
		if card.ability1:
			ability1description_label.text = card.ability1.description
		if card.ability2:
			ability2description_label.text = card.ability2.description
	else:
		background.texture = back_texture
		cardface.visible = false
	
	match highlight:
		Highlight.OFF:
			$Highlight.visible = false
		Highlight.YELLOW:
			$Highlight.visible = true
			$Highlight.modulate = Color.YELLOW
		Highlight.BLUE:
			$Highlight.visible = true
			$Highlight.modulate = Color.DEEP_SKY_BLUE
