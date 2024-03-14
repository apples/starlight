extends Node
class_name CardTask
## A fiber task to be used with [class CardFiber].

## Task status
enum Status {
	## The task is awaiting execution.
	PENDING = 1,
	## The task is awaiting a future value or other task.
	WAITING = 2,
	## The task is complete.
	DONE = 3,
}

## Task result
enum Result {
	## The task requires more execution or is awaiting something.
	PENDING = 0,
	## The task is done, and finished successfully.
	SUCCESS = 1,
	## The task is done, and failed.
	FAILED = 2,
	## The task was cancelled before finishing.
	CANCELLED = 3,
}

## A basic future/promise value.
class Future:
	var _value
	
	## If true, the future has been fulfilled with a value.
	var is_fulfilled: bool = false
	
	## The fulfilled future value.
	var value: Variant: get = get_value
	
	func _to_string():
		return "<unfulfilled future>" if not is_fulfilled else ("<fulfilled, %s>" % [_value])
	
	## Safely gets the value. Raises an error if the future is not fulfilled.
	func get_value():
		if not is_fulfilled:
			push_error("Cannot get value from unfulfilled future")
			breakpoint
		return _value
	
	## Fulfils the future with the given value.
	func fulfill(v):
		assert(!is_fulfilled, "Cannot fulfil an already fulfilled future")
		_value = v
		is_fulfilled = true

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

var filename: String = get_script().resource_path.get_file()

func _ready():
	assert(fiber != null)
	assert(battle_state != null)

func _to_string():
	return "<CardTask(%s)>" % [filename]

func is_done() -> bool: return status == Status.DONE

func can_run() -> bool:
	return _awaited_future == null or _awaited_future.is_fulfilled

func info(what: String, from_task: bool = true):
	var s := "INFO: " if from_task else ""
	if ability_instance:
		var n := ability_instance.card_instance.card.card_name
		print_rich("[color=cyan][lb]CardTask[rb][/color] (%s) %s: %s%s" % [n, filename, s, what])
	elif "passive_effect" in self and self.passive_effect:
		var n = self.passive_effect.card_instance.card.card_name
		print_rich("[color=cyan][lb]CardTask[rb][/color] (%s) %s: %s%s" % [n, filename, s, what])
	else:
		print_rich("[color=cyan][lb]CardTask[rb][/color] %s: %s%s" % [filename, s, what])

func run() -> void:
	if is_done():
		push_error("Attempted to run a CardTask which is already done.")
		breakpoint
		return
	
	if _awaited_future and not _awaited_future.is_fulfilled:
		push_error("Waiting task must not be run.")
		breakpoint
		return
	
	_did_update_state = false
	
	if !_awaited_future:
		info("Running state \"%s\"" % [_next_state], false)
		self.call(_next_state)
	else:
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
		info("Running state \"%s\"" % [state], false)
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
	info("<await> %s" % [future], false)
	_awaited_future = future

func _set_awaiting_task(task: CardTask):
	assert(!_awaited_future, "Already awaiting something.")
	info("<await> %s" % [task.filename], false)
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
		fiber.run_task(task)
	_set_awaiting_task(task)
	_next_state = next.get_method()
	_fail_state = on_fail.get_method() if on_fail.is_valid() else &"_default_fail_state"
	_did_update_state = true

func become(task: CardTask) -> void:
	wait_for(task, self._become_done, self._become_done)

func _become_done(value) -> void:
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

func assign_props(from: Object) -> void:
	for prop in from.get_script().get_script_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			# Skip over variable props
			if prop.name.ends_with("_var"):
				continue
			
			# Check for an apply variable prop instead of value
			var varkey: String = prop.name + "_var"
			if varkey in from:
				var varname: String = from[varkey]
				if varname != "":
					assert(ability_instance != null)
					assert(varname in ability_instance.variables)
					self[prop.name] = ability_instance.variables[varname]
					continue
			
			self[prop.name] = from[prop.name]
	
	if filename == "":
		filename = from.get_script().resource_path.get_file()
	
