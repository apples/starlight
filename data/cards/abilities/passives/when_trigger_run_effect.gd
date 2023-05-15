@tool
extends CardAbilityPassive

@export var trigger: CardAbilityTrigger
@export var effect: CardAbilityEffect

func process_trigger_event(passive_effect: PassiveEffect, trigger_event: TriggerEvent, battle_state: BattleState) -> void:
	if trigger == null:
		print_debug("when_trigger_run_effect: trigger is null (card: %s, ability_index: %s)" % [passive_effect.card_instance.card, passive_effect.ability_index])
		return
	
	if trigger.can_activate_single(
		trigger_event,
		battle_state,
		passive_effect.card_instance,
		passive_effect.ability_index,
		passive_effect.controller
	):
		var ability_instance := AbilityInstance.new(
			battle_state,
			passive_effect.controller,
			passive_effect.card_instance,
			passive_effect.ability_index)
		ability_instance.source_location = passive_effect.card_instance.location
		ability_instance.trigger_event = trigger_event
		var effect_task := effect.create_task(ability_instance)
		ability_instance.task = effect_task
		battle_state.fiber.run_task(effect_task)
