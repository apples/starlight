extends CardTask
class_name DealDamageTask

var target 

func start():
	print("I'm dealing damage!")
	wait_for(NestedTask.new(), to_target)

func to_target(x: int):
	print("To target %s" % x)
	done()

class NestedTask extends CardTask:
	func start():
		done(Result.SUCCESS, 42)
