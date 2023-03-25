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
@onready var ability_container = %AbilityContainer


var ability_panel_scene := preload("res://objects/card_plane/ability_panel.tscn")


func _ready():
	refresh()

func refresh():
	if card:
		background.texture = frame_texture
		cardface.visible = true
		if card.artwork_path != "":
			artwork.texture = load(card.artwork_path)
		else:
			artwork.texture = load("res://data/cards/artwork/_missing.png")
		name_label.text = card.card_name
		
		for i in range(card.abilities.size()):
			if i < ability_container.get_child_count():
				ability_container.get_child(i).card_ability = card.abilities[i]
			else:
				var ap = ability_panel_scene.instantiate()
				ap.card_ability = card.abilities[i]
				ability_container.add_child(ap)
		
		for i in range(card.abilities.size(), ability_container.get_child_count()):
			ability_container.get_child(i).queue_free()
	else:
		background.texture = back_texture
		cardface.visible = false
		
		for i in range(ability_container.get_child_count()):
			ability_container.get_child(i).queue_free()
	
