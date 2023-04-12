@tool
extends Control

signal edit_script_requested(script: Script)
signal show_in_filesystem_requested(path: String)

var plugin:
	get:
		return plugin
	set(value):
		plugin = value
		if cards:
			cards.plugin = value
		if decks:
			decks.plugin = value

@onready var cards = $TabContainer/Cards
@onready var decks = $TabContainer/Decks

func _ready():
	cards.plugin = plugin
	decks.plugin = plugin
	
	cards.edit_script_requested.connect(func (script): edit_script_requested.emit(script))
	cards.show_in_filesystem_requested.connect(func (path): show_in_filesystem_requested.emit(path))
