class_name ZoneLocation extends RefCounted

enum Side {
	Player,
	Opponent,
}

enum Zone {
	FrontRow,
	BackRow,
	Hand,
	Deck,
	Discard,
	Grace,
	Banish,
	Floating,
	#Rulecard,
}

var side: ZoneLocation.Side
var zone: Zone
var slot: int

func _init(s: ZoneLocation.Side, z: Zone, i: int = -1):
	side = s
	zone = z
	slot = i

func equals(other: ZoneLocation):
	return tuple() == other.tuple()

func tuple() -> Array:
	return [side, zone, slot]

func duplicate() -> ZoneLocation:
	return ZoneLocation.new(side, zone, slot)

func is_field() -> bool:
	match zone:
		Zone.FrontRow,Zone.BackRow:
			return true
	return false

func is_hidden() -> bool:
	match zone:
		Zone.Hand, Zone.Deck, Zone.Grace, Zone.Banish:
			return true
	return false

func _to_string():
	return "<%s, %s, %s>" % [ZoneLocation.Side.keys()[side], Zone.keys()[zone], slot]

static func flip(s: ZoneLocation.Side) -> ZoneLocation.Side:
	match s:
		ZoneLocation.Side.Player: return ZoneLocation.Side.Opponent
		ZoneLocation.Side.Opponent: return ZoneLocation.Side.Player
		_:
			push_error("Not implemented")
			return ZoneLocation.Side.Player
