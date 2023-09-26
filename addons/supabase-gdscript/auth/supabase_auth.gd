class_name GodotSupabaseAuth extends Node

signal signed_up(user: GodotSupabaseUser)
signal signed_in(user: GodotSupabaseUser)
signal error


enum ACTION_TYPE {
	NONE,
	SIGNUP,
	SIGNIN
}

var ACTIONS = {
	ACTION_TYPE.NONE: "NONE",
	ACTION_TYPE.SIGNUP: "SIGNUP",
	ACTION_TYPE.SIGNIN: "SIGNIN"
}

var auth_endpoint: String = "{url}/auth/{version}".format({"url":GodotSupabase.CONFIGURATION["url"] , "version": GodotSupabase.current_api_version})

var ENDPOINTS: Dictionary = {
	ACTION_TYPE.SIGNUP: auth_endpoint + "/signup",
	ACTION_TYPE.SIGNIN: auth_endpoint + "/token?grant_type=password",
}


var current_action: ACTION_TYPE = ACTION_TYPE.NONE
var user: GodotSupabaseUser


func _init():
	GodotSupabase.HTTP_REQUEST.request_completed.connect(on_request_completed)


func sign_up(email: String, password: String, metadata: Dictionary = {}) -> void:
	current_action = ACTION_TYPE.SIGNUP
	
	GodotSupabase.HTTP_REQUEST.request(
		ENDPOINTS[current_action], 
		GodotSupabase.CONFIGURATION["global"]["headers"],
		HTTPClient.METHOD_POST,
		JSON.stringify({"email": email, "password": password, "data": metadata})
	)
	
	
func sign_in(email: String, password: String) -> void:
	current_action = ACTION_TYPE.SIGNIN
	
	GodotSupabase.HTTP_REQUEST.request(
		ENDPOINTS[current_action], 
		GodotSupabase.CONFIGURATION["global"]["headers"],
		HTTPClient.METHOD_POST,
		JSON.stringify({"email": email, "password": password})
	)
	
func _set_auth_user(data: Dictionary, overwrite: bool = false) -> void:
	if user == null or overwrite:
		user = GodotSupabaseUser.new()
		user.initialize(data)
		
	
func on_request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray) -> void:
	var content = JSON.parse_string(body.get_string_from_utf8())

	if result == HTTPRequest.RESULT_SUCCESS and response_code in [200, 201] and not content.has("code") :
		match(current_action):
			ACTION_TYPE.SIGNUP:
				_set_auth_user(content)
				signed_up.emit(user)
			ACTION_TYPE.SIGNIN:
				_set_auth_user(content["user"])
				signed_in.emit(user)
	else:
		var error = GodotSupabaseError.new(content, ACTIONS[current_action])
		push_error(error)
		
	current_action = ACTION_TYPE.NONE
