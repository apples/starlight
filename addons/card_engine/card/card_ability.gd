class_name CardAbility
extends Resource

enum CardAbilityType {
	ACTION = 1,
	ATTACK = 2,
	TRIGGER = 3,
	PASSIVE = 4,
	STARLIGHT = 5,
}

enum CardAbilityAttributes {
	OPTIONAL = 1,
	MIRACLE = 2,
}

@export var ability_name: String
@export_multiline var description: String

@export var type: CardAbilityType = CardAbilityType.ACTION
@export var trigger: CardAbilityTrigger = null
@export var cost: CardAbilityCost = null
@export var passive: CardAbilityPassive = null
@export var effect: CardAbilityEffect = null

