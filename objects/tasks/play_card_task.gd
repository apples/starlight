class_name PlayCardTask extends CardTask

var card_instance: CardInstance = null
var side: ZoneLocation.Side = ZoneLocation.Side.Player

func _init(ci: CardInstance, s: ZoneLocation.Side):
	card_instance = ci
	side = s

func start() -> void:
	var state := battle_state.get_side_state(side)
	var card := card_instance.card

	if card.is_unit:
		return play_unit_card()
	else:
		return play_spell_card()

func play_unit_card() -> void:
	var side_state := battle_state.get_side_state(side)

	var availableBenchIndex := 0 # ask player to choose location

	if availableBenchIndex < 0:
		battle_state.send_message_to(side, MessageTypes.Alert.new({ text = "Bench is full!" }))
		return done()

	var location = ZoneLocation.new(side, ZoneLocation.Zone.BackRow, availableBenchIndex)

	battle_state.summon_unit(card_instance, location)

	return done()

func play_spell_card():
	push_error("Not implemented")
	done(null, Result.FAILED)
