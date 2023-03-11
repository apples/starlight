extends Node
class_name CardTask

enum Status {
	PENDING = 1,
	WAITING = 2,
	DONE = 3,
}

enum Result {
	PENDING = 0,
	SUCCESS = 1,
	FAILED = 2,
	CANCELLED = 3,
}

class Future:
	var _value
	var is_fulfilled: bool = false
	var value:
		get:
			assert(is_fulfilled, "Cannot get value from unfulfilled future")
			return _value
	func fulfill(v):
		assert(!is_fulfilled, "Cannot fulfil an already fulfilled future")
		_value = v
		is_fulfilled = true
	func _to_string():
		return "<unfulfilled future>" if not is_fulfilled else ("<fulfilled, %s>" % [_value])

class ResultValue:
	var value
	var result: Result
	func _init(v, r: Result):
		value = v
		result = r

signal finished()

# Standard properties
var battle_state: BattleState = null
var fiber: CardFiber = null
var ability_instance: AbilityInstance = null

# Execution status
var status: Status = Status.PENDING
var _next_state: StringName = &"start"
var _fail_state: StringName = &"_impossible_state"

# Results when done
var _result_future: Future = Future.new()

# Futures handling
var _awaited_future: Future = null
var _awaited_task: CardTask = null
var _awaited_task_result: Result = Result.PENDING

# Used for debugging purposes
var _did_update_state: bool = false

@onready var filename: String = get_script().resource_path.get_file()

func _ready():
	assert(fiber != null)
	assert(battle_state != null)

func is_done() -> bool: return status == Status.DONE

func can_run() -> bool:
	return _awaited_future == null or _awaited_future.is_fulfilled

func run() -> void:
	if is_done():
		push_error("Attempted to run a CardTask which is already done.")
		return
	
	_did_update_state = false
	
	if !_awaited_future:
		print("[CardTask] %s: %s" % [filename, _next_state])
		self.call(_next_state)
	else:
		assert(_awaited_future.is_fulfilled, "Waiting tasks must not be run!")
		if not _awaited_future.is_fulfilled:
			push_error("Waiting task must not be run.")
			_did_update_state = false
			return
		var state := _next_state
		var value = _awaited_future.value
		if value is ResultValue:
			var result: ResultValue = value
			assert(result)
			value = result.value
			_awaited_task_result = result.result
			if _awaited_task_result != Result.SUCCESS:
				state = _fail_state
		_awaited_future = null
		print("[CardTask] %s: %s" % [filename, state])
		_call_with_optional_argument(state, value)
	
	assert(_did_update_state, "Must call wait_for(), done(), or goto().")
	_did_update_state = false

func _call_with_optional_argument(method: StringName, argument):
	# require non-null arguments to be received
	if argument != null:
		return self.call(method, argument)
	# if null, we need to check if the method takes an argument or not
	var script = self.get_script()
	while script:
		for m in script.get_script_method_list():
			if m.name == method:
				if m.args.size() == 0:
					return self.call(method)
				else:
					return self.call(method, argument)
		script = script.get_base_script()
	push_error("Method not found in scripts. Built-in methods are not supported.")
	return null

func _default_fail_state(x):
	done(x, Result.FAILED)

func _impossible_state(x):
	assert(false, "This should never happen")
	push_error("Impossible state reached")
	done(x, Result.FAILED)

func _set_awaited_future(future: Future):
	assert(!_awaited_future, "Already awaiting something.")
	print("[CardTask] <await> %s: %s" % [filename, future])
	_awaited_future = future

func _set_awaiting_task(task: CardTask):
	assert(!_awaited_future, "Already awaiting something.")
	print("[CardTask] <await> %s: %s" % [filename, task.filename])
	_awaited_future = task._result_future

func run_task(task: CardTask) -> void:
	fiber.run_task(task)

func wait_for_future(future: Future, next: Callable) -> void:
	assert(future, "Future cannot be null.")
	assert(next.get_object() == self, "Next state must belong to this object.")
	status = Status.WAITING
	_set_awaited_future(future)
	_next_state = next.get_method()
	_fail_state = &"_impossible_state"
	_did_update_state = true

func wait_for(task: CardTask, next: Callable, on_fail: Callable = Callable()) -> void:
	assert(!_did_update_state, "Duplicate state update.")
	assert(next.get_object() == self, "Next state must belong to this object.")
	# (on_fail == next) due to bug in calling get_object() multiple times
	assert(on_fail == next or !on_fail.is_valid() or on_fail.get_object() == self, "Fail state must belong to this object.")
	assert(!_awaited_future, "Already awaiting something.")
	status = Status.WAITING
	if !task.is_inside_tree():
		run_task(task)
	_set_awaiting_task(task)
	_next_state = next.get_method()
	_fail_state = on_fail.get_method() if on_fail.is_valid() else &"_default_fail_state"
	_did_update_state = true

func become(task: CardTask):
	wait_for(task, self._become_done, self._become_done)

func _become_done(value):
	done(value, _awaited_task_result)

func goto(next: Callable) -> void:
	assert(!_did_update_state, "Duplicate state update.")
	assert(next.get_object() == self, "Next state must belong to this object.")
	status = Status.WAITING
	_next_state = next.get_method()
	_fail_state = &"_impossible_state"
	_did_update_state = true

func done(value = null, result: Result = Result.SUCCESS) -> void:
	assert(!_did_update_state, "Duplicate state update.")
	assert(result != Result.PENDING, "Result cannot be PENDING.")
	assert(status != Status.DONE, "Cannot complete a task twice.")
	status = Status.DONE
	_next_state = &"_impossible_state"
	_fail_state = &"_impossible_state"
	_did_update_state = true
	_result_future.fulfill(ResultValue.new(value, result))
	finished.emit()

func fail(value = null) -> void:
	done(value, Result.FAILED)

func cancel() -> void:
	if _awaited_task != null and _awaited_task.status != Status.DONE:
		_awaited_task.cancel()
	done(null, Result.CANCELLED)
