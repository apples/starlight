extends CardTask
class_name DealDamageTask

var target: UnitState

func start():
	print("I'm dealing damage!")
	wait_for(NestedTask.new(), to_target)

func to_target(x: int):
	print("To target %s" % x)
	done()

class NestedTask extends CardTask:
	func start():
		done(42, Result.SUCCESS)
