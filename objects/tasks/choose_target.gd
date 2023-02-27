extends CardTask
class_name ChooseTargetTask

var who: ZoneLocation.Side = ZoneLocation.Side.Player
var allowed_locations: Array[ZoneLocation]

func start():
	var future := Future.new()
	battle_state.send_message_to(who, MessageTypes.ChooseTarget.new({ allowed_locations = allowed_locations, future = future }))
	wait_for_future(future, chosen)

func chosen(where: ZoneLocation):
	done(where, CardTask.Result.SUCCESS)
