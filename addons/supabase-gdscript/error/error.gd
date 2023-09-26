class_name GodotSupabaseError extends Node

var code: int
var msg: String = "" 
var hint: String = ""
var type: String = ""
var action_type: String = "NONE"


func _init(params: Dictionary = {}, action: String = "NONE"):
	for param in params.keys().filter(func(key: String): return key in ["code", "msg", "hint", "type"]):
		self[param] = params[param]
	action_type = action


func _to_string() -> String:
	return "GodotSupabaseError: An error happened on action {action} with code {code} containing message: {message} | {hint} | {type}"\
	.format({"action": action_type, "code": str(code),  "message": msg, "hint": hint, "type": type})
	
