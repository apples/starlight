@tool
class_name CardRender
extends Node2D

@export var frame_texture: Texture2D = null
@export var back_texture: Texture2D = null

@export var stella_frame_texture: Texture2D = null

@export var card: Card = null:
	get:
		return card
	set(value):
		card = value
		refresh()

@export var poke: bool:
	set(_v):
		refresh()

@onready var background: Sprite2D = $Background
@onready var typical_cardface: Control = $TypicalCardFace
@onready var stella_cardface: Control = $StellaCardFace


var ability_panel_scene := preload("res://objects/card_plane/ability_panel.tscn")

var ability_panels: Array[Control] = []

var prev_card: Card

func _ready():
	refresh()

func refresh():
	if not is_inside_tree():
		return
	
	if Engine.is_editor_hint():
		if get_tree().edited_scene_root == self:
			return
		
		if get_tree().edited_scene_root.is_ancestor_of(self):
			return
	
	if card:
		if prev_card != card:
			_cleanup(typical_cardface.get_node("AbilityContainer"))
			_cleanup(stella_cardface.get_node("AbilityContainer"))
			ability_panels = []
		
		match card.kind:
			Card.Kind.STELLA:
				_refresh_stella()
			_:
				_refresh_typical()
		
		prev_card = card
	else:
		background.texture = back_texture
		typical_cardface.visible = false
		stella_cardface.visible = false
		
		_cleanup(typical_cardface.get_node("AbilityContainer"))
		_cleanup(stella_cardface.get_node("AbilityContainer"))
		ability_panels = []
		
		prev_card = null

func _cleanup(node: Node):
	while node.get_child_count() > 0:
		var c := node.get_child(-1)
		c.queue_free()
		node.remove_child(c)


func _refresh_typical():
	background.texture = frame_texture
	typical_cardface.visible = true
	stella_cardface.visible = false
	_refresh_generic(typical_cardface)

func _refresh_stella():
	background.texture = stella_frame_texture
	typical_cardface.visible = false
	stella_cardface.visible = true
	_refresh_generic(stella_cardface)

func _refresh_generic(cardface: Node):
	var artwork = cardface.get_node("Artwork")
	var name_label = cardface.get_node("Name")
	var ability_container: VBoxContainer = cardface.get_node("AbilityContainer")
	
	if card.artwork_path != "":
		artwork.texture = load(card.artwork_path)
	else:
		artwork.texture = load("res://data/cards/artwork/_missing.png")
	name_label.text = card.card_name
	
	
	for i in range(card.abilities.size()):
		if i < ability_panels.size():
			ability_panels[i].card = card
			ability_panels[i].card_ability = card.abilities[i]
		else:
			if i == 0:
				assert(ability_container.get_child_count() == 0)
				ability_container.add_spacer(false)
			var ap = ability_panel_scene.instantiate()
			ap.card = card
			ap.card_ability = card.abilities[i]
			ability_container.add_child(ap)
			ability_container.add_spacer(false)
			ability_panels.append(ap)
	
	for i in range(ability_panels.size(), card.abilities.size(), -1):
		ability_panels.remove_at(i - 1)
	
	for i in range(card.abilities.size(), (ability_container.get_child_count() - 1) / 2):
		ability_container.get_child(1 + i * 2).queue_free()
		ability_container.get_child(1 + i * 2 + 1).queue_free()
	
	if card.abilities.size() == 0:
		if ability_container.get_child_count() > 0:
			ability_container.get_child(0).queue_free()
	
