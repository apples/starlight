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
	var value
	var fulfilled: bool = false
	func fulfill(v):
		value = v
		fulfilled = true

signal finished()

var battle_state: BattleState = null
var fiber: CardFiber = null
var source_card_instance: BattleState.CardInstance = null
var source_location: BattleState.ZoneLocation = null

var status: Status = Status.PENDING
var next_state: StringName = &"start"
var fail_state: StringName = StringName()

var result: Result = Result.PENDING
var value = null

var awaiting_future: Future = null
var future_next_state: StringName = StringName()

# Used for debugging purposes
var did_update_state: bool = false

func is_done() -> bool: return status == Status.DONE

func run() -> void:
	if is_done():
		push_error("Attempted to run a CardTask which is already done.")
		return
	
	did_update_state = false
	
	var awaiting = get_awaiting()
	if !awaiting:
		self.call(next_state)
	else:
		if awaiting.is_done():
			var state := next_state if awaiting.result == Result.SUCCESS else fail_state
			remove_child(awaiting)
			_call_with_optional_argument(state, awaiting.value)
			awaiting.queue_free()
		else:
			awaiting.run()
			did_update_state = true
	
	assert(did_update_state, "Must call wait_for(), done(), or goto().")
	did_update_state = false

func _call_with_optional_argument(method: StringName, argument):
	# require non-null arguments to be received
	if argument != null:
		return self.call(method, argument)
	# if null, we need to check if the method takes an argument or not
	var script := self.get_script()
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

func default_fail_state(x):
	done(Result.FAILED, x)

func get_awaiting() -> CardTask:
	var child := get_child(0) if get_child_count() > 0 else null
	if !child: return null
	assert(child is CardTask)
	return child as CardTask

func set_awaiting(task: CardTask):
	assert(!get_child(0), "Already awaiting something.")
	add_child(task)

func run_task(task: CardTask) -> void:
	fiber.run_task(task)

func wait_for(task: CardTask, next: Callable, on_fail: Callable = Callable()) -> void:
	assert(!did_update_state, "Duplicate state update.")
	assert(next.get_object() == self, "Next state must belong to this object.")
	assert(!on_fail.is_valid() or on_fail.get_object() == self, "Fail state must belong to this object.")
	assert(!get_awaiting(), "Already awaiting another task.")
	self.status = Status.WAITING
	set_awaiting(task)
	self.next_state = next.get_method()
	self.fail_state = on_fail.get_method() if on_fail.is_valid() else &"default_fail_state"
	self.did_update_state = true

func goto(next: Callable) -> void:
	assert(!did_update_state, "Duplicate state update.")
	assert(next.get_object() == self, "Next state must belong to this object.")
	self.status = Status.WAITING
	self.next_state = next.get_method()
	self.fail_state = StringName()
	self.did_update_state = true

func done(result: Result = Result.SUCCESS, value = null) -> void:
	assert(!did_update_state, "Duplicate state update.")
	assert(result != Result.PENDING, "Result cannot be PENDING.")
	self.status = Status.DONE
	self.result = result
	self.value = value
	self.next_state = StringName()
	self.fail_state = StringName()
	self.did_update_state = true
	emit_signal("finished")

func cancel() -> void:
	var awaiting = get_awaiting()
	if awaiting:
		awaiting.cancel()
		awaiting.queue_free()
	done(Result.CANCELLED)

func wait_for_future(future: Future, next: Callable) -> void:
	assert(next.get_object() == self, "Next state must belong to this object.")
	awaiting_future = future
	future_next_state = next.get_method()
	goto(check_future)

func check_future():
	if !awaiting_future.fulfilled:
		goto(check_future)
		return
	var value = awaiting_future.value
	awaiting_future = null
	future_next_state = StringName()
	self.call(future_next_state, value)
