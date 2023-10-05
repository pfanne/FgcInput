extends Node
class_name InputReader

const BUFFER_MAX_SIZE:int = 60

# mapsinput_buffer up down left and right to the numpad directions
# 7 8 9
# 4 5 6input_buffer
# 1 2 3
const DIRECTION_MAPPING_CAPCOM:PackedByteArray = [
	   # U D L R
	5, # 0 0 0 0
	6, # 0 0 0 1
	4, # 0 0 1 0
	5, # 0 0 1 1
	2, # 0 1 0 0
	3, # 0 1 0 1
	1, # 0 1 1 0
	2, # 0 1 1 1
	8, # 1 0 0 0
	9, # 1 0 0 1
	7, # 1 0 1 0
	8, # 1 0 1 1
	5, # 1 1 0 0
	6, # 1 1 0 1
	4, # 1 1 1 0
	5, # 1 1 1 1
]

const BUTTON_MAPPING:Dictionary = {
	"light_punch":  "a",
	"medium_punch": "b",
	"heavy_punch":  "c",
	"light_kick":   "d",
	"medium_kick":  "e",
	"heavy_kick":   "f"
}

class Motion:
	var _name:String
	var _regex:RegEx
	func _init(name:String, regex_string:String):
		_name = name
		_regex = RegEx.new()
		_regex.compile(regex_string)
	func _is_motion(buffer:Array[String]) -> bool:
		var joined_buffer = "".join(buffer.map(func(x:String): return x[0]))
		if _regex.search(joined_buffer):
			return true
		else:
			return false

class Move:
	var _name:String
	var _motions:Array[String]
	var _button_regex:RegEx
	func _init(name:String, motions:Array[String], button_regex:String):
		_name = name
		_motions = motions
		_button_regex = RegEx.new()
		# parse custom regex expressions
		button_regex = RegEx.create_from_string("m").sub(button_regex,"[0-9]",true)
		button_regex = RegEx.create_from_string("p").sub(button_regex,"[abc]",true)
		button_regex = RegEx.create_from_string("k").sub(button_regex,"[def]",true)
		button_regex = RegEx.create_from_string("x").sub(button_regex,"[abcdef]",true)
		button_regex = RegEx.create_from_string("A").sub(button_regex,"(ab?c?)",true)
		button_regex = RegEx.create_from_string("B").sub(button_regex,"(a?bc?)",true)
		button_regex = RegEx.create_from_string("C").sub(button_regex,"(a?b?c)",true)
		button_regex = RegEx.create_from_string("D").sub(button_regex,"(de?f?)",true)
		button_regex = RegEx.create_from_string("E").sub(button_regex,"(d?ef?)",true)
		button_regex = RegEx.create_from_string("F").sub(button_regex,"(d?e?f)",true)
		button_regex = RegEx.create_from_string("P").sub(button_regex,"(ab?c?|a?bc?|a?b?c)",true)
		button_regex = RegEx.create_from_string("K").sub(button_regex,"(de?f?|d?ef?|d?e?f)",true)
		_button_regex.compile(button_regex)
	func _is_move(motions:Array[String], buffer:Array[String]) -> bool:
		var joined_buffer = "".join(buffer.slice(-10))
		var motion_found:bool = false
		if _motions.size() == 0:
			motion_found = true
		else:
			for motion in motions:
				if motion in _motions:
					motion_found = true
		if motion_found==true and _button_regex.search(joined_buffer):
			return true
		else:
			return false

var motion_list:Array[Motion] = [
	Motion.new("WF",  "6$"),
	Motion.new("WB",  "4$"),
	Motion.new("CR",  "[23]$"),
	Motion.new("CRB", "1$"),
	Motion.new("JU",  "8$"),
	Motion.new("JUF", "9$"),
	Motion.new("JUB", "7$"),
	Motion.new("DF",  "(?=5+6+5+6$).{1,20}"),
	Motion.new("DB",  "(?=5+4+5+4$).{1,20}"),
	Motion.new("QCF", "(?=2+3+6+5*$).{1,20}"),
	Motion.new("QCB", "(?=2+1+4+5*$).{1,20}"),
	Motion.new("DP",  "(?=6+5*2+3+6*5*$|6+3+6+5*$|3+5+3+6*5*$).{1,20}"),
	Motion.new("HCF", "(?=4+1+2*3+6+5*$).{1,20}"),
	Motion.new("HCB", "(?=6+3+2*1+4+5*$).{1,20}"),
	Motion.new("FCF", "(?=6+9+8*7+4*1+2*3+6*5*$).{1,30}"),
	Motion.new("BCH", "(?=4{30,}1*[25]*3*6+5*$).{1,40}"),
	Motion.new("SF",  "(?=2+3+6+5*2+3+6+5*$).{1,40}"),
	Motion.new("SB",  "(?=2+1+4+5*2+1+4+5*$).{1,40}"),
]

@export var button_prefix:String = "p1_"
var input_buffer:Array[String] = []
var facing_right:bool = true


func setForwardRight():
	facing_right = true
	
func setForwardLeft():
	facing_right = false
	
func update_input_buffer():
	input_buffer.push_back(_map_input_to_string())
	if input_buffer.size() > BUFFER_MAX_SIZE:
		input_buffer.pop_front()

func get_moves(move_list:Array[Move]) -> Array[String]:
	if (input_buffer.size() < 2 or input_buffer[-1] != input_buffer[-2]) and input_buffer[-1] != "":
		print(input_buffer[-1])
	var detected_motions = _detect_motions(motion_list, input_buffer)
	return _detect_moves(move_list, detected_motions, input_buffer)

		
func _map_input_to_string() -> String:
	var input:String
	var direction:int = 0
	# one hot encode the direction buttons
	if Input.is_action_pressed(button_prefix+"up"):
		direction |= 8 # 0b1000
	if Input.is_action_pressed(button_prefix+"down"):
		direction |= 4 # 0b0100
	if Input.is_action_pressed(button_prefix+"left"):
		if facing_right:
			direction |= 2 # 0b0010
		else:
			direction |= 1 # 0b0001
	if Input.is_action_pressed(button_prefix+"right"):
		if facing_right:
			direction |= 1 # 0b0001
		else:
			direction |= 2 # 0b0010
	# map the buttons to a numpad direction and append
	input = str(DIRECTION_MAPPING_CAPCOM[direction])
	# map buttons to string representation and append
	for button in BUTTON_MAPPING.keys():
		if Input.is_action_pressed(button_prefix+button):
			input += BUTTON_MAPPING[button]
	
	return input

func _detect_motions(motion_list:Array[Motion], buffer:Array[String]) -> Array[String]:
	var detected_motions:Array[String] = []
	for motion in motion_list:
		if motion._is_motion(buffer):
			detected_motions.push_back(motion._name)
	return detected_motions

func _detect_moves(move_list:Array[Move], motions:Array[String], buffer:Array[String]) -> Array[String]:
	var detected_moves:Array[String] = []
	for move in move_list:
		if move._is_move(motions, buffer):
			detected_moves.push_back(move._name)
	return detected_moves
