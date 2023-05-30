class_name CardAbilityPassive
extends Resource

@warning_ignore("unused_parameter")
func process_trigger_event(passive_effect: PassiveEffect, trigger_event: TriggerEvent, battle_state: BattleState) -> void:
	pass

func get_output_variables() -> Array[String]:
	return []
