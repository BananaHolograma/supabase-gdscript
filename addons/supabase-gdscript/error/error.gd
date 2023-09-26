class_name GodotSupabaseError extends Node

var code: int
var msg: String = "" 
var hint: String = ""
var type: String = ""


func _init(params: Dictionary = {}):
	for param in params.keys().filter(func(key: String): return key in ["code", "msg", "hint", "type"]):
		self[param] = params[param]
	

func _to_string() -> String:
	return "GodotSupabaseError: An error happened with code {code} with message: {message} | {hint} | {type}"\
	.format({"code": str(code),  "message": msg, "hint": hint, "type": type})
	
