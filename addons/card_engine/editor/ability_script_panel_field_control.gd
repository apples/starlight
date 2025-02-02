@tool
extends MarginContainer

signal value_changed(new_value: Variant)

var value: Variant

var _prop_control: Control

func _init(ability_part: Object, prop: Dictionary, create_inner_panel: Callable):
	value = ability_part[prop.name]
	
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
					option_button.select(option_button.get_item_index(value) if value != null else option_button.get_selectable_item())
					option_button.item_selected.connect(_on_option_button_item_selected)
					_prop_control = option_button
				PROPERTY_HINT_FLAGS:
					var flags_container := GridContainer.new()
					flags_container.columns = 2
					
					for option in CardDatabase.get_enum_options(prop):
						var label_text: String = option[0]
						var value_mask: int = option[1]
						assert(value_mask > 0)
						
						var flag_check := CheckBox.new()
						flag_check.button_pressed = value & value_mask if value else 0
						flag_check.pressed.connect(_on_flag_check_pressed.bind(flag_check, value_mask))
						flags_container.add_child(flag_check)
						
						var flag_label := Label.new()
						flag_label.text = label_text
						flags_container.add_child(flag_label)
					
					_prop_control = flags_container
				_:
					var spinbox := SpinBox.new()
					spinbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
					spinbox.allow_greater = true
					spinbox.allow_lesser = true
					spinbox.min_value = -100
					spinbox.value = value if value != null else 0
					spinbox.value_changed.connect(_on_spinbox_value_changed)
					_prop_control = spinbox
		TYPE_STRING:
			var lineedit := LineEdit.new()
			lineedit.text = value
			lineedit.text_submitted.connect(_on_lineedit_text_submitted)
			lineedit.focus_exited.connect(_on_lineedit_focus_exited)
			_prop_control = lineedit
		TYPE_BOOL:
			var checkbox := CheckBox.new()
			checkbox.button_pressed = value
			checkbox.toggled.connect(_on_checkbox_toggled)
			_prop_control = checkbox
		TYPE_OBJECT:
			if prop.hint == PROPERTY_HINT_RESOURCE_TYPE:
				match prop.hint_string:
					"CardAbilityTrigger":
						_prop_control = create_inner_panel.call(prop.name, "Trigger", "trigger")
					"CardAbilityEffect":
						_prop_control = create_inner_panel.call(prop.name, "Effect", "effect")
			else:
				breakpoint
		_:
			breakpoint
	
	if not _prop_control:
		push_error("Ability part %s has field %s of unsupported type %s." % [ability_part, prop.name, type_string(prop.type)])
		var error_label := Label.new()
		error_label.text = "(not supported)"
		error_label.size_flags_vertical = Control.SIZE_FILL
		_prop_control = error_label
	
	add_child(_prop_control)

func _on_option_button_item_selected(index: int) -> void:
	value = (_prop_control as OptionButton).get_item_id(index)
	value_changed.emit(value)

func _on_flag_check_pressed(flag_check: CheckBox, value_mask: int) -> void:
	if flag_check.button_pressed:
		value |= value_mask
	else:
		value &= ~value_mask
	value_changed.emit(value)

func _on_spinbox_value_changed(new_value: float) -> void:
	value = roundi(new_value)
	value_changed.emit(value)

func _on_lineedit_text_submitted(new_value: String) -> void:
	value = new_value
	value_changed.emit(value)

func _on_lineedit_focus_exited():
	value = (_prop_control as LineEdit).text
	value_changed.emit(value)

func _on_checkbox_toggled(toggled_on: bool) -> void:
	value = toggled_on
	value_changed.emit(value)
