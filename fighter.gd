extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

enum Event
{
	ENTERING,
	RUNNING,
	LEAVING
}

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var state_prev = null
var state = _ground

var _ground_move_list:Dictionary = {
	"Walk Forward": InputReader.Move.new([], "6x*"),
	"Walk Back":    InputReader.Move.new([], "4x*"),
	"Jump":         InputReader.Move.new([], "8x*"),
	"Jump Forward": InputReader.Move.new([], "9x*"),
	"Jump Back":    InputReader.Move.new([], "7x*"),
	"Crouch":       InputReader.Move.new([], "[23]x*"),
	"Crouch Back":  InputReader.Move.new([], "1x*"),
	"Dash Forward": InputReader.Move.new(["DF"], ""),
	"Dash Back":    InputReader.Move.new(["DB"], ""),
	"Punch Light":  InputReader.Move.new([], "m ma ma"),
	"Punch Medium": InputReader.Move.new([], "m mb mb"),
	"Punch Heavy":  InputReader.Move.new([], "m mc mc"),
	"Fireball Light":  InputReader.Move.new(["QCF","HCF"], "m (ma ma | ma m)"),
	"Fireball Medium": InputReader.Move.new(["QCF","HCF"], "m (mb mb | mb m)"),
	"Fireball Heavy":  InputReader.Move.new(["QCF","HCF"], "m (mc mc | mc m)"),
	"Fireball Ex":     InputReader.Move.new(["QCF","HCF"], "m (mp mpp | mpp)"),
	"Dragon Punch Light":  InputReader.Move.new(["DP"], "m (ma ma | ma m)"),
	"Dragon Punch Medium": InputReader.Move.new(["DP"], "m (mb mb | mb m)"),
	"Dragon Punch Heavy":  InputReader.Move.new(["DP"], "m (mc mc | mc m)"),
	"Dragon Punch Ex":     InputReader.Move.new(["DP"], "m (mp mpp | mpp)")
}

var _air_move_list:Dictionary = {
	"Kick Light":  InputReader.Move.new([], "m md md"),
	"Kick Medium": InputReader.Move.new([], "m me me"),
	"Kick Heavy":  InputReader.Move.new([], "m mf mf"),
}

func _physics_process(delta):
	$InputRreader.update_input_buffer()
	# FSM stuff
	state.call(Event.RUNNING, delta)
	if state != state_prev:
		if state_prev:
			state_prev.call(Event.LEAVING)
		state.call(Event.ENTERING)
		print(state)
	state_prev = state

func _ground(event:Event, delta=0.0):
	match(event):
		Event.RUNNING:
			var moves:Array[String] = $InputRreader.get_moves(_ground_move_list)
			velocity = Vector2.ZERO
			if not is_on_floor():
				state = _falling
			elif moves.size() >0:
				match(moves.back()):
					"Jump":
						state=_jump
					"Jump Forward":
						velocity.x = SPEED
						state=_jump
					"Jump Back":
						velocity.x = -SPEED
						state=_jump
					"Walk Forward":
						velocity.x = SPEED
						move_and_slide()
					"Walk Back":
						velocity.x = -SPEED
						move_and_slide()
					var test:
						if "Crouch" not in test:
							print(test)
					

func _jump(event:Event, delta=0.0):
	match(event):
		Event.ENTERING:
			velocity.y = JUMP_VELOCITY
			move_and_slide()
		Event.RUNNING:
			if not is_on_floor():
				# Add the gravity.
				velocity.y += gravity * delta
				state = _falling
			else:
				state = _ground
			move_and_slide()
				
func _falling(event:Event, delta=0.0):
	match(event):
		Event.RUNNING:
			var moves:Array[String] = $InputRreader.get_moves(_air_move_list)
			if not is_on_floor():
				# Add the gravity.
				velocity.y += gravity * delta
				if moves.size() >0:
					print(moves.back())
			else:
				state = _ground
			move_and_slide()
