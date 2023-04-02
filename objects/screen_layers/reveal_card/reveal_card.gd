extends BattleScreenLayer

var card_instance: CardInstance = null

signal done()

@onready var card_plane = %CardPlane

func uncover():
	super.uncover()
	
	var results := ClickTargetManager.set_criteria(0, func (cl: ClickTarget):
		return false
	)
	
	battle_scene.set_screen_label("")
	
	card_plane.card = card_instance.card
	
	create_tween() \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_ELASTIC) \
		.tween_property(card_plane, "rotation_degrees", Vector3(0, 0, 0), 1.0) \
		.finished.connect(_tween_finished)

func _tween_finished():
	battle_scene.pop_screen()
	done.emit()

