@tool
class_name CardAbilityCost
extends Resource

func get_mana_cost() -> String:
	return ""

func can_be_paid(battle_state: BattleState, card_instance: CardInstance, ability_index: int, user_side: ZoneLocation.Side) -> bool:
	push_error("CardAbilityCost: can_be_paid() not implemented")
	return false

func pay_task() -> CardTask:
	var task = get_script().Task.new()
	for prop in get_script().get_script_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			task[prop.name] = self[prop.name]
	if task.filename == "":
		task.filename = get_script().resource_path.get_file()
	return task
