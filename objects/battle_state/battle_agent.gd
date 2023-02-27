class_name BattleAgent extends Node

var battle_state: BattleState
var side: ZoneLocation.Side

func get_deck() -> CardDeck:
	push_error("Must be overridden")
	return null

func handle_message(_m: Message) -> void:
	push_error("Must be overridden")

class Message extends Resource:
	var type: String: get = get_type

	func _init(fields: Dictionary):
		for k in fields:
			assert(k != "type")
			assert(k in self)
			self[k] = fields[k]

	func get_type() -> String:
		push_error("Message get_type() must be overridden.")
		return "unknown"
