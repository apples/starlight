@tool
extends Control

@onready var frame := $Frame
@onready var starlight_frame := $StarlightFrame
@onready var type_label := $Type
@onready var attack_power_frame := $AttackPowerFrame
@onready var attack_power_label := $AttackPower
@onready var name_label := $Name
@onready var starlight_name_label := $StarlightName
@onready var mana_cost_frame := $ManaCostFrame
@onready var mana_cost_label := $ManaCost
@onready var description_label := $Description


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
	
	# frame
	match card_ability.type:
		CardAbility.CardAbilityType.STARLIGHT:
			frame.visible = false
			starlight_frame.visible = true
		_:
			frame.visible = true
			starlight_frame.visible = false
	
	# type
	match card_ability.type:
		CardAbility.CardAbilityType.ACTION,\
		CardAbility.CardAbilityType.ATTACK,\
		CardAbility.CardAbilityType.PASSIVE,\
		CardAbility.CardAbilityType.TRIGGER:
			type_label.visible = true
			type_label.text = CardAbility.CardAbilityType.find_key(card_ability.type)
		_:
			type_label.visible = false
	
	# attack power
	if card_ability.type == CardAbility.CardAbilityType.ATTACK:
		attack_power_frame.visible = true
		attack_power_label.visible = true
		attack_power_label.text = card_ability.attack_power
	else:
		attack_power_frame.visible = false
		attack_power_label.visible = false
	
	# name
	if card_ability.type == CardAbility.CardAbilityType.STARLIGHT:
		name_label.visible = false
		starlight_name_label.visible = true
	else:
		name_label.visible = true
		starlight_name_label.visible = false
		name_label.text = card_ability.ability_name
	
	# mana cost
	if card_ability.mana_cost:
		mana_cost_frame.visible = true
		mana_cost_label.visible = true
		mana_cost_label.text = card_ability.mana_cost
	else:
		mana_cost_frame.visible = false
		mana_cost_label.visible = false
	
	# description
	description_label.text = card_ability.description
