class_name BattleSideState extends Resource

var battle_state: BattleState
var agent: BattleAgent
var side: ZoneLocation.Side

var deck: Array[CardInstance] = []
var hand: Array[CardInstance] = []
var discard: Array[CardInstance] = []
var starlights: Array[CardInstance] = []
var starters: Array[CardInstance] = []

var front_row: Array[UnitState] = [null, null]
var back_row: Array[UnitState] = [null, null, null, null]

var Zone := ZoneLocation.Zone

func _init(bs: BattleState, a: BattleAgent, s: ZoneLocation.Side):
	battle_state = bs
	agent = a
	side = s
	
	print("Initting %s" % s)
	
	agent.battle_state = bs
	
	var card_deck := agent.get_deck()
	
	for card in card_deck.main_deck_cards:
		deck.append(battle_state.create_card_instance(card, ZoneLocation.new(side, Zone.Deck), side))
	for card in card_deck.starlight_cards:
		starlights.append(battle_state.create_card_instance(card, ZoneLocation.new(side, Zone.Starlight, starlights.size()), side))
	for card in card_deck.starter_unit_cards:
		starters.append(battle_state.create_card_instance(card, ZoneLocation.new(side, Zone.Floating), side))
	
	deck.shuffle()
	starlights.shuffle()

func get_field_zone(zone: ZoneLocation.Zone) -> Array[UnitState]:
	match zone:
		Zone.FrontRow: return front_row
		Zone.BackRow: return back_row
		_:
			push_error("Zone is non-field: %s" % zone)
			return front_row

func remove_from_hand(card_instance: CardInstance):
	var idx := hand.find(card_instance)
	assert(idx != -1, "Card not found in hand.")
	hand.remove_at(idx)
	for i in range(hand.size()):
		hand[i].location.slot = i

func get_all_units() -> Array[UnitState]:
	var results: Array[UnitState] = []
	results.append_array(front_row)
	results.append_array(back_row)
	return results.filter(func (u): return u != null)
