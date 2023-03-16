@tool
extends Control

@export var card: Resource:
	get:
		return card
	set(value):
		card = value
		_refresh()

@export var ability_key: String:
	get:
		return ability_key
	set(value):
		ability_key = value
		_refresh()

@onready var cost := %AbilityScriptPanelCost
@onready var trigger := %AbilityScriptPanelTrigger
@onready var effect := %AbilityScriptPanelEffect

@onready var enable_checkbox := %EnableCheckBox
@onready var ability_enabled := %AbilityEnabled
@onready var ability_disabled := %AbilityDisabled

@onready var ability_type_option_button: OptionButton = %AbilityTypeOptionButton
@onready var name_edit = %NameEdit
@onready var description_edit = %DescriptionEdit

signal saved()
signal edit_script_requested(script: Script)

# Called when the node enters the scene tree for the first time.
func _ready():
	_refresh()

func _refresh():
	if not is_inside_tree():
		return
	
	enable_checkbox.button_pressed = card != null and ability_key != "" and card[ability_key] != null
	
	
	if not card or ability_key == "" or card[ability_key] == null:
		ability_enabled.visible = false
		ability_disabled.visible = true
		
		cost.ability = null
		trigger.ability = null
		effect.ability = null
		
		return
	
	ability_enabled.visible = true
	ability_disabled.visible = false
	
	var ability = card[ability_key]
	
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
	if type_prop:
		ability_type_option_button.clear()
		var hint_string: String = type_prop.hint_string
		var option_strs := hint_string.split(",")
		for option in option_strs:
			var split := option.split(":")
			var l := split[0]
			var v: int = int(split[1]) if split.size() == 2 else -1
			assert(v >= 0)
			ability_type_option_button.add_item(l, v)
		if card[ability_key]:
			ability_type_option_button.select(ability_type_option_button.get_item_index(card[ability_key][type_prop.name]))
	
	else:
		ability_enabled.visible = false
		ability_disabled.visible = true
	
	# Details
	
	cost.card = card
	cost.ability = ability
	cost.options = CardDatabase.get_all_ability_costs()
	
	trigger.card = card
	trigger.ability = ability
	trigger.options = CardDatabase.get_all_ability_triggers()
	
	effect.card = card
	effect.ability = ability
	effect.options = CardDatabase.get_all_ability_effects()
	



func _on_ability_script_panel_saved():
	saved.emit()


func _save():
	ResourceSaver.save(card)
	_refresh()
	saved.emit()


func _on_enable_check_box_toggled(button_pressed):
	if button_pressed and card[ability_key] == null:
		card[ability_key] = CardDatabase.ability_script.new()
		_save()
	elif not button_pressed and card[ability_key] != null:
		var confirm := ConfirmationDialog.new()
		confirm.title = "Confirm"
		var confirm_label := Label.new()
		confirm_label.text = "Deleting ability. Are you sure?"
		confirm.add_child(confirm_label)
		confirm.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
		confirm.confirmed.connect(func ():
			card[ability_key] = null
			_save())
		confirm.canceled.connect(func ():
			enable_checkbox.button_pressed = true)
		add_child(confirm)
		confirm.show()


func _on_name_edit_text_changed(new_text):
	card[ability_key].ability_name = new_text
	_save()


func _on_description_edit_text_changed():
	card[ability_key].description = description_edit.text
	_save()


func _on_ability_script_panel_edit_script_requested(script):
	edit_script_requested.emit(script)


func _on_ability_type_option_button_item_selected(index):
	var type := ability_type_option_button.get_item_id(index)
	card[ability_key].type = type
	_save()
