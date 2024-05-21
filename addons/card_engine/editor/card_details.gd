@tool
extends HSplitContainer

@export var card: Resource = null:
	set(value):
		card = value
		if is_inside_tree():
			_refresh()

@export var for_print: bool = false:
	set(v):
		for_print = v
		if is_inside_tree():
			_refresh()

@onready var card_preview_container := %CardPreviewContainer

@onready var design_notes_text_edit = %DesignNotesTextEdit
@onready var notes_save_timer = %NotesSaveTimer
@onready var save_indicator = %SaveIndicator
@onready var tab_container: TabContainer = %CardDetailsTabContainer

var ability_tab_scene := preload("res://addons/card_engine/editor/ability_tab.tscn")

var card_control: Control
var design_note: CardEngineDesignNote
var ability_clipboard: Resource:
	get:
		return ability_clipboard
	set(value):
		ability_clipboard = value
		if is_inside_tree():
			for i in range(_ability_tab_count()):
				_ability_tab_get(i).enable_paste = ability_clipboard != null

var prev_card

signal edit_script_requested(script: Script)

func _ready():
	_refresh()

func _refresh():
	_save_notes()
	
	if card:
		if card_control:
			card_control.card = card
			card_control.for_print = for_print
		else:
			card_control = CardDatabase.config.card_control.instantiate()
			card_control.card = card
			card_control.for_print = for_print
			card_preview_container.add_child(card_control)
		
		design_note = CardDatabase.get_design_note(card)
		design_notes_text_edit.editable = true
		design_notes_text_edit.text = design_note.text
		
		tab_container.set_tab_disabled(_get_plus_tab(), false)
		
		for i in card.abilities.size():
			if i >= _ability_tab_count():
				_ability_tab_append(i)
			else:
				_ability_tab_get(i).set_value(card, i)
				_ability_tab_get(i).enable_paste = ability_clipboard != null
		
		for i in range(card.abilities.size(), _ability_tab_count()):
			_ability_tab_get(i).queue_free()
		
		if prev_card != card:
			tab_container.current_tab = 0
	else:
		if card_preview_container.get_child_count() > 0:
			var c := card_preview_container.get_child(0)
			assert(c == card_control)
			c.queue_free()
			card_preview_container.remove_child(c)
			card_control = null
		
		design_note = null
		design_notes_text_edit.editable = false
		design_notes_text_edit.text = ""
		
		tab_container.set_tab_disabled(_get_plus_tab(), true)
		tab_container.current_tab = 0
		
		for i in range(_ability_tab_count()):
			_ability_tab_get(i).queue_free()
	
	prev_card = card
	

func _ability_tab_count() -> int:
	return tab_container.get_tab_count() - 2

func _ability_tab_get(i: int) -> Control:
	return tab_container.get_tab_control(1 + i)

func _get_plus_tab() -> int:
	return tab_container.get_tab_count() - 1

func _ability_tab_append(i: int):
	assert(card)
	assert(i == _ability_tab_count())
	var tab := ability_tab_scene.instantiate()
	tab.name = "Ability %s" % i
	tab.set_value(card, i)
	tab.enable_paste = ability_clipboard != null
	tab.delete.connect(_on_ability_delete)
	tab.copy.connect(_on_ability_copy)
	tab.paste.connect(_on_ability_paste)
	tab.saved.connect(_on_ability_saved)
	tab.edit_script_requested.connect(_on_ability_edit_script_requested)
	tab_container.add_child(tab)
	tab_container.move_child(tab, 1 + i)

func _on_ability_saved():
	if card_control:
		card_control.refresh()


func _on_design_notes_text_edit_text_changed():
	if design_note:
		design_note.text = design_notes_text_edit.text
		notes_save_timer.start()
		save_indicator.text = "..."


func _on_notes_save_timer_timeout():
	_save_notes()


func _save_notes():
	if design_note:
		ResourceSaver.save(design_note)
	
	notes_save_timer.stop()
	save_indicator.text = "saved"

func _save():
	ResourceSaver.save(card)
	_refresh()


func _on_design_notes_text_edit_focus_exited():
	_save_notes()

func _on_ability_delete(ability_tab):
	var confirm := ConfirmationDialog.new()
	confirm.title = "Confirm"
	var confirm_label := Label.new()
	confirm_label.text = "Deleting ability %s. Are you sure?" % ability_tab.ability_idx
	confirm.add_child(confirm_label)
	confirm.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	confirm.confirmed.connect(func ():
		card.abilities.remove_at(ability_tab.ability_idx)
		_save()
		confirm.queue_free())
	confirm.canceled.connect(func ():
		confirm.queue_free())
	add_child(confirm)
	confirm.show()

func _on_ability_copy(ability_tab):
	var ability: Resource = card.abilities[ability_tab.ability_idx]
	assert(ability)
	ability_clipboard = ability.duplicate(true)
	print("Ability copied")


func _on_ability_paste(ability_tab):
	assert(ability_clipboard)
	
	var confirm := ConfirmationDialog.new()
	confirm.title = "Confirm Paste"
	
	var layout := VBoxContainer.new()
	
	var confirm_label := Label.new()
	confirm_label.text = "Overwriting ability %s. Are you sure?" % ability_tab.ability_idx
	layout.add_child(confirm_label)
	
	var incl_desc := CheckBox.new()
	incl_desc.text = "Include description"
	layout.add_child(incl_desc)
	
	confirm.add_child(layout)
	confirm.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	confirm.canceled.connect(func ():
		confirm.queue_free())
	add_child(confirm)
	confirm.show()
	
	await confirm.confirmed
	confirm.queue_free()
	
	var include_description := incl_desc.button_pressed
	var tmp_name = card.abilities[ability_tab.ability_idx].ability_name
	var tmp_desc = card.abilities[ability_tab.ability_idx].description
	
	card.abilities[ability_tab.ability_idx] = ability_clipboard.duplicate(true)
	if not include_description:
		card.abilities[ability_tab.ability_idx].ability_name = tmp_name
		card.abilities[ability_tab.ability_idx].description = tmp_desc
	
	ResourceSaver.save(card)
	_on_ability_saved()
	ability_tab._refresh()
	print("Ability pasted")

func _on_ability_edit_script_requested(script: Script):
	edit_script_requested.emit(script)



func _on_card_details_tab_container_tab_selected(tab: int):
	# + tab
	if tab == tab_container.get_tab_count() - 1:
		var i := _ability_tab_count()
		assert(i == card.abilities.size())
		card.abilities.append(CardDatabase.ability_script.new())
		_save()
		tab_container.current_tab = 1 + i
