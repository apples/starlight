@tool
extends EditorPlugin

const MainPanel = preload("res://addons/card_engine/editor/editor_panel.tscn")

var panel

func _enter_tree():
	panel = MainPanel.instantiate()
	get_editor_interface().get_editor_main_screen().add_child(panel)
	_make_visible(false)
	add_custom_type("Card", "Resource", preload("res://addons/card_engine/card/card.gd"), get_editor_interface().get_base_control().get_theme_icon("ImageTexture", "EditorIcons"))
	add_custom_type("CardAbility", "Resource", preload("res://addons/card_engine/card/card_ability.gd"), get_editor_interface().get_base_control().get_theme_icon("Rayito", "EditorIcons"))
	add_custom_type("CardAbilityCost", "Resource", preload("res://addons/card_engine/card/card_ability_cost.gd"), get_editor_interface().get_base_control().get_theme_icon("Script", "EditorIcons"))
	add_custom_type("CardAbilityEffect", "Resource", preload("res://addons/card_engine/card/card_ability_effect.gd"), get_editor_interface().get_base_control().get_theme_icon("Script", "EditorIcons"))
	add_custom_type("CardAbilityPassive", "Resource", preload("res://addons/card_engine/card/card_ability_passive.gd"), get_editor_interface().get_base_control().get_theme_icon("Script", "EditorIcons"))
	add_custom_type("CardAbilityTrigger", "Resource", preload("res://addons/card_engine/card/card_ability_trigger.gd"), get_editor_interface().get_base_control().get_theme_icon("Script", "EditorIcons"))
	add_custom_type("CardDeck", "Resource", preload("res://addons/card_engine/card/card_deck.gd"), get_editor_interface().get_base_control().get_theme_icon("ImageTexture", "EditorIcons"))
	add_custom_type("CardFiber", "Node", preload("res://addons/card_engine/task/card_fiber.gd"), get_editor_interface().get_base_control().get_theme_icon("Node", "EditorIcons"))
	add_custom_type("CardTask", "Node", preload("res://addons/card_engine/task/card_task.gd"), get_editor_interface().get_base_control().get_theme_icon("Node", "EditorIcons"))
	add_custom_type("BattleAgent", "Node", preload("res://addons/card_engine/battle/battle_agent.gd"), get_editor_interface().get_base_control().get_theme_icon("Node", "EditorIcons"))
	add_custom_type("BattleState", "Node", preload("res://addons/card_engine/battle/battle_state.gd"), get_editor_interface().get_base_control().get_theme_icon("Node", "EditorIcons"))
	add_autoload_singleton("CardDatabase", "res://addons/card_engine/card_database.gd")


func _exit_tree():
	if panel:
		panel.queue_free()

func _has_main_screen():
	return true


func _make_visible(visible):
	if panel:
		panel.visible = visible


func _get_plugin_name():
	return "Cards"


func _get_plugin_icon():
	return get_editor_interface().get_base_control().get_theme_icon("ActionCopy", "EditorIcons")
