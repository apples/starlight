class_name BattleScene extends Node


@onready var fiber = $BattleState/CardFiber

# Called when the node enters the scene tree for the first time.
func _ready():
	fiber.run_task(RootBattleTask.new())


func _process(delta):
	fiber.execute_one()
