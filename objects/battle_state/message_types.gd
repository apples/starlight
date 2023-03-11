class_name MessageTypes extends Node

class DeclareWinner extends BattleAgent.Message:
	func get_type(): return "declare_winner"
	var winner: ZoneLocation.Side

class UnitSummoned extends BattleAgent.Message:
	func get_type(): return "unit_summoned"
	var location: ZoneLocation

class AddDiscard extends BattleAgent.Message:
	func get_type(): return "add_discard"
	var what: CardInstance # TODO: convert to net-friendly ID

class DeckShuffled extends BattleAgent.Message:
	func get_type(): return "deck_shuffled"
	var side: ZoneLocation.Side

class CardDrawn extends BattleAgent.Message:
	func get_type(): return "card_drawn"
	var side: ZoneLocation.Side
	var card_instance: CardInstance # TODO: use net-friendly ID

class Alert extends BattleAgent.Message:
	func get_type(): return "alert"
	var text: String

class ChooseTarget extends BattleAgent.Message:
	func get_type(): return "choose_target"
	var allowed_locations: Array[ZoneLocation]
	var future: CardTask.Future

class TakeTurn extends BattleAgent.Message:
	func get_type(): return "take_turn"
	var action_future: CardTask.Future

class RequestResponse extends BattleAgent.Message:
	func get_type(): return "request_response"
	var action_future: CardTask.Future
	var available_triggers: Array[Array]

class RequestManaTaps extends BattleAgent.Message:
	func get_type(): return "request_mana_taps"
	var action_future: CardTask.Future
	var amount: int
	var available_locations: Array[ZoneLocation]
