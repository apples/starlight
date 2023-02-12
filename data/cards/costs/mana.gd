class_name ManaCost
extends CardAbilityCost

@export var amount: int = 1

func can_be_paid() -> bool:
	push_error("CardAbilityCost: can_be_paid() not implemented")
	return false

func pay():
	push_error("CardAbilityCost: pay() not implemented")
