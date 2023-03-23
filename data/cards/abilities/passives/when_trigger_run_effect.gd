@tool
extends CardAbilityPassive

@export var trigger: CardAbilityTrigger
@export var effect: CardAbilityEffect

class Task extends CardAbilityPassiveTask:
	var trigger: CardAbilityTrigger
	var effect: CardAbilityEffect
	
	func start():
		if trigger.can_activate_single(
			trigger_event,
			battle_state,
			passive_effect.unit.card_instance,
			passive_effect.ability_index,
			passive_effect.controller
		):
			var ability_instance := AbilityInstance.new(
				battle_state,
				passive_effect.controller,
				passive_effect.unit.card_instance,
				passive_effect.ability_index)
			ability_instance.source_location = passive_effect.unit.card_instance.location
			ability_instance.trigger_event = trigger_event
			var effect_task := effect.create_task(ability_instance)
			ability_instance.task = effect_task
			become(effect_task)
		else:
			done()

