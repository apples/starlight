class_name AbilityInstance extends RefCounted

var battle_state: BattleState
var controller: ZoneLocation.Side
var card_ability: CardAbility
var card_instance: CardInstance
var source_location: ZoneLocation
var task: CardTask

func negate():
	task.cancel()
