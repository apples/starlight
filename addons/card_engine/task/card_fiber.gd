extends Node
class_name CardFiber

var battle_state: BattleState = null

# This is set when execute_one is executing a task.
var is_executing: bool = false

# This is set when stop_all_tasks is called while a task is being executed. 
var pending_stop_all: bool = false

func _ready():
	battle_state = get_parent() as BattleState

# Starts a task. The task will be put on top of the stack.
func run_task(task: CardTask):
	task.battle_state = battle_state
	task.fiber = self
	add_child(task)

# Executes the next step of the first pending task.
func execute_one() -> bool:
	assert(!pending_stop_all)
	
	if is_executing:
		push_error("Cannot execute a task while another task is being executed.")
		return false
	
	if get_child_count() == 0:
		return false
	
	is_executing = true
	
	var last_child = get_child(-1)
	assert(last_child is CardTask)
	var task = last_child as CardTask
	
	task.run()
	
	if task.is_done():
		task.queue_free()
	
	is_executing = false
	
	if pending_stop_all:
		pending_stop_all = false
		stop_all_tasks()
	
	return true

# Stops and removes all pending tasks.
func stop_all_tasks() -> void:
	if is_executing:
		pending_stop_all = true
		return
	
	for child in get_children():
		assert(child is CardTask)
		var task = child as CardTask
		task.cancel()
		task.queue_free()
		remove_child(task)
