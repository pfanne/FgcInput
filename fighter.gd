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

# a = light punch, b = medium punch, c = heavy punch, p = any punch
# x = any button, m = any direction
# A = at least light punch, B = at least medium punch, C = at least heavy punch
# d = light kick, e = medium kick, f = heavy kick, k = any kick
# D = at least light kick, E = at least medium kick, F = at least heavy kick
# P = at least some punch
# K = at least some kick
# numpad direction:
#     ^
#   7 8 9
# < 4 5 6 >
#   1 2 3
#     v
var _ground_move_list:Array[InputReader.Move] = [
	InputReader.Move.new("Walk Forward",["WF"],  ""),
	InputReader.Move.new("Walk Back",["WB"],     ""),
	InputReader.Move.new("Crouch",["CR"],        ""),
	InputReader.Move.new("Crouch Back",["CRB"],  ""),
	InputReader.Move.new("Dash Forward",["DF"],  ""),
	InputReader.Move.new("Dash Back",["DB"],     ""),
	InputReader.Move.new("Punch Light",[],  "(mmAmA|mmAmm)$"),
	InputReader.Move.new("Punch Medium",[], "(mmBmB|mmBmm)$"),
	InputReader.Move.new("Punch Heavy",[],  "(mmCmC|mmCmm)$"),
	InputReader.Move.new("Kick Light",[],   "(mmDmD|mmDmm)$"),
	InputReader.Move.new("Kick Medium",[],  "(mmDmE|mmEmm)$"),
	InputReader.Move.new("Kick Heavy",[],   "(mmFmF|mmFmm)$"),
	InputReader.Move.new("Grab",[],         "(mm[ad]mad|mmad)$"),
	InputReader.Move.new("Jump",["JU"],          ""),
	InputReader.Move.new("Jump Forward",["JUF"], ""),
	InputReader.Move.new("Jump Back",["JUB"],    ""),
	InputReader.Move.new("Fireball Light",["QCF","HCF"],  "(mmama|mmamm)$"),
	InputReader.Move.new("Fireball Medium",["QCF","HCF"], "(mmbmb|mmbmm)$"),
	InputReader.Move.new("Fireball Heavy",["QCF","HCF"],  "(mmcmc|mmcmm)$"),
	InputReader.Move.new("Fireball Ex",["QCF","HCF"],     "(mmpp|mmpmpp)$"),
	InputReader.Move.new("Dragon Punch Light",["DP"],     "(mmama|mmamm)$"),
	InputReader.Move.new("Dragon Punch Medium",["DP"],    "(mmbmb|mmbmm)$"),
	InputReader.Move.new("Dragon Punch Heavy",["DP"],     "(mmcmc|mmcmm)$"),
	InputReader.Move.new("Dragon Punch Ex",["DP"],        "(mmpp|mmpmpp)$"),
	InputReader.Move.new("Round House",["FCF"],           "(mmkmk|mmkmm)$"),
	InputReader.Move.new("Giga Punch",["SF"],             "(mmPm|mmPmP)$"),
	InputReader.Move.new("Giga Kick",["SF"],              "(mmKm|mmKmK)$")
]

var _air_move_list:Array[InputReader.Move] = [
	InputReader.Move.new("Jump Kick Light",[],  "(mmdmd|mmdm)$"),
	InputReader.Move.new("Jump Kick Medium",[], "(mmeme|mmem)$"),
	InputReader.Move.new("Jump Kick Heavy",[],  "(mmfmf|mmfm)$"),
	InputReader.Move.new("Air Round House",["FCF"], "(mmkmk|mmkm)$")
]

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
					var not_mapped:
						if "Crouch" not in not_mapped:
							print(not_mapped)
					

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
