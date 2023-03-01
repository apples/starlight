class_name CardAbilityCost
extends Resource

func can_be_paid(battle_state: BattleState, card_instance: CardInstance, user_side: ZoneLocation.Side) -> bool:
	push_error("CardAbilityCost: can_be_paid() not implemented")
	return false

func pay_task() -> CardTask:
	push_error("CardAbilityCost: pay_task() not implemented")
	return null
