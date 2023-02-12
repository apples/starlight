extends BattleAgent

@export var deck: CardDeck = null

func get_deck() -> CardDeck:
	if deck: return deck
	return CardDeck.new()

func handle_message(message: Dictionary):
	print("Player got message: %s" % message)
