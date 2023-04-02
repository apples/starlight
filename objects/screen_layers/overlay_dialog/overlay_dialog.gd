extends BattleScreenLayer

var text: String

var options: Array[String]

signal action_chosen(action)

var _dialog_button := preload("res://objects/screen_layers/overlay_dialog/dialog_button.tscn")

@onready var text_label = %TextLabel
@onready var button_container = %ButtonContainer

func _ready():
	text_label.text = text
	for o in options:
		var b := _dialog_button.instantiate()
		b.text = o
		b.clicked.connect(func (): _on_button_clicked(o))
		button_container.add_child(b)

func uncover():
	super.uncover()
	
	var results := ClickTargetManager.set_criteria(
		ClickTargetGroup.LAYER_ACTIONS, func (cl: ClickTarget):
		return self.is_ancestor_of(cl)
	)
	
	battle_scene.set_screen_label("")
	
	if results.size() > 0:
		results[0].make_current()


func _on_button_clicked(text: String):
	remove_screen()
	action_chosen.emit(text)


func _on_click_target_agent_cancelled():
	remove_screen()
	action_chosen.emit(null)

