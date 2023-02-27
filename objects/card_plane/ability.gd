@tool
extends Control

@export var normal_frame_texture: Texture = preload("res://objects/card_plane/images/frame_ability.png")
@export var starlight_frame_texture: Texture = preload("res://objects/card_plane/images/frame_ability_starlight.png")

@onready var overlays := %NormalOverlays
@onready var frame := %Frame
@onready var type_label := %Type
@onready var attack_power_frame := %AttackPowerFrame
@onready var attack_power_label := %AttackPower
@onready var name_label := %Name
@onready var mana_cost_frame := %ManaCostFrame
@onready var mana_cost_label := %ManaCost
@onready var description_label := %Description

@onready var starlight_overlays := %StarlightOverlays
@onready var starlight_name_label := %StarlightName
@onready var starlight_description_label := %StarlightDescription


@export var card_ability: CardAbility = null:
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
	if not card_ability:
		visible = false
		return
	
	visible = true
	
	if card_ability.type == CardAbility.CardAbilityType.STARLIGHT:
		_refresh_starlight()
	else:
		_refresh_normal()

func _refresh_normal():
	# frame
	frame.texture = normal_frame_texture
	
	# type
	type_label.text = CardAbility.CardAbilityType.find_key(card_ability.type)
	
	# attack power
	if card_ability.type == CardAbility.CardAbilityType.ATTACK:
		attack_power_frame.visible = true
		attack_power_label.text = card_ability.attack_power
	else:
		attack_power_frame.visible = false
	
	# name
	name_label.text = card_ability.ability_name
	
	# mana cost
	if card_ability.mana_cost:
		mana_cost_frame.visible = true
		mana_cost_label.text = card_ability.mana_cost
	else:
		mana_cost_frame.visible = false
	
	# description
	description_label.text = card_ability.description

func _refresh_starlight():
	# frame
	frame.texture = starlight_frame_texture
	
	# name
	starlight_name_label.text = card_ability.ability_name
	
	# description
	starlight_description_label.text = card_ability.description

