@tool
extends CardAbilityCondition

@export var reach: bool = false
@export var reach_var: String

func is_met(
	battle_state: BattleState,
	card_instance: CardInstance,
	ability_index: int
) -> bool:
	if reach:
		return true
	if card_instance.location.zone == ZoneLocation.Zone.FrontRow:
		return true
	return false

func get_variable_names() -> Array[String]:
	return ["basic_attack_target_zones"]

func compute_variables(ability_instance: AbilityInstance) -> Dictionary:
	var reach_v = ability_instance.variables[reach_var] if reach_var else reach
	var is_front_row := ability_instance.card_instance.location.zone == ZoneLocation.Zone.FrontRow
	
	var basic_attack_target_zones: int = 0
	if reach_v or is_front_row:
		basic_attack_target_zones |= FieldZoneFlags.OPPONENT_FRONT
	if reach_v and is_front_row:
		basic_attack_target_zones |= FieldZoneFlags.OPPONENT_BACK
	
	return {
		basic_attack_target_zones = basic_attack_target_zones,
	}
