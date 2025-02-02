@tool
extends Control

@onready var cost := %AbilityScriptPanelCost
@onready var trigger := %AbilityScriptPanelTrigger
@onready var effect := %AbilityScriptPanelEffect
@onready var passive := %AbilityScriptPanelPassive

@onready var ability_type_option_button: OptionButton = %AbilityTypeOptionButton
@onready var name_edit = %NameEdit
@onready var description_edit = %DescriptionEdit

@onready var delete_button = %DeleteButton
@onready var copy_button = %CopyButton
@onready var paste_button = %PasteButton

@onready var conditions_container = %ConditionsContainer
@onready var add_condition_button = %AddConditionButton

@onready var is_uninterruptable_container = %IsUninterruptableContainer
@onready var is_uninterruptable_check_button = %IsUninterruptableCheckButton

var ability_script_panel_scene = preload("res://addons/card_engine/editor/ability_script_panel.tscn")
var ability_script_panel_condition_scene = preload("res://addons/card_engine/editor/ability_script_panel_condition.tscn")

var card: Resource
var ability_idx: int

var enable_paste: bool:
	get:
		return enable_paste
	set(value):
		enable_paste = value
		if paste_button:
			paste_button.disabled = not enable_paste

signal saved()
signal edit_script_requested(script: Script)
signal delete(ability_tab)
signal copy(ability_tab)
signal paste(ability_tab)

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.is_editor_hint() and (EditorInterface.get_edited_scene_root() == self or EditorInterface.get_edited_scene_root().is_ancestor_of(self)):
		return
	_refresh()

func set_value(p_card: Resource, p_idx: int):
	card = p_card
	ability_idx = p_idx
	_refresh()

func _get_ability():
	return card.abilities[ability_idx]

func _refresh():
	if not is_inside_tree():
		return
	
	assert(card)
	assert(_get_ability())
	
	paste_button.disabled = not enable_paste
	
	var ability: CardAbility = _get_ability()
	
	# Text
	
	if name_edit.text != ability.ability_name:
		name_edit.text = ability.ability_name
	if description_edit.text != ability.description:
		description_edit.text = ability.description
	
	# Type
	
	var type_prop
	for prop in CardDatabase.ability_script.get_script_property_list():
		if prop.name == "type":
			type_prop = prop
			break
	assert(type_prop != null)
	
	ability_type_option_button.clear()
	for option in CardDatabase.get_enum_options(type_prop):
		var l = option[0]
		var v = option[1]
		assert(v >= 0)
		ability_type_option_button.add_item(l, v)
	ability_type_option_button.select(ability_type_option_button.get_item_index(ability[type_prop.name]))
	
	# Is Uninterruptable
	
	match ability.type:
		CardAbility.CardAbilityType.ACTION, \
		CardAbility.CardAbilityType.ATTACK, \
		CardAbility.CardAbilityType.DEFEND, \
		CardAbility.CardAbilityType.TRIGGER:
			is_uninterruptable_container.visible = true
			is_uninterruptable_check_button.button_pressed = ability.is_uninterruptable == true
		_:
			is_uninterruptable_container.visible = false
	
	# Conditions
	
	var variable_options: Array[String] = []
	
	for i in range(ability.conditions.size()):
		var panel
		if i >= conditions_container.get_child_count() - 1:
			panel = _add_condition_panel()
		else:
			panel = conditions_container.get_child(i)
		panel.card = card
		panel.ability = ability
		panel.options = CardDatabase.get_all_ability_conditions()
		panel.variable_options = variable_options
		
		if ability.conditions[i]:
			variable_options = variable_options.duplicate()
			variable_options.append_array(ability.conditions[i].get_variable_names())
	
	for i in range(ability.conditions.size(), conditions_container.get_child_count() - 1):
		conditions_container.get_child(i).queue_free()
	
	# Details
	
	trigger.card = card
	trigger.ability = ability
	trigger.options = CardDatabase.get_all_ability_triggers()
	trigger.variable_options = variable_options
	
	if ability[trigger.script_key]:
		variable_options = variable_options.duplicate()
		variable_options.append_array(ability[trigger.script_key].get_variable_names())
	
	cost.card = card
	cost.ability = ability
	cost.options = CardDatabase.get_all_ability_costs()
	cost.variable_options = variable_options
	
	if ability[cost.script_key]:
		variable_options = variable_options.duplicate()
		variable_options.append_array(ability[cost.script_key].get_variable_names())
	
	effect.card = card
	effect.ability = ability
	effect.options = CardDatabase.get_all_ability_effects()
	effect.variable_options = variable_options
	
	if ability[effect.script_key]:
		variable_options = variable_options.duplicate()
		variable_options.append_array(ability[effect.script_key].get_variable_names())
	
	passive.card = card
	passive.ability = ability
	passive.options = CardDatabase.get_all_ability_passives()
	passive.variable_options = variable_options
	
	if ability[passive.script_key]:
		variable_options = variable_options.duplicate()
		variable_options.append_array(ability[passive.script_key].get_variable_names())
	
	_refresh_visibility()

func _refresh_visibility():
	var ability = _get_ability()
	if ability == null:
		return
	
	var CAT = CardDatabase.ability_script.CardAbilityType
	
	match ability.type:
		CAT.TRIGGER:
			trigger.visible = true
			cost.visible = true
			effect.visible = true
			passive.visible = false
		CAT.PASSIVE:
			trigger.visible = false
			cost.visible = false
			effect.visible = false
			passive.visible = true
		_:
			trigger.visible = false
			cost.visible = true
			effect.visible = true
			passive.visible = false


func _on_ability_script_panel_saved():
	_refresh()
	saved.emit()


func _save():
	ResourceSaver.save(card)
	_refresh()
	saved.emit()



func _on_name_edit_text_changed(new_text):
	_get_ability().ability_name = new_text
	_save()


func _on_description_edit_text_changed():
	_get_ability().description = description_edit.text
	_save()


func _on_ability_script_panel_edit_script_requested(script):
	edit_script_requested.emit(script)


func _on_ability_type_option_button_item_selected(index):
	var type := ability_type_option_button.get_item_id(index)
	
	if _get_ability().type == type:
		return
	
	var CAT = CardDatabase.ability_script.CardAbilityType
	
	match type:
		CAT.PASSIVE:
			await _confirm_clear_script("trigger")
			await _confirm_clear_script("cost")
			await _confirm_clear_script("effect")
			_get_ability().trigger = null
			_get_ability().cost = null
			_get_ability().effect = null
		CAT.TRIGGER:
			await _confirm_clear_script("passive")
			_get_ability().passive = null
		_:
			await _confirm_clear_script("trigger")
			await _confirm_clear_script("passive")
			_get_ability().trigger = null
			_get_ability().passive = null
	
	_get_ability().type = type
	
	match type:
		CAT.ATTACK:
			if _get_ability().conditions.is_empty():
				_get_ability().conditions.append(load("res://data/cards/abilities/conditions/basic_attack_condition.gd").new())
			if _get_ability().cost == null:
				var cost = load("res://data/cards/abilities/costs/generic_cost.gd").new()
				cost.unit_target_count = 1
				cost.unit_target_zones_var = "basic_attack_target_zones"
				_get_ability().cost = cost
			if _get_ability().effect == null:
				_get_ability().effect = load("res://data/cards/abilities/effects/attack.gd").new()
	
	_save()
	_refresh_visibility()

func _confirm_clear_script(key: String):
	if _get_ability()[key] != null:
		var dialog := ConfirmationDialog.new()
		dialog.title = "Are you sure?"
		dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
		var label := Label.new()
		label.text = "There is a %s script on this ability.\nChanging the type will remove this script.\nThis cannot be undone." % key
		dialog.add_child(label)
		add_child(dialog)
		dialog.show()
		dialog.canceled.connect(func ():
			dialog.queue_free())
		await dialog.confirmed
		dialog.queue_free()
	

func _on_delete_button_pressed():
	delete.emit(self)

func _on_copy_button_pressed():
	copy.emit(self)


func _on_paste_button_pressed():
	paste.emit(self)


func _on_add_condition_button_pressed():
	var ability: CardAbility = _get_ability()
	if ability.conditions.size() < conditions_container.get_child_count() - 1:
		return
	
	_add_condition_panel()


func _add_condition_panel():
	var ability: CardAbility = _get_ability()
	
	var panel = ability_script_panel_condition_scene.instantiate()
	panel.panel_label = "Condition%s" % (conditions_container.get_child_count() - 1)
	panel.script_key = "conditions"
	panel.is_array = true
	panel.card = card
	panel.ability = ability
	panel.options = CardDatabase.get_all_ability_conditions()
	panel.saved.connect(_on_ability_script_panel_saved)
	panel.edit_script_requested.connect(_on_ability_script_panel_edit_script_requested)
	panel.cleared.connect(func ():
		if panel.get_index() < ability.conditions.size():
			ability.conditions.remove_at(panel.get_index())
		conditions_container.remove_child(panel)
		panel.queue_free()
		_save())
	conditions_container.add_child(panel)
	conditions_container.move_child(add_condition_button, -1)
	
	return panel


func _on_is_uninterruptable_check_button_toggled(button_pressed):
	_get_ability().is_uninterruptable = button_pressed
	_save()
