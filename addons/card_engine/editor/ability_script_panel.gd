@tool
extends Control

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

var ability_script_panel_scene := preload("res://addons/card_engine/editor/ability_script_panel.tscn")
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
		assert(arr != ability)
		
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
		assert(arr != ability)
		
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
	
	while properties.get_child_count() > 0:
		var c := properties.get_child(0)
		c.queue_free()
		properties.remove_child(c)
	
	var ability_part = get_ability_part()
	var script := ability_part.get_script() as Script
	assert(script)
	
	for prop in script.get_script_property_list():
		if not (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		
		if prop.name.ends_with("_var"):
			continue
		
		var label := Label.new()
		label.text = "%s:" % prop.name
		label.size_flags_vertical = Control.SIZE_FILL
		properties.add_child(label)
		
		var current_value = get_ability_part()[prop.name]
		
		var prop_control: Control
		
		match prop.type:
			TYPE_INT:
				match prop.hint:
					PROPERTY_HINT_ENUM:
						var option_button := OptionButton.new()
						option_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
						for option in CardDatabase.get_enum_options(prop):
							var l = option[0]
							var v = option[1]
							assert(v >= 0)
							option_button.add_item(l, v)
						option_button.select(option_button.get_item_index(current_value))
						option_button.item_selected.connect(func (idx):
							_set_property(prop.name, option_button.get_item_id(idx))
						)
						prop_control = option_button
					PROPERTY_HINT_FLAGS:
						var flags_container := GridContainer.new()
						flags_container.columns = 2
						
						for option in CardDatabase.get_enum_options(prop):
							var l = option[0]
							var v = option[1]
							assert(v > 0)
							
							var flag_check := CheckBox.new()
							flag_check.button_pressed = current_value & v
							flag_check.pressed.connect(func ():
								var cur_v: int = get_ability_part()[prop.name]
								if flag_check.button_pressed:
									cur_v |= v
								else:
									cur_v &= ~v
								_set_property(prop.name, cur_v))
							flags_container.add_child(flag_check)
							
							var flag_label := Label.new()
							flag_label.text = l
							flags_container.add_child(flag_label)
						
						prop_control = flags_container
					_:
						var spinbox := SpinBox.new()
						spinbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
						spinbox.value = current_value if current_value != null else 0
						spinbox.value_changed.connect(func (new_value):
							_set_property(prop.name, new_value)
						)
						prop_control = spinbox
			TYPE_STRING:
				var lineedit := LineEdit.new()
				lineedit.text = current_value
				lineedit.text_submitted.connect(func (new_value):
					_set_property(prop.name, new_value)
				)
				lineedit.focus_exited.connect(func ():
					_set_property(prop.name, lineedit.text)
				)
				prop_control = lineedit
			TYPE_BOOL:
				var checkbox := CheckBox.new()
				checkbox.button_pressed = current_value == true
				checkbox.toggled.connect(func (new_value):
					_set_property(prop.name, new_value)
				)
				prop_control = checkbox
			TYPE_OBJECT:
				if prop.hint == PROPERTY_HINT_RESOURCE_TYPE:
					match prop.hint_string:
						"CardAbilityTrigger":
							prop_control = _create_inner_panel(prop.name, "Trigger", "trigger")
						"CardAbilityEffect":
							prop_control = _create_inner_panel(prop.name, "Effect", "effect")
				else:
					assert(false)
					push_error("Not supported!")
			_:
				assert(false)
				push_error("Not supported!")
		
		if prop_control != null:
			var varprop_name: String = prop.name + "_var"
			if varprop_name in ability_part:
				var variable_property_control := variable_property_control_scene.instantiate()
				properties.add_child(variable_property_control)
				
				variable_property_control.initialize(prop_control, ability_part[varprop_name])
				variable_property_control.set_options(variable_options)
				
				variable_property_control.variable_changed.connect(func (new_value):
					_set_property(varprop_name, new_value))
			else:
				properties.add_child(prop_control)

func _create_inner_panel(propname: String, label: String, kind: String) -> Control:
	var panel := ability_script_panel_scene.instantiate()
	panel.card = card
	panel.ability = ability
	panel.panel_label = label
	panel.script_key = "%s.%s" % [script_key, propname]
	panel.script_kind = kind
	panel.options = CardDatabase.call("get_all_ability_%ss" % kind)
	panel.saved.connect(_on_inner_panel_saved)
	panel.edit_script_requested.connect(_on_inner_panel_edit_script_requested)
	var vo := variable_options.duplicate()
	vo.append_array(get_ability_part().get_output_variables())
	panel.variable_options = vo
	return panel

func _on_inner_panel_saved():
	saved.emit()

func _on_inner_panel_edit_script_requested(script: Script):
	edit_script_requested.emit(script)

func _set_property(prop_name: String, value):
	get_ability_part()[prop_name] = value
	_save()

func _on_choose_button_pressed():
	_open_search()

func _open_search():
	script_path_popup.show()
	var edit_pos := script_path_edit.get_screen_position()
	var edit_xform := script_path_edit.get_global_transform_with_canvas()
	var edit_size := edit_xform.get_scale() * script_path_edit.size
	script_path_popup.position = edit_pos
	script_path_popup.size.x = edit_size.x
	script_path_popup.edit.text = ""
	script_path_popup.edit.call_deferred("grab_focus")
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
