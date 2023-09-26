class_name GodotSupabaseAuth extends Node

signal signed_up(user: GodotSupabaseUser)
signal error


enum ACTION_TYPE {
	NONE,
	SIGNUP
}

var endpoint: String = "{url}/auth/{version}".format({"url":GodotSupabase.CONFIGURATION["url"] , "version": GodotSupabase.current_api_version})
var signup_endpoint: String = endpoint + "/signup"

var current_action: ACTION_TYPE = ACTION_TYPE.NONE
var user: GodotSupabaseUser


func _init():
	GodotSupabase.HTTP_REQUEST.request_completed.connect(on_request_completed)


func sign_up(email: String, password: String, metadata: Dictionary = {}):
	current_action = ACTION_TYPE.SIGNUP
	GodotSupabase.HTTP_REQUEST.request(
		signup_endpoint, 
		GodotSupabase.CONFIGURATION["global"]["headers"],
		HTTPClient.METHOD_POST,
		JSON.stringify({"email": email, "password": password, "data": metadata})
	)
	
	
func set_auth_user(data: Dictionary, overwrite: bool = false) -> void:
	if user == null or overwrite:
		user = GodotSupabaseUser.new()
		user.initialize(data)
		
		print(user)
		
	
func on_request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray) -> void:
	var content = JSON.parse_string(body.get_string_from_utf8())

	if result == HTTPRequest.RESULT_SUCCESS and content.has("code") and content["code"] in [200,201]:
		match(current_action):
			ACTION_TYPE.SIGNUP:
				set_auth_user(content)
				signed_up.emit(user)
	else:
		var error = GodotSupabaseError.new(content)
		push_error(error)
		
	current_action = ACTION_TYPE.NONE
