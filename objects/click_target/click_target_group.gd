class_name ClickTargetGroup extends Node

enum {
	LAYER_BATTLE = 1,
	LAYER_PLAYER = 2,
	LAYER_OPPONENT = 4,
	LAYER_FIELD = 8,
	LAYER_HAND = 16,
	LAYER_ACTIONS = 32,
	LAYER_CARD_ABILITIES = 64,
}

@export_flags("Battle", "Player", "Opponent", "Field", "Hand", "Actions", "Card Abilities") var layers: int = LAYER_BATTLE

@export var nav_left: ClickTargetGroup
@export var nav_right: ClickTargetGroup

var targets: Array[ClickTarget] = []

signal click_target_added(click_target: ClickTarget)
signal click_target_removed(click_target: ClickTarget)

func _ready():
	ClickTargetManager.add_group(self)
	tree_exiting.connect(func (): ClickTargetManager.remove_group(self))

func add_target(target: ClickTarget):
	assert(not target in targets)
	targets.append(target)
	click_target_added.emit(target)

func remove_target(target: ClickTarget):
	assert(target in targets)
	targets.remove_at(targets.find(target))
	click_target_removed.emit(target)

func matches(mask: int) -> bool:
	return layers & mask != 0
