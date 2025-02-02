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
	var unit: UnitState # The unit that was destroyed
	var was: CardInstance # The card instance that the unit was at time of destruction
	var by_who: CardInstance # The card responsible for destroying the unit

class UnitDiscarded extends TriggerEvent:
	func get_type(): return "unit_discarded"
	var unit: UnitState
	var was: CardInstance

class UnitTapped extends TriggerEvent:
	func get_type(): return "unit_tapped"
	var unit: UnitState
	var for_mana: bool

class UnitReadied extends TriggerEvent:
	func get_type(): return "unit_readied"
	var unit: UnitState

class GainedTokens extends TriggerEvent:
	func get_type(): return "gained_tokens"
	var side: ZoneLocation.Side
	var kind: BattleState.TokenType
	var amount_gained: int
	var total_amount: int

#class RulecardCharge extends TriggerEvent:
	#func get_type(): return "rulecard_charge"
	#var side: ZoneLocation.Side
	#var amount_gained: int
	#var total_amount: int
