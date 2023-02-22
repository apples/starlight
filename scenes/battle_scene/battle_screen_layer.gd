class_name BattleScreenLayer extends Node3D

@export var battle_scene: BattleScene = null
@export var battle_state: BattleState = null

func cover():
	process_mode = Node.PROCESS_MODE_DISABLED

func uncover():
	process_mode = Node.PROCESS_MODE_INHERIT

func remove_screen():
	assert(battle_scene.screen_layer_stack.back() == self)
	battle_scene.pop_screen()

