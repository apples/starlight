@tool
extends Control

@onready var overlays := %NormalOverlays
@onready var frame := %Frame
@onready var type_rect: TextureRect = %Type
@onready var attack_power_frame := %AttackPowerFrame
@onready var attack_power_label: Label = %AttackPower
@onready var name_label: Label = %Name

@onready var description_label: IconLabel = %Description
@onready var normal_header_row = %NormalHeaderRow

@onready var grace_overlays := %GraceOverlays
#@onready var grace_name_label: Label = %GraceName
@onready var grace_description_label: IconLabel = %GraceDescription

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
		#Card.Kind.RULECARD:
			#frame.texture = get_card_texture.call(&"FRAME_ABILITY_RULECARD")
		Card.Kind.UNIT:
			frame.texture = get_card_texture.call(&"FRAME_ABILITY")
		Card.Kind.SPELL:
			frame.texture = get_card_texture.call(&"FRAME_ABILITY_SPELL")
		Card.Kind.TRAP:
			frame.texture = get_card_texture.call(&"FRAME_ABILITY_SPELL_TRIGGER")
	
	#if card.kind == Card.Kind.RULECARD:
		#normal_header_row.visible = false
	#else:
	
	normal_header_row.visible = true
	
	# type
	match [card.kind, card_ability.type]:
		[Card.Kind.SPELL, _], [Card.Kind.TRAP, _]:
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
	
	# description
	
	var special_conditions := ""
	var trigger := ""
	var costs := ""
	var effects_and_conditions := ""
	
	var desc_text := card_ability.description
	
	var special_cond_regex := RegEx.create_from_string("^(\\{\\{.*?\\}\\}|\\(.*?\\))")
	
	var j: int = 0
	while desc_text:
		var m := special_cond_regex.search(desc_text)
		if not m:
			desc_text = desc_text.lstrip(" ")
			break
		special_conditions += m.get_string()
		desc_text = desc_text.substr(m.get_end())
	
	if desc_text.begins_with("{{") or desc_text.begins_with("("):
		var special_cond_split := desc_text.split(" ", true, 1)
		special_conditions = special_cond_split[0]
		desc_text = special_cond_split[1] if special_cond_split.size() == 2 else ""
	
	var trigger_split := desc_text.split(":", true, 1)
	if trigger_split.size() == 2:
		trigger = trigger_split[0]
		desc_text = trigger_split[1].lstrip(" ")
	
	var costs_split := desc_text.split(";", true, 1)
	if costs_split.size() == 2:
		costs = costs_split[0]
		desc_text = costs_split[1].lstrip(" ")
	
	effects_and_conditions = desc_text
	
	if card_ability.cost:
		var icon_costs := ""
		if card_ability.cost.get_requires_tap():
			icon_costs += "{{tap}}"
		for i in card_ability.cost.get_mana_cost():
			icon_costs += "{{mana}}"
		if card_ability.cost.get_once_per_turn():
			special_conditions += "{{once_per_turn}}"
		if icon_costs:
			if costs:
				costs = icon_costs + ", " + costs
			else:
				costs = icon_costs
	
	var result_desc_text := ""
	
	if special_conditions:
		result_desc_text += special_conditions
	
	if trigger:
		if result_desc_text:
			result_desc_text += " "
		result_desc_text += trigger + ":"
	
	if costs:
		if result_desc_text:
			result_desc_text += " "
		var k := 0
		while k < costs.length():
			if costs[k] != "\n":
				break
			k += 1
		result_desc_text += costs.substr(0, k) + "{{cost}}" + costs.substr(k) + "{{cost_rt}};"
	
	if effects_and_conditions:
		if result_desc_text:
			result_desc_text += " "
		result_desc_text += effects_and_conditions
	
	description_label.text = result_desc_text
	
	#description_label.text = card_ability.description#.replace(":", "：").replace(";", "；")
	description_label.add_theme_color_override(&"font_color", get_card_color.call(&"TEXT"))
	
	var condition_style = description_label.highlights[0].style if description_label.highlights.size() > 0 and description_label.highlights[0] else null
	var costs_style = description_label.highlights[1].style if description_label.highlights.size() > 1 and description_label.highlights[1] else null
	
	if condition_style is StyleBoxFlat:
		assert(condition_style.resource_local_to_scene)
		condition_style.bg_color = get_card_color.call(&"HIGHLIGHT_CONDITION")
	
	if costs_style is StyleBoxFlat:
		assert(costs_style.resource_local_to_scene)
		costs_style.bg_color = get_card_color.call(&"HIGHLIGHT_COST")
	
	description_label.mark_dirty()
	
	#description_parent.underline_condition_color = get_card_color.call(&"UNDERLINE_CONDITION")
	#description_parent.underline_condition_tag = get_card_texture.call(&"CONDITION_TAG")
	#description_parent.underline_cost_color = get_card_color.call(&"UNDERLINE_COST")
	#description_parent.underline_cost_tag = get_card_texture.call(&"COST_TAG")
	
	#if card.kind == Card.Kind.RULECARD:
		#description_parent.highlight_sections = false
		#description_parent.underline_sections = false
	#description_parent.refresh()
	

func _refresh_grace():
	# frame
	frame.texture = get_card_texture.call(&"FRAME_ABILITY_GRACE")
	
	# name
	#grace_name_label.text = card_ability.ability_name
	#grace_name_label.add_theme_color_override(&"font_color", get_card_color.call(&"TEXT"))
	
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
