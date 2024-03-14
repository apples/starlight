extends Node
class_name CardFiber
## A fiber system used for card effects and other async tasks.

var battle_state: BattleState = null

## This is set when execute_one is executing a task.
var is_executing: bool = false

## This is set when stop_all_tasks is called while a task is being executed. 
var pending_stop_all: bool = false

func _ready():
	battle_state = get_parent() as BattleState

## Starts a task. The task will be put on top of the stack (last child).
##
## [param task]: The new task to start. Will be given a name if a name isn't present.
func run_task(task: CardTask):
	assert(!task.is_inside_tree(), "Task already in tree!")
	if task.name == "":
		var task_name := (task.get_script() as Script).resource_path.get_file()
		task.name = task_name if task_name else "unknown_task"
	task.battle_state = battle_state
	task.fiber = self
	print_rich("[color=green][lb]CardFiber[rb][/color] running task [i]%s[/i]" % [task])
	add_child(task)

## Executes the next step of the latest pending task. Returns false if there are no tasks.
func execute_one() -> bool:
	assert(!pending_stop_all)
	assert(not is_executing)
	
	if is_executing:
		push_error("Cannot execute a task while another task is being executed.")
		return false
	
	if get_child_count() == 0:
		return false
	
	is_executing = true
	
	var task := get_child(-1) as CardTask
	assert(task)
	
	if task.can_run():
		task.run()
	
	if task.is_done():
		assert(task.get_child_count() == 0)
		task.queue_free()
	
	is_executing = false
	
	if pending_stop_all:
		pending_stop_all = false
		stop_all_tasks()
	
	return true

## Stops and removes all tasks.
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
