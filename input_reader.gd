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
	"light_punch": "a",
	"medium_punch": "b",
	"heavy_punch": "c",
	"light_kick": "d",
	"medium_kick": "e",
	"heavy_kick": "f"
}

class Motion:
	var _max_frames:int
	var _regex:RegEx
	func _init(max_frames:int, regex_string:String):
		_max_frames = max_frames
		_regex = RegEx.new()
		_regex.compile(InputReader._convert_custom_regex(regex_string))

var motion_list:Dictionary = {
	"DF":  Motion.new(30, "5 6+10 5+10 6"),
	"DB":  Motion.new(30, "5 4+10 5+10 4"),
	"QCF": Motion.new(30, "2 3+10 6+10 5*10"),
	"QCB": Motion.new(30, "2 1+10 4+10 5*10"),
	"DP":  Motion.new(30, "(6 5*5 2+10 3+10 [56]*10 |
							6 3+10 6 [56]*9 )"),
	"HCF": Motion.new(30, "4 1+10 2*10 3+10 6+10 5*10"),
	"HCB": Motion.new(30, "6 3+10 2*10 1+10 4+10 5*10"),
	"BCH": Motion.new(60, "[14]+30 [235sd]*10 6+10 5+10"),
	"SF":  Motion.new(30, "(2+10 3+10 6+10 5*10)=2"),
	"SB":  Motion.new(30, "(2+10 1+10 4+10 5*10)=2"),
}

class Move:
	var _motions:PackedStringArray
	var _button_regex:RegEx
	func _init(motions:PackedStringArray, button_regex:String):
		_motions = motions
		_button_regex = RegEx.new()
		_button_regex.compile(InputReader._convert_custom_regex(button_regex))

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

func get_moves(move_list:Dictionary) -> Array[String]:		
	if (input_buffer.size() < 2 or input_buffer[-1] != input_buffer[-2]) and input_buffer[-1] != "":
		print(input_buffer[-1])
	
	var detected_motions = _detect_motions(motion_list, input_buffer)
#	if motions.size() > 0:
#		print(motions)
		
	return _detect_moves(move_list, input_buffer, detected_motions)

static func _convert_custom_regex(input:String) -> String:
	var start:String
	var end:String
	start = ""
	end = input
	#keep applying replacement rules until nothing changes
	while start != end:
		start = end
		# loop only executed on intialization so we don't really care about recreating regex
		end = RegEx.create_from_string("([0-9m][abcdefpkx]{0,6})=(\\d+)").sub(end,"($1){$2}",true)
		end = RegEx.create_from_string("(\\)|\\])=(\\d+)").sub(end,"$1{$2}",true)
		end = RegEx.create_from_string("([0-9m][abcdefpkx]{0,6})\\+(\\d+)").sub(end,"($1){1,$2}",true)
		end = RegEx.create_from_string("(\\)|\\])\\+(\\d+)").sub(end,"$1{1,$2}",true)
		end = RegEx.create_from_string("([0-9m][abcdefpkx]{0,6})\\*(\\d+)").sub(end,"($1){0,$2}",true)
		end = RegEx.create_from_string("(\\)|\\])\\*(\\d+)").sub(end,"$1{0,$2}",true)
		end = RegEx.create_from_string("m").sub(end,"\\d",true)
		end = RegEx.create_from_string("p").sub(end,"[abc]",true)
		end = RegEx.create_from_string("k").sub(end,"[def]",true)
		end = RegEx.create_from_string("x").sub(end,"[abcdef]",true)
	end = RegEx.create_from_string("\\s").sub(end,"",true)
	end+="$"
	return end

		
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

func _detect_motions(motion_list:Dictionary, buffer:Array[String]) -> Array[String]:
	var detected_motions:Array[String] = []
	for motion_name in motion_list.keys():
		var motion:Motion = motion_list[motion_name]
		var joined_buffer = "".join(buffer.slice(-motion._max_frames).map(func(x): return RegEx.create_from_string("[abcdef]").sub(x,"",true)))
		if motion._regex.search(joined_buffer):
			detected_motions.push_back(motion_name)
	return detected_motions

func _detect_moves(move_list:Dictionary, buffer:Array[String], motions:Array[String]) -> Array[String]:
	var detected_moves:Array[String] = []
	for move_name in move_list.keys():
		var move:Move = move_list[move_name]
		var joined_buffer = "".join(buffer.slice(-10))
		var motion_found:bool = false
		if move._motions.size() == 0:
			motion_found = true
		else:
			for motion in motions:
				if motion in move._motions:
					motion_found = true
		if motion_found==true and move._button_regex.search(joined_buffer):
			detected_moves.push_back(move_name)
	return detected_moves
