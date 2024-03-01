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

class CardMoved extends BattleAgent.Message:
	func get_type(): return "card_moved"
	var uid: int
	var from: ZoneLocation
	var to: ZoneLocation

class CardRevealed extends BattleAgent.Message:
	func get_type(): return "card_revealed"
	var uid: int

class Alert extends BattleAgent.Message:
	func get_type(): return "alert"
	var text: String

class ChooseTarget extends BattleAgent.Message:
	func get_type(): return "choose_target"
	var allowed_locations: Array[ZoneLocation]
	var source_location: ZoneLocation
	var future: CardTask.Future

class ChooseFieldLocation extends BattleAgent.Message:
	func get_type(): return "choose_field_location"
	var allowed_locations: Array[ZoneLocation]
	var future: CardTask.Future

class TakeTurn extends BattleAgent.Message:
	func get_type(): return "take_turn"
	var action_future: CardTask.Future
	var available_abilities: Dictionary = {} ## { [uid: int]: [ability_index: int] }
	var available_summons: Array[int] = []

class RequestResponse extends BattleAgent.Message:
	func get_type(): return "request_response"
	var action_future: CardTask.Future
	var available_triggers: Array[Dictionary] ## Array[{ card_uid: int, available_trigger_abilities: Array[int] }]

class RequestManaTaps extends BattleAgent.Message:
	func get_type(): return "request_mana_taps"
	var action_future: CardTask.Future
	var amount: int
	var available_locations: Array[ZoneLocation]

class UnitDamaged extends BattleAgent.Message:
	func get_type(): return "unit_damaged"
	var card_uid: int
	var location: ZoneLocation
	var amount: int

class UnitTappedChanged extends BattleAgent.Message:
	func get_type(): return "unit_tapped_changed"
	var location: ZoneLocation
	var is_tapped: bool

class UnitRemoved extends BattleAgent.Message:
	func get_type(): return "unit_removed"
	var location: ZoneLocation
