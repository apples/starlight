@tool
class_name CardRender
extends Node2D

const BASE_TEXTURES = {
	BACK = preload("res://objects/card_plane/images/back.png"),
	FRAME = preload("res://objects/card_plane/images/frame.png"),
	FRAME_ABILITY = preload("res://objects/card_plane/images/frame_ability.png"),
	FRAME_ABILITY_ATTACKPOWER = preload("res://objects/card_plane/images/frame_ability_attackpower.png"),
	FRAME_ABILITY_GRACE = preload("res://objects/card_plane/images/frame_ability_grace.png"),
	FRAME_ABILITY_MANACOST = preload("res://objects/card_plane/images/frame_ability_manacost.png"),
	FRAME_ABILITY_MANACOST_TAP = preload("res://objects/card_plane/images/frame_ability_manacost_tap.png"),
	FRAME_ABILITY_RULECARD = preload("res://objects/card_plane/images/frame_ability_rulecard.png"),
	FRAME_ABILITY_SPELL = preload("res://objects/card_plane/images/frame_ability_spell.png"),
	FRAME_ABILITY_TAG_ACTION = preload("res://objects/card_plane/images/frame_ability_tag_action.png"),
	FRAME_ABILITY_TAG_ATTACK = preload("res://objects/card_plane/images/frame_ability_tag_attack.png"),
	FRAME_ABILITY_TAG_PASSIVE = preload("res://objects/card_plane/images/frame_ability_tag_passive.png"),
	FRAME_ABILITY_TAG_TRIGGER = preload("res://objects/card_plane/images/frame_ability_tag_trigger.png"),
	FRAME_GRACE = preload("res://objects/card_plane/images/frame_grace.png"),
	FRAME_RULECARD = preload("res://objects/card_plane/images/frame_rulecard.png"),
	HP_LARGE = preload("res://objects/card_plane/images/hp_large.png"),
	HP_SMALL = preload("res://objects/card_plane/images/hp_small.png"),
	LEVEL_ICON = preload("res://objects/card_plane/images/level_icon.png"),
}


@export var frame_texture: Texture2D = null
@export var back_texture: Texture2D = null

@export var rulecard_frame_texture: Texture2D = null
@export var grace_frame_texture: Texture2D = null

@export var card: Card = null:
	set(value):
		card = value
		refresh()

@export var for_print: bool = false:
	set(value):
		for_print = value
		refresh()

@export var poke: bool:
	set(_v):
		refresh()

@onready var background: Sprite2D = $Background
@onready var typical_cardface: Control = $Control/TypicalCardFace
@onready var rulecard_cardface: Control = $Control/RulecardCardFace




var ability_panel_scene := preload("res://objects/card_plane/ability_panel.tscn")

var ability_panels: Array[Control] = []

var prev_card: Card

func _ready():
	refresh()

func refresh():
	if not is_inside_tree():
		return
	
	if Engine.is_editor_hint():
		if get_tree().edited_scene_root == self:
			return
		
		if get_tree().edited_scene_root.is_ancestor_of(self):
			return
	
	if card:
		if prev_card != card:
			_cleanup(typical_cardface.get_node("AbilityContainer"))
			_cleanup(rulecard_cardface.get_node("AbilityContainer"))
			ability_panels = []
		
		match card.kind:
			Card.Kind.RULECARD:
				_refresh_rulecard()
			_:
				_refresh_typical()
		
		prev_card = card
	else:
		background.texture = _get_card_texture(&"BACK")
		typical_cardface.visible = false
		rulecard_cardface.visible = false
		
		_cleanup(typical_cardface.get_node("AbilityContainer"))
		_cleanup(rulecard_cardface.get_node("AbilityContainer"))
		ability_panels = []
		
		prev_card = null
	

func _cleanup(node: Node):
	while node.get_child_count() > 0:
		var c := node.get_child(-1)
		c.queue_free()
		node.remove_child(c)


func _refresh_typical():
	match card.kind:
		Card.Kind.GRACE:
			background.texture = _get_card_texture(&"FRAME_GRACE")
		_:
			background.texture = _get_card_texture(&"FRAME")
	typical_cardface.visible = true
	rulecard_cardface.visible = false
	
	_refresh_generic(typical_cardface)
	
	# level
	
	var level_icons: VBoxContainer = typical_cardface.get_node("LevelIcons")
	
	for i in range(3):
		var icon: TextureRect = level_icons.get_child(i)
		icon.visible = i < card.level
		if icon.visible:
			icon.texture = _get_card_texture(&"LEVEL_ICON")
	
	# hp
	
	var hp_rect: TextureRect = typical_cardface.get_node("HP")
	var hp_label: Label = hp_rect.get_node("Label")
	
	hp_rect.visible = card.unit_hp > 0
	hp_rect.texture = _get_card_texture("HP_SMALL") if card.unit_hp < 10 else _get_card_texture("HP_LARGE")
	hp_label.text = str(card.unit_hp)
	hp_label.modulate = Color.BLACK if for_print else Color.WHITE

func _refresh_rulecard():
	background.texture = _get_card_texture(&"FRAME_RULECARD")
	typical_cardface.visible = false
	rulecard_cardface.visible = true
	_refresh_generic(rulecard_cardface)

func _refresh_generic(cardface: Node):
	var artwork = cardface.get_node("Artwork")
	var name_label = cardface.get_node("Name")
	var ability_container: VBoxContainer = cardface.get_node("AbilityContainer")
	
	if card.artwork_path != "":
		artwork.texture = load(card.artwork_path)
	else:
		artwork.texture = load("res://data/cards/artwork/_missing.png") if not for_print else null
	
	name_label.text = card.card_name
	name_label.modulate = Color.BLACK if for_print else Color.WHITE
	
	for i in range(card.abilities.size()):
		if i < ability_panels.size():
			ability_panels[i].get_card_texture = _get_card_texture
			ability_panels[i].text_modulate = Color.BLACK if for_print else Color.WHITE
			ability_panels[i].card = card
			ability_panels[i].card_ability = card.abilities[i]
		else:
			if i == 0:
				assert(ability_container.get_child_count() == 0)
				ability_container.add_spacer(false)
			var ap = ability_panel_scene.instantiate()
			ap.get_card_texture = _get_card_texture
			ap.text_modulate = Color.BLACK if for_print else Color.WHITE
			ap.card = card
			ap.card_ability = card.abilities[i]
			ability_container.add_child(ap)
			ability_container.add_spacer(false)
			ability_panels.append(ap)
	
	for i in range(ability_panels.size(), card.abilities.size(), -1):
		ability_panels.remove_at(i - 1)
	
	for i in range(card.abilities.size(), (ability_container.get_child_count() - 1) / 2):
		ability_container.get_child(1 + i * 2).queue_free()
		ability_container.get_child(1 + i * 2 + 1).queue_free()
	
	if card.abilities.size() == 0:
		if ability_container.get_child_count() > 0:
			ability_container.get_child(0).queue_free()
	

func _get_card_texture(p_name: StringName) -> Texture2D:
	if for_print:
		var print_file_path := (BASE_TEXTURES[p_name] as Resource).resource_path.replace("images/", "images_print/")
		
		if ResourceLoader.exists(print_file_path, "Texture2D"):
			return load(print_file_path)
	
	return BASE_TEXTURES[p_name]
