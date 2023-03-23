@tool
extends HSplitContainer

@export var card: Resource = null:
	get:
		return card
	set(value):
		card = value
		if is_inside_tree():
			_refresh()

@onready var card_preview_container := %CardPreviewContainer

@onready var ability0 := %"Ability 0"
@onready var ability1 := %"Ability 1"

@onready var design_notes_text_edit = %DesignNotesTextEdit
@onready var notes_save_timer = %NotesSaveTimer
@onready var save_indicator = %SaveIndicator

var card_control: Control

var design_note: CardEngineDesignNote

var ability_clipboard: Resource

func _ready():
	$BottomPanelTabs.set_popup($PopupMenu)
	_refresh()

func _refresh():
	_save_notes()
	
	if card_preview_container.get_child_count() > 0:
		var c := card_preview_container.get_child(0)
		assert(c == card_control)
		c.queue_free()
		card_preview_container.remove_child(c)
		card_control = null
		design_note = null
	
	if card:
		card_control = CardDatabase.config.card_control.instantiate()
		card_control.card = card
		card_preview_container.add_child(card_control)
		
		design_note = CardDatabase.get_design_note(card)
		design_notes_text_edit.text = design_note.text
	
	ability0.card = card
	ability1.card = card


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


func _on_design_notes_text_edit_focus_exited():
	_save_notes()


func _on_ability_copy(ability_tab):
	var ability: Resource = card[ability_tab.ability_key]
	assert(ability)
	ability_clipboard = ability.duplicate(true)
	print("Ability copied")


func _on_ability_paste(ability_tab):
	assert(card[ability_tab.ability_key] == null)
	if ability_clipboard == null:
		print("Ability clipboard empty!")
		return
	card[ability_tab.ability_key] = ability_clipboard.duplicate(true)
	ResourceSaver.save(card)
	_on_ability_saved()
	ability_tab._refresh()
	print("Ability pasted")
