extends BattleScreenLayer

var text: String

var options: Array[String]

signal action_chosen(action)

var _dialog_button := preload("res://objects/screen_layers/overlay_dialog/dialog_button.tscn")

@onready var text_label = %TextLabel
@onready var button_container = %ButtonContainer

@onready var click_target_agent: ClickTargetAgent = $ClickTargetAgent

func _ready():
	text_label.text = text
	for o in options:
		var b := _dialog_button.instantiate()
		b.text = o
		b.clicked.connect(func (): _on_button_clicked(o))
		button_container.add_child(b)

func uncover():
	super.uncover()
	
	click_target_agent.set_criteria({
		group_layer_mask = ClickTargetGroup.LAYER_ACTIONS,
		target_filter = func (cl: ClickTarget):
			return self.is_ancestor_of(cl)
	})
	
	battle_scene.set_screen_label("")
	
	var results := click_target_agent.get_enabled_click_targets()
	
	if results.size() > 0:
		results[0].make_current()


func _on_button_clicked(text: String):
	remove_screen()
	action_chosen.emit(text)


func _on_click_target_agent_cancelled():
	remove_screen()
	action_chosen.emit(null)

