extends BattleScreenLayer

var card_instance: CardInstance = null

signal done()

@onready var card_plane = %CardPlane

@onready var click_target_agent: ClickTargetAgent = $ClickTargetAgent

func uncover():
	super.uncover()
	
	click_target_agent.set_criteria({ group_layer_mask = ClickTargetGroup.LAYER_NONE })
	
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

