class_name AbilityInstance extends RefCounted

var battle_state: BattleState
var controller: ZoneLocation.Side
var card_instance: CardInstance
var ability_index: int
var source_location: ZoneLocation
var task: CardTask
var trigger_event: TriggerEvent

var attack_bonus_damage: int = 0

func _init(p_battle_state: BattleState, p_controller: ZoneLocation.Side, p_card_instance: CardInstance, p_ability_index: int):
	battle_state = p_battle_state
	controller = p_controller
	card_instance = p_card_instance
	ability_index = p_ability_index

func negate():
	task.cancel()

func get_ability() -> CardAbility:
	return card_instance.card.get_ability(ability_index)
