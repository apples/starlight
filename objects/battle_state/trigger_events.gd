class_name TriggerEvents extends Node

class AbilityActivated extends TriggerEvent:
	func get_type(): return "ability_activated"
	var ability_instance: AbilityInstance

class AbilityPerformed extends TriggerEvent:
	func get_type(): return "ability_performed"
	var ability_instance: AbilityInstance

class UnitSummoned extends TriggerEvent:
	func get_type(): return "unit_summoned"
	var unit: UnitState
	var to: CardInstance

class UnitAscended extends TriggerEvent:
	func get_type(): return "unit_ascended"
	var unit: UnitState
	var from: CardInstance
	var to: CardInstance

class UnitDestroyed extends TriggerEvent:
	func get_type(): return "unit_destroyed"
	var unit: UnitState
	var was: CardInstance

class UnitTapped extends TriggerEvent:
	func get_type(): return "unit_tapped"
	var unit: UnitState
	var for_mana: bool

class GainedTokens extends TriggerEvent:
	func get_type(): return "gained_tokens"
	var side: ZoneLocation.Side
	var kind: BattleState.TokenType
	var amount_gained: int
	var total_amount: int
