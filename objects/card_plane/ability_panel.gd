@tool
extends Control

@onready var overlays := %NormalOverlays
@onready var frame := %Frame
@onready var type_rect: TextureRect = %Type
@onready var attack_power_frame := %AttackPowerFrame
@onready var attack_power_label := %AttackPower
@onready var name_label := %Name
@onready var mana_cost_frame := %ManaCostFrame
@onready var mana_cost_label := %ManaCost
@onready var description_label := %Description
@onready var normal_header_row = %NormalHeaderRow

@onready var grace_overlays := %GraceOverlays
@onready var grace_name_label := %GraceName
@onready var grace_description_label := %GraceDescription

var card: Card
var get_card_texture: Callable
var text_modulate: Color = Color.WHITE

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
	if not card_ability:
		return
	
	if card_ability.type == CardAbility.CardAbilityType.GRACE:
		overlays.visible = false
		grace_overlays.visible = true
		_refresh_grace()
	else:
		overlays.visible = true
		grace_overlays.visible = false
		_refresh_normal()

func _refresh_normal():
	
	# frame
	match card.kind:
		Card.Kind.RULECARD:
			frame.texture = get_card_texture.call(&"FRAME_ABILITY_RULECARD")
		Card.Kind.UNIT:
			frame.texture = get_card_texture.call(&"FRAME_ABILITY")
		Card.Kind.SPELL:
			frame.texture = get_card_texture.call(&"FRAME_ABILITY_SPELL")
	
	if card.kind == Card.Kind.RULECARD:
		normal_header_row.visible = false
	else:
		normal_header_row.visible = true
		
		# type
		match card_ability.type:
			CardAbility.CardAbilityType.ACTION:
				type_rect.texture = get_card_texture.call(&"FRAME_ABILITY_TAG_ACTION")
			CardAbility.CardAbilityType.ATTACK:
				type_rect.texture = get_card_texture.call(&"FRAME_ABILITY_TAG_ATTACK")
			CardAbility.CardAbilityType.PASSIVE:
				type_rect.texture = get_card_texture.call(&"FRAME_ABILITY_TAG_PASSIVE")
			CardAbility.CardAbilityType.TRIGGER:
				type_rect.texture = get_card_texture.call(&"FRAME_ABILITY_TAG_TRIGGER")
			_:
				push_error("Unknown type: ", card_ability.type)
		
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
		name_label.modulate = text_modulate
		
		# mana cost
		if card_ability.cost:
			var mana_cost := card_ability.cost.get_mana_cost()
			var tap := card_ability.cost.get_requires_tap()
			mana_cost_frame.visible = mana_cost != "" or tap
			match [tap, mana_cost]:
				[true, ""]:
					mana_cost_frame.texture = get_card_texture.call(&"FRAME_ABILITY_MANACOST_TAP")
					mana_cost_label.text = ""
				[true, _]:
					mana_cost_frame.texture = get_card_texture.call(&"FRAME_ABILITY_MANACOST_TAP")
					mana_cost_label.text = "+" + mana_cost
				[false, _]:
					mana_cost_frame.texture = get_card_texture.call(&"FRAME_ABILITY_MANACOST")
					mana_cost_label.text = " " + mana_cost
				_:
					push_error("Invalid mana cost state")
					breakpoint
		else:
			mana_cost_frame.visible = false
	
	# description
	description_label.text = card_ability.description
	description_label.modulate = text_modulate
	

func _refresh_grace():
	# frame
	frame.texture = get_card_texture.call(&"FRAME_ABILITY_GRACE")
	
	# name
	grace_name_label.text = card_ability.ability_name
	grace_name_label.modulate = text_modulate
	
	# description
	grace_description_label.text = card_ability.description
	grace_description_label.modulate = text_modulate

