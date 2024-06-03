@tool
extends Control

@onready var overlays := %NormalOverlays
@onready var frame := %Frame
@onready var type_rect: TextureRect = %Type
@onready var attack_power_frame := %AttackPowerFrame
@onready var attack_power_label: Label = %AttackPower
@onready var name_label: Label = %Name


@onready var tap_cost: TextureRect = %TapCost
@onready var mana_cost_frame := %ManaCostFrame
@onready var mana_cost_label: Label = %ManaCost

@onready var description_label: Label = %Description
@onready var normal_header_row = %NormalHeaderRow

@onready var grace_overlays := %GraceOverlays
@onready var grace_name_label: Label = %GraceName
@onready var grace_description_label: Label = %GraceDescription

var condition_prefix := "[bgcolor=red]"
var condition_suffix := "[/bgcolor]"
var costs_prefix := "[bgcolor=green]"
var costs_suffix := "[/bgcolor]"
var effect_prefix := ""
var effect_suffix := ""

var card: Card
var get_card_texture: Callable
var get_card_color: Callable

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
			match card_ability.type:
				CardAbility.CardAbilityType.TRIGGER:
					frame.texture = get_card_texture.call(&"FRAME_ABILITY_SPELL_TRIGGER")
				_:
					frame.texture = get_card_texture.call(&"FRAME_ABILITY_SPELL")
	
	if card.kind == Card.Kind.RULECARD:
		normal_header_row.visible = false
	else:
		normal_header_row.visible = true
		
		# type
		match [card.kind, card_ability.type]:
			[Card.Kind.SPELL, _]:
				type_rect.texture = null
			[_, CardAbility.CardAbilityType.ACTION]:
				type_rect.texture = get_card_texture.call(&"FRAME_ABILITY_TAG_ACTION")
			[_, CardAbility.CardAbilityType.ATTACK]:
				type_rect.texture = get_card_texture.call(&"FRAME_ABILITY_TAG_ATTACK")
			[_, CardAbility.CardAbilityType.PASSIVE]:
				type_rect.texture = get_card_texture.call(&"FRAME_ABILITY_TAG_PASSIVE")
			[_, CardAbility.CardAbilityType.TRIGGER]:
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
		name_label.add_theme_color_override(&"font_color", get_card_color.call(&"TEXT"))
		
		# mana cost
		if card_ability.cost:
			var mana_cost := card_ability.cost.get_mana_cost()
			var tap := card_ability.cost.get_requires_tap()
			tap_cost.visible = tap
			tap_cost.texture = get_card_texture.call(&"FRAME_ABILITY_TAPCOST")
			mana_cost_frame.visible = mana_cost != ""
			mana_cost_frame.texture = get_card_texture.call(&"FRAME_ABILITY_MANACOST_TAP" if tap else &"FRAME_ABILITY_MANACOST")
			mana_cost_label.text = mana_cost
		else:
			tap_cost.visible = false
			mana_cost_frame.visible = false
	
	# description
	description_label.text = card_ability.description
	description_label.add_theme_color_override(&"font_color", get_card_color.call(&"TEXT"))
	
	var description_parent = description_label.get_parent()
	
	if description_parent.condition_style is StyleBoxFlat:
		assert(description_parent.condition_style.resource_local_to_scene)
		description_parent.condition_style.bg_color = get_card_color.call(&"HIGHLIGHT_CONDITION")
	
	if description_parent.costs_style is StyleBoxFlat:
		assert(description_parent.costs_style.resource_local_to_scene)
		description_parent.costs_style.bg_color = get_card_color.call(&"HIGHLIGHT_COST")
	
	description_parent.underline_condition_color = get_card_color.call(&"UNDERLINE_CONDITION")
	description_parent.underline_condition_tag = get_card_texture.call(&"CONDITION_TAG")
	description_parent.underline_cost_color = get_card_color.call(&"UNDERLINE_COST")
	description_parent.underline_cost_tag = get_card_texture.call(&"COST_TAG")
	
	if card.kind == Card.Kind.RULECARD:
		description_parent.highlight_sections = false
		description_parent.underline_sections = false
	description_parent.refresh()

func _refresh_grace():
	# frame
	frame.texture = get_card_texture.call(&"FRAME_ABILITY_GRACE")
	
	# name
	grace_name_label.text = card_ability.ability_name
	grace_name_label.add_theme_color_override(&"font_color", get_card_color.call(&"TEXT"))
	
	# description
	grace_description_label.text = card_ability.description
	grace_description_label.add_theme_color_override(&"font_color", get_card_color.call(&"TEXT"))


func _format_description(text: String) -> String:
	
	var condition: String
	var costs: String
	var effect: String
	
	var colon_pos := text.find(":")
	
	if colon_pos != -1:
		condition = text.substr(0, colon_pos)
	
	var semicolon_pos := text.find(";")
	
	if semicolon_pos != -1:
		costs = text.substr(colon_pos + 1 if colon_pos != -1 else 0, semicolon_pos)
	
	effect = text.substr(semicolon_pos + 1 if semicolon_pos != -1 else colon_pos + 1 if colon_pos != -1 else 0)
	
	var result: String = ""
	
	if condition:
		result += "%s%s:%s" % [condition_prefix, condition, condition_suffix]
	if costs:
		result += "%s%s;%s" % [costs_prefix, costs, costs_suffix]
	if effect:
		result += "%s%s%s" % [effect_prefix, effect, effect_suffix]
	
	return result
