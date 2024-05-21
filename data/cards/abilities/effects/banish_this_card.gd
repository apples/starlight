@tool
extends CardAbilityEffect

class Task extends CardTask:
	func start() -> void:
		battle_state.banish_card(ability_instance.card_instance)
		done()
