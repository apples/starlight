@tool
class_name CardAbilityCost
extends Resource

func get_mana_cost() -> String:
	return ""

@warning_ignore("unused_parameter")
func can_be_paid(battle_state: BattleState, card_instance: CardInstance, ability_index: int, user_side: ZoneLocation.Side) -> bool:
	push_error("CardAbilityCost: can_be_paid() not implemented")
	return false

func pay_task(ability_instance: AbilityInstance) -> CardTask:
	var task = get_script().Task.new()
	task.ability_instance = ability_instance
	
	task.assign_props(self)
	
	return task

func get_output_variables() -> Array[String]:
	return []
