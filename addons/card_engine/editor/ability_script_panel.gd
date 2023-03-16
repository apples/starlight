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

signal saved()
signal edit_script_requested(script: Script)

var filtered_options: Array[String] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	script_path_popup.selected_id.connect(_on_script_path_popup_menu_id_pressed)
	type_label.text = panel_label
	_reset_script_text()
	_reset_fields()

func _reset_script_text():
	if ability:
		clear_button.disabled = false
		if ability[script_key]:
			script_path_edit.text = ability[script_key].get_script().resource_path.get_file()
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
	if not ability or not ability[script_key]:
		properties_container.visible = false
		edit_button.disabled = true
		return
	
	properties_container.visible = true
	edit_button.disabled = false
	
	while properties.get_child_count() > 0:
		var c := properties.get_child(0)
		c.queue_free()
		properties.remove_child(c)
	
	var script := ability[script_key].get_script() as Script
	assert(script)
	
	for prop in script.get_script_property_list():
		if not (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		
		var label := Label.new()
		label.text = "%s:" % prop.name
		properties.add_child(label)
		
		var current_value = ability[script_key][prop.name]
		
		match prop.type:
			TYPE_INT:
				match prop.hint:
					PROPERTY_HINT_ENUM:
						var option_button := OptionButton.new()
						var hint_string: String = prop.hint_string
						var option_strs := hint_string.split(",")
						for option in option_strs:
							var split := option.split(":")
							var l := split[0]
							var v: int = int(split[1]) if split.size() == 2 else -1
							assert(v >= 0)
							option_button.add_item(l, v)
						option_button.select(option_button.get_item_index(current_value))
						option_button.item_selected.connect(func (idx):
							_set_property(prop.name, option_button.get_item_id(idx))
						)
						properties.add_child(option_button)
					_:
						var spinbox := SpinBox.new()
						spinbox.value = current_value if current_value != null else 0
						spinbox.value_changed.connect(func (new_value):
							_set_property(prop.name, new_value)
						)
						properties.add_child(spinbox)
			TYPE_STRING:
				var lineedit := LineEdit.new()
				lineedit.text = current_value
				lineedit.text_submitted.connect(func (new_value):
					_set_property(prop.name, new_value)
				)
				lineedit.focus_exited.connect(func ():
					_set_property(prop.name, lineedit.text)
				)
				properties.add_child(lineedit)
			TYPE_BOOL:
				var checkbox := CheckBox.new()
				checkbox.button_pressed = current_value
				checkbox.toggled.connect(func (new_value):
					_set_property(prop.name, new_value)
				)
				properties.add_child(checkbox)
			_:
				assert(false)
				push_error("Not supported!")

func _set_property(prop_name: String, value):
	ability[script_key][prop_name] = value
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
	script_path_popup.edit.text = script_path_edit.text
	script_path_popup.edit.call_deferred("grab_focus")
	script_path_popup.edit.call_deferred("select_all")
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
		script_path_edit.text = ""
		ability[script_key] = null
		_save()
		
		_reset_fields()
		return
	
	assert(FileAccess.file_exists(o))
	
	script_path_edit.text = o.get_file()
	if ability[script_key]:
		var current = ability[script_key].get_script().resource_path
		if current == o:
			return
	ability[script_key] = load(o).new()
	_save()
	_reset_fields()

func _save():
	ResourceSaver.save(card)
	saved.emit()

func _on_script_path_popup_menu_id_pressed(id):
	_set_new_script(options[id])


func _on_clear_button_pressed():
	_set_new_script("")
	_reset_fields()


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
	
	var path := CardDatabase.create_script(script_key, script_name)
	
	options.append(path)
	_set_new_script(path)




func _on_edit_button_pressed():
	if ability[script_key] == null:
		print("Null ability script")
		return
	var script := ability[script_key].get_script() as Script
	if script == null:
		print("Ability script has... no script...")
		return
	
	print("Opening %s" % script.resource_path)
	edit_script_requested.emit(script)



