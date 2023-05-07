@tool
extends Control

var card_engine_config: CardEngineConfig

var plugin

var all_cards: Array[String] = []
var filtered_cards: Array[String] = []

var all_decks: Array[String] = []

var set_filter: String = ""

@onready var deck_path_edit = %DeckPathEdit
@onready var set_option_button = %SetOptionButton
@onready var name_line_edit = %NameLineEdit
@onready var deck_cards = %DeckCards
@onready var card_search_list = %CardSearchList
@onready var stella_container = %StellaContainer
@onready var starlights_container = %StarlightsContainer
@onready var starters_container = %StartersContainer
@onready var zoom_label = %ZoomLabel
@onready var zoom_minus = %ZoomMinus
@onready var zoom_plus = %ZoomPlus
@onready var no_deck_container = %NoDeckContainer

var deck_card_item_scene = preload("res://addons/card_engine/editor/deck_card_item.tscn")
var new_deck_scene = preload("res://addons/card_engine/editor/new_deck_dialog.tscn")

#@export var main_deck_cards: Array[CardCount] = []
#@export var starter_unit_card_keys: Array[String] = []
#@export var starlight_card_keys: Array[String] = []
#@export var stella_card_key: String
var loaded_deck: Resource

var search_name: String
var search_set: String = "ALL_SETS"

var card_sets: Dictionary = {}

var zoom: float = 0.5

var _cached_searches: Dictionary = {}

func _ready():
	if visible:
		_reload()

func _reload():
	all_cards = CardDatabase.get_all_cards()
	all_decks = CardDatabase.get_all_decks()
	print("all_decks = ", all_decks)
	
	card_sets = {}
	for c in all_cards:
		var card := load(c)
		if not card.cardset_name in card_sets:
			card_sets[card.cardset_name] = [c]
		else:
			card_sets[card.cardset_name].append(c)
	set_option_button.clear()
	set_option_button.add_item("ALL_SETS")
	for cardset_name in card_sets:
		var cards: Array = card_sets[cardset_name]
		cards.sort_custom(func (a, b):
			return load(a).cardset_idx < load(b).cardset_idx)
		set_option_button.add_item(cardset_name)
	set_option_button.select(0)
	
	if not search_set in card_sets:
		search_set = "ALL_SETS"
	
	_cached_searches = {}
	_refresh_search()
	_reconcile()
	
	zoom_label.text = "%s%%" % [zoom * 100]

func _reconcile():
	if not loaded_deck:
		for c in deck_cards.get_children():
			c.queue_free()
		no_deck_container.visible = true
		return
	
	no_deck_container.visible = false
	
	_reconcile_stella()
	_reconcile_starlights()
	_reconcile_starters()
	_reconcile_main_deck()

func _reconcile_stella():
	var arr := [loaded_deck.stella_card_key] if loaded_deck.stella_card_key else []
	_reconcile_deck_container(stella_container, arr, _on_stella_item_change_count)	

func _reconcile_starlights():
	_reconcile_deck_container(starlights_container, loaded_deck.starlight_card_keys, _on_starlight_item_change_count)

func _reconcile_starters():
	_reconcile_deck_container(starters_container, loaded_deck.starter_unit_card_keys, _on_starter_item_change_count)

func _reconcile_main_deck():
	_reconcile_deck_container(deck_cards, loaded_deck.main_deck_cards, _on_card_deck_item_change_count)

func _on_card_deck_item_change_count(id: int, amount: int):
	loaded_deck.main_deck_cards[id].count += amount
	if loaded_deck.main_deck_cards[id].count > 0:
		deck_cards.get_child(id).count = loaded_deck.main_deck_cards[id].count
	else:
		loaded_deck.main_deck_cards.remove_at(id)
		_reconcile_main_deck()
	_save()

func _on_starlight_item_change_count(id: int, amount: int):
	if amount == 1:
		return
	loaded_deck.starlight_card_keys.remove_at(id)
	_reconcile_starlights()
	_save()

func _on_starter_item_change_count(id: int, amount: int):
	if amount == 1:
		return
	loaded_deck.starter_unit_card_keys.remove_at(id)
	_reconcile_starters()
	_save()

func _on_stella_item_change_count(id: int, amount: int):
	if amount == 1:
		return
	loaded_deck.stella_card_key = ""
	_reconcile_stella()
	_save()

func _reconcile_deck_item(deck_item, id: int, card_key: String, count: int):
	deck_item.id = id
	deck_item.card = CardDatabase.load_from_key(card_key)
	deck_item.count = count
	deck_item.zoom = zoom

func _reconcile_deck_container(deck_container, items: Array, on_change_count: Callable = Callable()):
	for i in range(items.size()):
		var is_card_key := items[i] is String
		var card_key: String = items[i] if is_card_key else items[i].card_key
		var count: int = 1 if is_card_key else items[i].count
		if i < deck_container.get_child_count():
			var c = deck_container.get_child(i)
			_reconcile_deck_item(c, i, card_key, count)
		else:
			var c = deck_card_item_scene.instantiate()
			_reconcile_deck_item(c, i, card_key, count)
			if on_change_count:
				c.change_count.connect(on_change_count)
			deck_container.add_child(c)
	for i in range(items.size(), deck_container.get_child_count()):
		deck_container.get_child(i).queue_free()


func _save():
	ResourceSaver.save(loaded_deck)

func _on_visibility_changed():
	if is_inside_tree() and visible:
		call_deferred("_reload")


func _on_deck_path_edit_opened():
	deck_path_edit.popup_menu.edit.text = ""
	_update_deck_search()

func _update_deck_search():
	deck_path_edit.popup_menu.clear()
	
	for i in range(all_decks.size()):
		var d = all_decks[i].get_file()
		
		if deck_path_edit.popup_menu.edit.text != "":
			if not d.contains(deck_path_edit.popup_menu.edit.text):
				continue
		
		deck_path_edit.popup_menu.add_item(d, i)

func _on_deck_path_edit_selected_id(id):
	_load_deck(all_decks[id])


func _on_deck_path_edit_search_changed(new_text):
	_update_deck_search()


func _load_deck(path: String):
	deck_path_edit.text = path.get_file()
	loaded_deck = load(path)
	_reconcile()



func _on_name_line_edit_text_changed(new_text):
	search_name = new_text
	_refresh_search()

func _on_set_option_button_item_selected(index):
	search_set = set_option_button.get_item_text(index)
	_refresh_search()

func _refresh_search():
	var result_cards: Array[Resource] = [] # used only for efficiency purposes
	var result_paths: Array[String] = []
	
	var card_set = card_sets[search_set] if search_set in card_sets else all_cards
	
	var cache_key := "%s\u001F%s" % [search_set, search_name]
	
	if cache_key in _cached_searches:
		result_paths = _cached_searches[cache_key]
	else:
		for f in card_set:
			if search_name == "":
				result_paths.append(f)
				result_cards.append(null)
				continue
			var c = load(f)
			if (c.card_name as String).to_lower().contains(search_name):
				result_paths.append(f)
				result_cards.append(c)
		_cached_searches[cache_key] = result_paths
	
	for i in range(result_paths.size()):
		if i < card_search_list.get_child_count():
			var c = card_search_list.get_child(i)
			c.id = i
			c.card = load(result_paths[i])
			c.zoom = zoom
		else:
			var c = deck_card_item_scene.instantiate()
			c.id = i
			c.card = load(result_paths[i])
			c.zoom = zoom
			c.change_count.connect(_on_search_item_change_count)
			c.right_clicked.connect(_on_search_item_right_clicked)
			card_search_list.add_child(c)
			c.button_minus.visible = false
			c.count_label.visible = false
	for i in range(result_paths.size(), card_search_list.get_child_count()):
		card_search_list.get_child(i).queue_free()

func _on_search_item_change_count(id: int, amount: int):
	if not loaded_deck:
		return
	assert(amount == 1)
	var card = card_search_list.get_child(id).card
	match card.kind:
		CardDatabase.card_script.Kind.STELLA:
			loaded_deck.stella_card_key = _make_key(card.uid)
			_reconcile_stella()
		CardDatabase.card_script.Kind.STARLIGHT:
			var found := false
			for k in loaded_deck.starlight_card_keys:
				if _get_key_uid(k) == card.uid:
					found = true
					break
			if not found:
				var a: Array[String] = loaded_deck.starlight_card_keys.duplicate()
				a.append(_make_key(card.uid))
				loaded_deck.starlight_card_keys = a
				_reconcile_starlights()
		_:
			var found := false
			for c in loaded_deck.main_deck_cards:
				if _get_key_uid(c.card_key) == card.uid:
					c.count += amount
					found = true
					_reconcile_main_deck()
					break
			if not found and amount > 0:
				var c = CardDatabase.card_count_script.new()
				c.card_key = _make_key(card.uid)
				c.count = amount
				var a = loaded_deck.main_deck_cards.duplicate()
				a.append(c)
				loaded_deck.main_deck_cards = a
				_reconcile_main_deck()
	_save()

func _on_search_item_right_clicked(id: int):
	if not loaded_deck:
		return
	var card = card_search_list.get_child(id).card
	if card.kind == CardDatabase.card_script.Kind.UNIT:
		for k in loaded_deck.starter_unit_card_keys:
			if _get_key_uid(k) == card.uid:
				return
		var a: Array[String] = loaded_deck.starter_unit_card_keys.duplicate()
		a.append(_make_key(card.uid))
		loaded_deck.starter_unit_card_keys = a
		_reconcile_starters()
		_save()

func _make_key(uid: String):
	return "%s:0" % uid

func _get_key_uid(key: String):
	return key.split(":")[0]


func _on_zoom_minus_pressed():
	_apply_zoom(-0.25)


func _on_zoom_plus_pressed():
	_apply_zoom(+0.25)

func _apply_zoom(amount: float):
	zoom += amount
	zoom_label.text = "%s%%" % [zoom * 100]
	_reconcile()
	_refresh_search()
	zoom_minus.disabled = zoom <= 0.25
	zoom_plus.disabled = zoom >= 2


func _on_new_button_pressed():
	var dialog: ConfirmationDialog = new_deck_scene.instantiate()
	add_child(dialog)
	dialog.canceled.connect(dialog.queue_free)
	dialog.show()
	
	await dialog.confirmed
	
	var filename: String = dialog.line_edit.text
	if not filename.ends_with(".tres"):
		filename += ".tres"
	
	assert(filename.is_valid_filename())
	
	var fullpath := CardDatabase.decks_path.path_join(filename)
	
	assert(not FileAccess.file_exists(fullpath))
	
	var deck: Resource = CardDatabase.card_deck_script.new()
	
	ResourceSaver.save(deck, fullpath, ResourceSaver.FLAG_CHANGE_PATH)
	
	_load_deck(fullpath)
	
	all_decks = CardDatabase.get_all_decks()
