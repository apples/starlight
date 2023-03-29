class_name CardZoneArray extends RefCounted

var side: ZoneLocation.Side
var zone: ZoneLocation.Zone

var _card_instances: Array[CardInstance] = []

var _iter_idx: int

func _init(p_side: ZoneLocation.Side, p_zone: ZoneLocation.Zone):
	side = p_side
	zone = p_zone

func size() -> int:
	return _card_instances.size()

func get_card(i: int) -> CardInstance:
	assert(i >= 0 && i < _card_instances.size())
	return _card_instances[i]

func add_card(card_instance: CardInstance):
	assert(card_instance.location.zone != zone)
	card_instance.location = ZoneLocation.new(side, zone, _card_instances.size())
	_card_instances.append(card_instance)

func remove_card(card_instance: CardInstance):
	assert(card_instance.location.side == side)
	assert(card_instance.location.zone == zone)
	assert(card_instance.location.slot >= 0 and card_instance.location.slot < _card_instances.size())
	_card_instances.remove_at(card_instance.location.slot)
	for i in range(card_instance.location.slot, _card_instances.size()):
		_card_instances[i].location.slot = i
	card_instance.location = ZoneLocation.new(side, ZoneLocation.Zone.Floating)

func shuffle() -> void:
	_card_instances.shuffle()
	for i in range(_card_instances.size()):
		_card_instances[i].location.slot = i

func _iter_init(arg) -> bool:
	_iter_idx = 0
	return _iter_idx < _card_instances.size()

func _iter_next(arg) -> bool:
	_iter_idx += 1
	return _iter_idx < _card_instances.size()

func _iter_get(arg) -> CardInstance:
	return _card_instances[_iter_idx]
