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

var card_control: Control


func _ready():
	_refresh()

func _refresh():
	if card_preview_container.get_child_count() > 0:
		var c := card_preview_container.get_child(0)
		assert(c == card_control)
		c.queue_free()
		card_preview_container.remove_child(c)
		card_control = null
	
	if card:
		card_control = CardDatabase.config.card_control.instantiate()
		card_control.card = card
		card_preview_container.add_child(card_control)
		
	ability0.card = card
	ability1.card = card


func _on_ability_saved():
	if card_control:
		card_control.refresh()
