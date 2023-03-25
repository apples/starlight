@tool
extends Control

var normal_frame_texture: Texture = preload("res://objects/card_plane/images/frame_ability.png")
var starlight_frame_texture: Texture = preload("res://objects/card_plane/images/frame_ability_starlight.png")

@onready var overlays := %NormalOverlays
@onready var frame := %Frame
@onready var type_label := %Type
@onready var attack_power_frame := %AttackPowerFrame
@onready var attack_power_label := %AttackPower
@onready var name_label := %Name
@onready var mana_cost_frame := %ManaCostFrame
@onready var mana_cost_label := %ManaCost
@onready var description_label := %Description
@onready var normal_header_row = %NormalHeaderRow
@onready var stella_frame = %StellaFrame

@onready var starlight_overlays := %StarlightOverlays
@onready var starlight_name_label := %StarlightName
@onready var starlight_description_label := %StarlightDescription

var card: Card

var card_ability: CardAbility = null:
	get:
		return card_ability
	set(value):
		card_ability = value
		if is_inside_tree():
			refresh()


# Called when the node enters the scene tree for the first time.
func _ready():
	refresh()

func refresh():
	assert(card_ability)
	
	if card_ability.type == CardAbility.CardAbilityType.STARLIGHT:
		overlays.visible = false
		starlight_overlays.visible = true
		_refresh_starlight()
	else:
		overlays.visible = true
		starlight_overlays.visible = false
		_refresh_normal()

func _refresh_normal():
	
	# frame
	if card.kind == Card.Kind.STELLA:
		stella_frame.visible = true
		frame.visible = false
	else:
		stella_frame.visible = false
		frame.visible = true
		frame.texture = normal_frame_texture
	
	if card.kind == Card.Kind.STELLA:
		normal_header_row.visible = false
	else:
		normal_header_row.visible = true
			
		# type
		type_label.text = CardAbility.CardAbilityType.find_key(card_ability.type)
		
		# attack power
		if card_ability.effect:
			var attack_power := card_ability.effect.get_attack_damage()
			if attack_power != "":
				attack_power_frame.visible = true
				attack_power_label.text = attack_power
			else:
				attack_power_frame.visible = false
		else:
			attack_power_frame.visible = false
		
		# name
		name_label.text = card_ability.ability_name
		
		# mana cost
		if card_ability.cost:
			var mana_cost := card_ability.cost.get_mana_cost()
			if mana_cost != "":
				mana_cost_frame.visible = true
				mana_cost_label.text = mana_cost
			else:
				mana_cost_frame.visible = false
		else:
			mana_cost_frame.visible = false
	
	# description
	description_label.text = card_ability.description
	

func _refresh_starlight():
	# frame
	stella_frame.visible = false
	frame.visible = true
	frame.texture = starlight_frame_texture
	
	# name
	starlight_name_label.text = card_ability.ability_name
	
	# description
	starlight_description_label.text = card_ability.description

