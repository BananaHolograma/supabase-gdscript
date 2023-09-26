class_name GodotSupabaseAuth extends Node

signal signed_up(user: GodotSupabaseUser)
signal signed_in_with_password(user: GodotSupabaseUser)
signal signed_in_with_phone(user: GodotSupabaseUser)
signal signed_out
signal error(error: GodotSupabaseError)


enum ACTION_TYPE {
	NONE,
	SIGNUP,
	SIGNIN_PASSWORD,
	SIGNIN_PHONE,
	SIGNOUT
}

var ACTIONS = {
	ACTION_TYPE.NONE: "NONE",
	ACTION_TYPE.SIGNUP: "SIGNUP",
	ACTION_TYPE.SIGNIN_PASSWORD: "SIGNIN_PASSWORD",
	ACTION_TYPE.SIGNIN_PHONE: "SIGNIN_PHONE",
	ACTION_TYPE.SIGNOUT: "SIGNOUT"
}

var auth_endpoint: String = "{url}/auth/{version}".format({"url":GodotSupabase.CONFIGURATION["url"] , "version": GodotSupabase.current_api_version})

var ENDPOINTS: Dictionary = {
	ACTION_TYPE.SIGNUP: auth_endpoint + "/signup",
	ACTION_TYPE.SIGNIN_PASSWORD: auth_endpoint + "/token?grant_type=password",
}


var current_action: ACTION_TYPE = ACTION_TYPE.NONE
var user: GodotSupabaseUser


func _init():
	GodotSupabase.HTTP_REQUEST.request_completed.connect(on_request_completed)


func sign_up(email: String, password: String, metadata: Dictionary = {}) -> void:
	if not _user_is_authenticated():
		current_action = ACTION_TYPE.SIGNUP
		
		GodotSupabase.HTTP_REQUEST.request(
			ENDPOINTS[current_action], 
			GodotSupabase.CONFIGURATION["global"]["headers"],
			HTTPClient.METHOD_POST,
			JSON.stringify({"email": email, "password": password, "data": metadata})
		)
		
		
func sign_in_with_password(email: String, password: String) -> void:
	if not _user_is_authenticated():
		current_action = ACTION_TYPE.SIGNIN_PASSWORD
		
		GodotSupabase.HTTP_REQUEST.request(
			ENDPOINTS[current_action], 
			GodotSupabase.CONFIGURATION["global"]["headers"],
			HTTPClient.METHOD_POST,
			JSON.stringify({"email": email, "password": password})
		)


func sign_in_with_phone(phone: String, password: String) -> void:
	if not _user_is_authenticated():
		current_action = ACTION_TYPE.SIGNIN_PHONE
		
		GodotSupabase.HTTP_REQUEST.request(
			ENDPOINTS[current_action], 
			GodotSupabase.CONFIGURATION["global"]["headers"],
			HTTPClient.METHOD_POST,
			JSON.stringify({"phone": phone, "password": password})
		)

func sign_out() -> void:
	if _user_is_authenticated():
		current_action = ACTION_TYPE.SIGNOUT
		
		GodotSupabase.HTTP_REQUEST.request(
			ENDPOINTS[current_action], 
			GodotSupabase.CONFIGURATION["global"]["headers"],
			HTTPClient.METHOD_POST
		)


func _set_auth_user(data: Dictionary, overwrite: bool = false) -> void:
	if user == null or overwrite:
		user = GodotSupabaseUser.new()
		user.initialize(data)
		print(data)


func _user_is_authenticated() -> bool:
	return user != null and user is GodotSupabaseUser
	
	
func on_request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray) -> void:
	var content = JSON.parse_string(body.get_string_from_utf8())

	if result == HTTPRequest.RESULT_SUCCESS and response_code in [200, 201] and not content.has("code") :
		match(current_action):
			ACTION_TYPE.SIGNUP:
				_set_auth_user(content)
				signed_up.emit(user)
			ACTION_TYPE.SIGNIN_PASSWORD:
				_set_auth_user(content["user"])
				signed_in_with_password.emit(user)
			ACTION_TYPE.SIGNIN_PHONE:
				_set_auth_user(content["user"])
				signed_in_with_phone.emit(user)
	else:
		print("content ", content)
		var supabase_error = GodotSupabaseError.new(content, ACTIONS[current_action])
		error.emit(supabase_error)
		push_error(supabase_error)
		
	current_action = ACTION_TYPE.NONE
