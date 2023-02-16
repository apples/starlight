class_name BattleAgent extends Node

var battle_state: BattleState
var side: BattleState.Side

func get_deck() -> CardDeck:
	push_error("Must be overridden")
	return null

func handle_message(e: Dictionary) -> void:
	push_error("Must be overridden")