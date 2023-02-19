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
		if is_inside_tree():
			refresh()

@export var highlight: Highlight = Highlight.OFF:
	get:
		return highlight
	set(value):
		highlight = value
		if is_inside_tree():
			refresh()

@export var poke: bool = false:
	set(value):
		poke = false
		if is_inside_tree():
			refresh()

@onready var background: Sprite2D = $Background
@onready var cardface: Control = $CardFace
@onready var artwork: Sprite2D = $CardFace/Artwork
@onready var name_label: Label = $CardFace/Name
@onready var ability1 := $CardFace/Ability1
@onready var ability2 := $CardFace/Ability2
@onready var ability_solo := $CardFace/AbilitySolo

func _ready():
	refresh()

func refresh():
	if card:
		background.texture = frame_texture
		cardface.visible = true
		artwork.texture = card.artwork
		name_label.text = card.card_name
		var solo: bool = card.ability1 and not card.ability2 or \
			not card.ability1 and card.ability2
		if solo:
			ability1.card_ability = null
			ability2.card_ability = null
			ability_solo.card_ability = card.ability1 if card.ability1 else card.ability2
		else:
			ability1.card_ability = card.ability1
			ability2.card_ability = card.ability2
			ability_solo.card_ability = null
	else:
		background.texture = back_texture
		cardface.visible = false
		ability1.card_ability = null
		ability2.card_ability = null
		ability_solo.card_ability = null
	
	match highlight:
		Highlight.OFF:
			$Highlight.visible = false
		Highlight.YELLOW:
			$Highlight.visible = true
			$Highlight.modulate = Color.YELLOW
		Highlight.BLUE:
			$Highlight.visible = true
			$Highlight.modulate = Color.DEEP_SKY_BLUE
