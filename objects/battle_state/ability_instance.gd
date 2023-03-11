class_name AbilityInstance extends RefCounted

var battle_state: BattleState
var controller: ZoneLocation.Side
var card_ability: CardAbility
var card_instance: CardInstance
var source_location: ZoneLocation
var task: CardTask

var attack_bonus_damage: int = 0

func negate():
	task.cancel()
