@tool
extends Control

@export var data_table_field: PackedScene = preload("res://addons/card_engine/editor/data_table_field.tscn")
@export var new_card_window: PackedScene = preload("res://addons/card_engine/editor/new_card_window.tscn")
@export var change_set_window: PackedScene = preload("res://addons/card_engine/editor/change_set_window.tscn")

@onready var config_path_edit: LineEdit = %ConfigPathEdit
@onready var card_data_table = %CardDataTable
@onready var set_option_button: OptionButton = %SetOptionButton
@onready var card_details = %CardDetails
@onready var default_mana_option_button: OptionButton = %DefaultManaOptionButton
@onready var print_preview_check_button: CheckButton = %PrintPreviewCheckButton

var plugin

var card_script: Script = null

var all_cards: Array[String] = []
var filtered_cards: Array[Card] = []

var card_sets: Dictionary

var current_set: String = ""
var name_filter: String = ""

var is_loaded := false

var current_selection: String

signal edit_script_requested(script: Script)
signal show_in_filesystem_requested(path: String)
signal delete_requested(cardfilepath: String)

func _ready():
	config_path_edit.text = "res://card_engine_config.tres"


func _on_reload_button_pressed():
	if Engine.is_editor_hint() and EditorInterface.get_edited_scene_root() and (EditorInterface.get_edited_scene_root() == self or EditorInterface.get_edited_scene_root().is_ancestor_of(self)):
		return
	print("Loading cards!")
	CardDatabase.config = load(config_path_edit.text)
	reload()
	refresh()


func reload():
	is_loaded = true
	all_cards = CardDatabase.get_all_cards()
	if all_cards.size() == 0:
		print("No cards!")
	current_set = "ALL_SETS"
	name_filter = ""
	filtered_cards = Array(all_cards.map(func (c): return load(c)), TYPE_OBJECT, "Resource", preload("res://resource_types/card/card.gd"))
	card_sets = {}
	var all_cards_loaded: Array = all_cards.map(func (c): return load(c))
	for card: Card in all_cards_loaded:
		if not card.cardset_name in card_sets:
			card_sets[card.cardset_name] = [card.resource_path]
		else:
			card_sets[card.cardset_name].append(card.resource_path)
	set_option_button.clear()
	set_option_button.add_item("ALL_SETS")
	for cardset_name in card_sets:
		var cards: Array = card_sets[cardset_name]
		cards.sort_custom(func (a, b):
			return load(a).cardset_idx < load(b).cardset_idx)
		set_option_button.add_item(cardset_name)
	set_option_button.select(0)
	
	default_mana_option_button.clear()
	for mt in CardDatabase.get_mana_types():
		default_mana_option_button.add_item(mt[0], mt[1])

func refresh():
	print("tab_cards.gd: refresh(): start")
	var refresh_start := Time.get_ticks_usec()
	
	if current_set == "ALL_SETS" and name_filter == "":
		filtered_cards = []
		filtered_cards.assign(all_cards.map(func (c): return load(c)))
	else:
		filtered_cards = []
		for c in all_cards:
			var card: Card = load(c)
			if current_set != "ALL_SETS" and card.cardset_name != current_set:
				continue
			if name_filter != "" and not card.card_name.to_lower().contains(name_filter):
				continue
			filtered_cards.append(card)
	
	print("tab_cards.gd: refresh(): after filter: ", (Time.get_ticks_usec() - refresh_start) / 1000, "ms")
	
	filtered_cards.sort_custom(func (a: Card, b: Card):
		if a.cardset_name != b.cardset_name:
			return a.cardset_name < b.cardset_name
		return a.cardset_idx < b.cardset_idx)
	
	
	print("tab_cards.gd: refresh(): after sort: ", (Time.get_ticks_usec() - refresh_start) / 1000, "ms")
	
	
	if current_selection != "":
		var idx := filtered_cards.find(load(current_selection))
		if idx != -1:
			_select_index(idx)
		else:
			current_selection = ""
			card_details.card = null
	else:
		card_details.card = null
	card_data_table.set_data(filtered_cards)
	
	print("tab_cards.gd: refresh(): after set_data: ", (Time.get_ticks_usec() - refresh_start) / 1000, "ms")
	
	if current_set != "ALL_SETS" and filtered_cards.size() > 0:
		var mid = filtered_cards[0].mana
		var midx := default_mana_option_button.get_item_index(mid)
		default_mana_option_button.select(midx)
	
	print("tab_cards.gd: refresh(): total: ", (Time.get_ticks_usec() - refresh_start) / 1000, "ms")
	print("tab_cards.gd: refresh(): done.")

func _on_new_card_button_pressed():
	var popup := new_card_window.instantiate()
	add_child(popup)
	var card_set_names: Array[String] = []
	card_set_names.assign(card_sets.keys())
	popup.set_sets(card_set_names)
	if current_set != "ALL_SETS":
		popup.cardset_edit.text = current_set
	else:
		popup.cardset_edit.text = card_set_names[0] if card_set_names.size() > 0 else ""
	popup.new_card.connect(func (cardset_name: String, card_name: String):
		var card: Resource = CardDatabase.card_script.new()
		
		card.uid = CardDatabase.card_script.random_uid()
		var path := CardDatabase.cards_path.path_join("%s.tres" % card.uid)
		while FileAccess.file_exists(path):
			card.uid = CardDatabase.card_script.random_uid()
			path = CardDatabase.cards_path.path_join("%s.tres" % card.uid)
		card.cardset_name = cardset_name
		card.card_name = card_name
		
		card.mana = default_mana_option_button.get_selected_id()
		
		all_cards.append(path)
		if not cardset_name in card_sets:
			card_sets[cardset_name] = [path]
			card.cardset_idx = 0
			set_option_button.add_item(cardset_name)
		else:
			card_sets[cardset_name].append(path)
			card.cardset_idx = card_sets[cardset_name].size() - 1
		
		ResourceSaver.save(card, path, ResourceSaver.FLAG_CHANGE_PATH)
		
		refresh()
	)
	popup.show()


func _on_data_table_column_set_double_clicked(idx):
	var popup := change_set_window.instantiate()
	add_child(popup)
	
	var card_set_names: Array[String] = []
	card_set_names.assign(card_sets.keys())
	popup.set_sets(card_set_names)
	
	var card := filtered_cards[idx]
	var old_set: String = card.cardset_name
	
	print("changing set: %s: %s" % [card.card_name, old_set])
	
	popup.change_set.connect(func (cardset_name: String):
		if card.cardset_name == cardset_name:
			return
		if card.cardset_name in card_sets:
			var a := card_sets[card.cardset_name] as Array
			var i := a.find(card.resource_path)
			a.remove_at(i)
			for j in range(i, a.size()):
				var set_card := load(a[j])
				set_card.cardset_idx = j
				ResourceSaver.save(set_card)
		card.cardset_name = cardset_name
		if not cardset_name in card_sets:
			card_sets[cardset_name] = [card.resource_path]
			card.cardset_idx = 0
			set_option_button.add_item(cardset_name)
		else:
			card_sets[cardset_name].append(card.resource_path)
			card.cardset_idx = card_sets[cardset_name].size() - 1
		ResourceSaver.save(card)
		refresh()
	)


func _on_set_option_button_item_selected(index):
	var next_set := set_option_button.get_item_text(index)
	if next_set != current_set:
		current_set = next_set
		refresh()


func _on_search_edit_text_submitted(new_text):
	name_filter = new_text
	refresh()


func _on_visibility_changed():
	if is_inside_tree() and visible and not is_loaded:
		call_deferred("_on_reload_button_pressed")
	if is_inside_tree() and visible:
		if card_details:
			card_details.card = card_details.card


func _on_card_data_table_row_clicked(idx: int):
	_select_index(idx)


func _select_index(idx: int):
	var card := filtered_cards[idx]
	card_details.card = card
	current_selection = filtered_cards[idx].resource_path


func _on_data_table_column_id_saved(idx: int):
	var card := filtered_cards[idx]
	
	var cardset: Array = card_sets[card.cardset_name]
	var old_idx: int = cardset.find(filtered_cards[idx])
	var new_idx: int = card.cardset_idx
	
	if new_idx >= cardset.size():
		new_idx = cardset.size() - 1
		card.cardset_idx = new_idx
		ResourceSaver.save(card)
	
	# rotate
	if old_idx < new_idx:
		for i in range(old_idx, new_idx):
			cardset[i] = cardset[i + 1]
			var c := load(cardset[i])
			c.cardset_idx = i
			ResourceSaver.save(c)
	elif new_idx < old_idx:
		for i in range(old_idx, new_idx, -1):
			cardset[i] = cardset[i - 1]
			var c := load(cardset[i])
			c.cardset_idx = i
			ResourceSaver.save(c)
	cardset[new_idx] = filtered_cards[idx]
	
	refresh()


func _on_card_details_edit_script_requested(script):
	edit_script_requested.emit(script)


func _on_card_data_table_show_in_filesystem_requested(path):
	show_in_filesystem_requested.emit(path)


func _on_card_data_table_delete_requested(cardfilepath):
	var card := load(cardfilepath)
	var cardset: Array = card_sets[card.cardset_name]
	var old_idx: int = card.cardset_idx
	assert(cardset[old_idx] == cardfilepath)
	
	if not await plugin.delete_card(cardfilepath):
		return
	
	# rotate
	for i in range(old_idx, cardset.size() - 1):
		cardset[i] = cardset[i + 1]
		var c := load(cardset[i])
		c.cardset_idx = i
		ResourceSaver.save(c)
	
	cardset.pop_back()
	
	all_cards.remove_at(all_cards.find(cardfilepath))
	
	refresh()


func _on_print_preview_check_button_toggled(toggled_on: bool) -> void:
	card_details.for_print = toggled_on


func _on_autofill_artworks_button_pressed() -> void:
	var art_root := CardDatabase.config.data_root.path_join(CardDatabase.config.artwork_path)
	for c in filtered_cards:
		var card := c
		if card.artwork_path:
			continue
		var card_name: String = card.card_name
		if not card_name:
			continue
		var art_name := (
			card_name.to_lower()
				.replace("'", "")
				.replace(" ", "_")
				.replace(",", "")
		)
		var art_filename := art_root.path_join(art_name + ".png")
		if not FileAccess.file_exists(art_filename):
			print("%s does not exist." % [art_filename])
			continue
		card.artwork_path = art_filename
		ResourceSaver.save(card)
		print("Added artwork to \"%s\": %s" % [card_name, art_filename])
	refresh()
