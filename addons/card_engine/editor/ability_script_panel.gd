@tool
extends Control

const AbilityScriptPanelFieldControl = preload("res://addons/card_engine/editor/ability_script_panel_field_control.gd")

@export var card: Resource

@export var ability: Resource:
	get:
		return ability
	set(value):
		ability = value
		if is_inside_tree():
			_reset_script_text()
			_reset_fields()

@export var panel_label: String:
	get:
		return panel_label
	set(value):
		panel_label = value
		if type_label:
			type_label.text = panel_label

@export var script_key: String
@export var is_array: bool = false

@export var options: Array[String] = []:
	get:
		return options
	set(value):
		options = value
		if is_inside_tree():
			_reset_script_text()

@export var new_script_dialog := preload("res://addons/card_engine/editor/new_script_dialog.tscn")

@onready var type_label: Label = %TypeLabel
@onready var script_path_edit: LineEdit = %ScriptPathEdit
@onready var script_path_popup: Window = %ScriptPathPopupMenu
@onready var properties_container: Control = %PropertiesContainer
@onready var properties: Control = %Properties
@onready var clear_button: Button = %ClearButton
@onready var edit_button: Button = %EditButton
@onready var minimize_button: Button = %MinimizeButton
@onready var minimize_hint = %MinimizeHint
@onready var properties_inner_container = %PropertiesInnerContainer

var ability_script_panel_scene := load("res://addons/card_engine/editor/ability_script_panel.tscn")
var variable_property_control_scene := preload("res://addons/card_engine/editor/variable_property_control.tscn")

var script_kind: String = ""

signal saved()
signal edit_script_requested(script: Script)
signal cleared()

var filtered_options: Array[String] = []

var variable_options: Array[String] = []:
	get:
		return variable_options
	set(value):
		variable_options = value
		if is_inside_tree():
			_reset_fields()

var is_minimized: bool:
	get:
		return not properties_inner_container.visible
	set(value):
		if properties:
			properties_inner_container.visible = not value
			minimize_hint.visible = not properties_inner_container.visible
			minimize_button.text = "◰" if value else "—"

var _property_controls: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	if script_kind == "":
		script_kind = script_key.split(".", true, 1)[0]
	
	type_label.text = panel_label
	_reset_script_text()
	_reset_fields()

func get_ability_part():
	if is_array:
		var arr = ability
		for k in script_key.split("."):
			arr = arr[k]
		
		if get_index() < arr.size():
			return arr[get_index()]
		else:
			return null
	else:
		var f = ability
		for k in script_key.split("."):
			f = f[k]
		assert(f != ability)
		return f

func set_ability_part(value) -> void:
	if is_array:
		var arr = ability
		for k in script_key.split("."):
			arr = arr[k]
		
		if get_index() < arr.size():
			arr[get_index()] = value
		else:
			assert(get_index() == arr.size())
			arr.append(value)
	else:
		var f = ability
		var pf
		var kk: String
		for k in script_key.split("."):
			pf = f
			kk = k
			f = pf[kk]
		
		assert(pf)
		pf[kk] = value

func _reset_script_text():
	if ability:
		clear_button.disabled = false
		if get_ability_part():
			script_path_edit.text = get_ability_part().get_script().resource_path.get_file()
		else:
			script_path_edit.text = ""
	else:
		script_path_edit.text = ""
		clear_button.disabled = true
		edit_button.disabled = true

func _update_filtered_options():
	script_path_popup.clear()
	filtered_options = []
	for i in range(options.size()):
		var o := options[i]
		var f := o.get_file()
		if script_path_popup.edit.text == "" or f.to_lower().contains(script_path_popup.edit.text):
			script_path_popup.add_item(f, i)
			filtered_options.append(o)

func _reset_fields():
	if not ability or not get_ability_part():
		properties_container.visible = false
		edit_button.disabled = true
		return
	
	is_minimized = false
	
	properties_container.visible = true
	edit_button.disabled = false
	
	for c in properties.get_children():
		c.queue_free()
		properties.remove_child(c)
	
	_property_controls = {}
	
	var ability_part = get_ability_part()
	var script := ability_part.get_script() as Script
	assert(script)
	
	var prop_dict := {}
	var value_props: Array[String] = []
	
	for prop in script.get_script_property_list():
		if not (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		
		prop_dict[prop.name] = prop
		
		if prop.name.ends_with("_var"):
			continue
		
		value_props.append(prop.name)
	
	for prop_name: String in value_props:
		var prop = prop_dict[prop_name]
		
		var label := Label.new()
		label.text = "%s:" % prop.name
		label.size_flags_vertical = Control.SIZE_FILL
		properties.add_child(label)
		
		var prop_control: Control = AbilityScriptPanelFieldControl.new(get_ability_part(), prop, _create_inner_panel)
		prop_control.value_changed.connect(_set_property.bind(prop.name))
		
		var varprop_name: String = prop.name + "_var"
		if varprop_name in prop_dict:
			if prop_dict[varprop_name].type != TYPE_STRING:
				push_error("Ability script (%s) has incorrect type for varprop %s (should be String)." % [script.resource_path, varprop_name])
			else:
				var variable_property_control := variable_property_control_scene.instantiate()
				variable_property_control.variable_text = ability_part[varprop_name]
				variable_property_control.add_fixed_value_control(prop_control)
				variable_property_control.set_options(variable_options)
				
				variable_property_control.variable_changed.connect(_set_property.bind(varprop_name))
				
				prop_control = variable_property_control
		
		properties.add_child(prop_control)
		
		_property_controls[prop.name] = [label, prop_control]
	
	_update_visibility()

func _update_visibility():
	var ability_part = get_ability_part()
	if not ability_part.has_method("get_property_display"):
		return
	for prop in _property_controls:
		var v = ability_part.get_property_display(prop)
		for c in _property_controls[prop]:
			c.visible = v

func _create_inner_panel(propname: String, label: String, kind: String) -> Control:
	var panel = ability_script_panel_scene.instantiate()
	panel.card = card
	panel.ability = ability
	panel.panel_label = label
	panel.script_key = "%s.%s" % [script_key, propname]
	panel.script_kind = kind
	panel.options = CardDatabase.call("get_all_ability_%ss" % kind)
	panel.saved.connect(_on_inner_panel_saved)
	panel.edit_script_requested.connect(_on_inner_panel_edit_script_requested)
	var vo := variable_options.duplicate()
	vo.append_array(get_ability_part().get_variable_names())
	panel.variable_options = vo
	return panel

func _on_inner_panel_saved():
	saved.emit()

func _on_inner_panel_edit_script_requested(script: Script):
	edit_script_requested.emit(script)

func _set_property(value, prop_name: String):
	get_ability_part()[prop_name] = value
	_save()
	_update_visibility()

func _on_choose_button_pressed():
	_open_search()

func _open_search():
	var edit_pos := script_path_edit.get_screen_position()
	var edit_xform := script_path_edit.get_global_transform_with_canvas()
	var edit_size := edit_xform.get_scale() * script_path_edit.size
	script_path_popup.position = edit_pos
	script_path_popup.size = Vector2i(edit_size.x, edit_size.y * 10)
	script_path_popup.edit.text = ""
	script_path_popup.edit.call_deferred("grab_focus")
	script_path_popup.popup()
	_update_filtered_options()


func _on_script_path_edit_text_submitted(new_text):
	script_path_popup.hide()
	var selected
	for o in options:
		if o.get_file() == new_text:
			selected = o
			break
	if selected == null:
		_reset_script_text()
	else:
		_set_new_script(selected)


func _set_new_script(o: String):
	if o == "":
		set_ability_part(null)
		_save()
		_reset_script_text()
		_reset_fields()
		return
	
	assert(FileAccess.file_exists(o))
	
	# Setting the script without actually changing it would normally reset the
	# field values too, so check here to make sure we keep existing values.
	if get_ability_part():
		var current = get_ability_part().get_script().resource_path
		if current == o:
			return
	
	set_ability_part(load(o).new())
	_save()
	_reset_script_text()
	_reset_fields()

func _save():
	ResourceSaver.save(card)
	saved.emit()

func _on_script_path_popup_menu_id_pressed(id):
	_set_new_script(options[id])


func _on_clear_button_pressed():
	_set_new_script("")
	_reset_fields()
	cleared.emit()


func _on_script_path_popup_menu_close_requested():
	script_path_edit.release_focus()


func _on_line_edit_text_changed(new_text):
	_update_filtered_options()


func _on_line_edit_text_submitted(new_text):
	if filtered_options.size() > 0:
		_set_new_script(filtered_options[0])
	script_path_popup.hide()


func _on_script_path_popup_menu_selected_id(id):
	_set_new_script(options[id])


func _on_script_path_edit_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
			_open_search()


func _on_new_button_pressed():
	var dialog := new_script_dialog.instantiate()
	
	dialog.canceled.connect(func ():
		dialog.queue_free())
	
	dialog.check_error = func (str: String):
		if str == "":
			return "Cannot be empty"
		if str.contains(" "):
			return "Cannot contain spaces"
		var forbidden := "/\\|?*<>:\""
		for c in forbidden:
			if str.contains(c):
				return "Cannot contain %s" % c
		
		var script_name := str if str.ends_with(".gd") else ("%s.gd" % str)
		var path := CardDatabase.get_script_path(script_kind, script_name)
		if FileAccess.file_exists(path):
			return "File already exists"
		
		return ""
	
	add_child(dialog)
	dialog.show()
	
	var str: String = await dialog.submit
	
	dialog.queue_free()
	
	if str == "":
		print("Empty script name, cancelling")
		return
	
	var script_name := str if str.ends_with(".gd") else ("%s.gd" % str)
	
	var path := CardDatabase.create_script(script_kind, script_name)
	
	options.append(path)
	_set_new_script(path)




func _on_edit_button_pressed():
	if get_ability_part() == null:
		print("Null ability script")
		return
	var script := get_ability_part().get_script() as Script
	if script == null:
		print("Ability script has... no script...")
		return
	
	print("Opening %s" % script.resource_path)
	edit_script_requested.emit(script)





func _on_minimize_button_pressed():
	is_minimized = not is_minimized
