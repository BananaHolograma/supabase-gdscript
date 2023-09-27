class_name GodotSupabaseError extends Node

var code: int
var msg: String = "" 
var message: String = ""
var hint: String = ""
var type: String = ""
var detail: String = ""
var action_type: String = "NONE"


func _init(params: Dictionary = {}, action: String = "NONE"):
	print(params)
	for param in params.keys().filter(func(key: String): return params[key] != null and key in ["code", "msg", "message", "hint", "type"]):
		self[param] = params[param]
	action_type = action


func _to_string() -> String:
	return "GodotSupabaseError: An error happened on action {action} with code {code} containing message: {message} | {detail} | {hint} | {type}"\
	.format({"action": action_type, "code": str(code), "message": msg + message, "detail": detail, "hint": hint, "type": type})
	
