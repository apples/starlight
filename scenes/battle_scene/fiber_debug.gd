extends PanelContainer


@export var fiber: CardFiber

@onready var fiber_tree: VBoxContainer = %FiberTree

func _ready() -> void:
	visibility_changed.connect(_visibility_changed)
	if not fiber:
		hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for c in fiber_tree.get_children():
		fiber_tree.remove_child(c)
		c.queue_free()
	
	for c in fiber.get_children():
		_add_task(c, 0)

func _add_task(task: Node, indent: int) -> void:
	var label := Label.new()
	label.text = "| ".repeat(indent) + task.name
	fiber_tree.add_child(label)
	
	for c in task.get_children():
		_add_task(c, indent + 1)

func _visibility_changed() -> void:
	set_process(visible)
