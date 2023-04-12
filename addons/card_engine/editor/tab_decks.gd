@tool
extends Control

var card_engine_config: CardEngineConfig

var plugin

var all_cards: Array[String] = []
var filtered_cards: Array[String] = []

var all_decks: Array[String] = []

var set_filter: String = ""

@onready var deck_path_edit = %DeckPathEdit
@onready var deck_path_popup_menu = %DeckPathPopupMenu

func _ready():
	if visible:
		_reload()

func _reload():
	all_cards = CardDatabase.get_all_cards()
	all_decks = CardDatabase.get_all_decks()


func _on_visibility_changed():
	if is_inside_tree() and visible:
		call_deferred("_reload")


func _on_deck_path_edit_opened():
	deck_path_edit.popup_menu.edit.text = ""
	_update_deck_search()

func _update_deck_search():
	deck_path_edit.popup_menu.clear()
	
	for i in range(all_decks.size()):
		var d = all_decks[i]
		
		if deck_path_edit.popup_menu.edit.text != "":
			if not d.contains(deck_path_edit.popup_menu.edit.text):
				continue
		
		deck_path_edit.popup_menu.add_item(d.get_file(), i)

func _on_deck_path_edit_selected_id(id):
	_load_deck(all_decks[id])


func _on_deck_path_edit_search_changed(new_text):
	_update_deck_search()


func _load_deck(path: String):
	deck_path_edit.text = path.get_file()

