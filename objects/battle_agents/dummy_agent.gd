extends BattleAgent


@export var deck: CardDeck = null

func get_deck() -> CardDeck:
	if deck: return deck
	return CardDeck.new()

func handle_message(message: BattleAgent.Message):
	print("dummy_agent got message: %s" % message)
	var handler: StringName = "handle_%s" % message.type
	if self.has_method(handler):
		print("dummy_agent message handler: %s" % handler)
		call(handler, message)

func handle_request_response(message: MessageTypes.RequestResponse):
	message.action_future.fulfill([])
