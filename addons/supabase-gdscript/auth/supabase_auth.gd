class_name GodotSupabaseAuth extends Node

signal signed_up_with_email(user: GodotSupabaseUser)
signal signed_up_with_phone(user: GodotSupabaseUser)
signal signed_in_with_email(user: GodotSupabaseUser)
signal signed_in_with_phone(user: GodotSupabaseUser)
signal signed_out
signal error(error: GodotSupabaseError)


enum ACTION_TYPE {
	NONE,
	SIGNUP_EMAIL,
	SIGNUP_PHONE,
	SIGNIN_EMAIL,
	SIGNIN_PHONE,
	SIGNOUT,
	USER
}

var ACTIONS = {
	ACTION_TYPE.NONE: "NONE",
	ACTION_TYPE.SIGNUP_EMAIL: "SIGNUP_EMAIL",
	ACTION_TYPE.SIGNUP_PHONE: "SIGNUP_PHONE",
	ACTION_TYPE.SIGNIN_EMAIL: "SIGNIN_EMAIL",
	ACTION_TYPE.SIGNIN_PHONE: "SIGNIN_PHONE",
	ACTION_TYPE.SIGNOUT: "SIGNOUT",
	ACTION_TYPE.USER: "USER"
}

var auth_endpoint: String = "{url}/auth/{version}".format({"url":GodotSupabase.CONFIGURATION["url"] , "version": GodotSupabase.current_api_version})

var ENDPOINTS: Dictionary = {
	ACTION_TYPE.SIGNUP_EMAIL: auth_endpoint + "/signup",
	ACTION_TYPE.SIGNUP_PHONE: auth_endpoint + "/signup",
	ACTION_TYPE.SIGNIN_EMAIL: auth_endpoint + "/token?grant_type=password",
	ACTION_TYPE.SIGNIN_PHONE: auth_endpoint + "/token?grant_type=password",
	ACTION_TYPE.SIGNOUT: auth_endpoint + "/logout",
	ACTION_TYPE.USER: auth_endpoint + "/user"
}

var current_action: ACTION_TYPE = ACTION_TYPE.NONE
var user: GodotSupabaseUser


func sign_up_with_email(email: String, password: String, metadata: Dictionary = {}) -> GodotSupabaseAuth:
	if not _user_is_authenticated():
		current_action = ACTION_TYPE.SIGNUP_EMAIL
		
		GodotSupabase.http_request(on_request_completed).request(
			ENDPOINTS[current_action], 
			GodotSupabase.CONFIGURATION["global"]["headers"],
			HTTPClient.METHOD_POST,
			JSON.stringify({"email": email, "password": password, "data": metadata})
		)
	
	return self

func sign_up_with_phone(phone: String, password: String, metadata: Dictionary = {}) -> void:
	if not _user_is_authenticated():
		current_action = ACTION_TYPE.SIGNUP_PHONE
		
		GodotSupabase.http_request(on_request_completed).request(
			ENDPOINTS[current_action], 
			GodotSupabase.CONFIGURATION["global"]["headers"],
			HTTPClient.METHOD_POST,
			JSON.stringify({"phone": phone, "password": password, "data": metadata})
		)
		
		
func sign_in_with_email(email: String, password: String) -> GodotSupabaseAuth:
	if not _user_is_authenticated():
		current_action = ACTION_TYPE.SIGNIN_EMAIL
		
		GodotSupabase.http_request(on_request_completed).request(
			ENDPOINTS[current_action], 
			GodotSupabase.CONFIGURATION["global"]["headers"],
			HTTPClient.METHOD_POST,
			JSON.stringify({"email": email, "password": password})
		)

	return self

func sign_in_with_phone(phone: String, password: String) -> void:
	if not _user_is_authenticated():
		current_action = ACTION_TYPE.SIGNIN_PHONE
		
		GodotSupabase.http_request(on_request_completed).request(
			ENDPOINTS[current_action], 
			GodotSupabase.CONFIGURATION["global"]["headers"],
			HTTPClient.METHOD_POST,
			JSON.stringify({"phone": phone, "password": password})
		)


func sign_out() -> void:
	if _user_is_authenticated():
		current_action = ACTION_TYPE.SIGNOUT
		GodotSupabase.http_request(on_request_completed).request(
			ENDPOINTS[current_action], 
			GodotSupabase.CONFIGURATION["global"]["headers"],
			HTTPClient.METHOD_POST,
		)


func fetch_user() -> void:
	if _user_is_authenticated():
		current_action = ACTION_TYPE.USER
		GodotSupabase.http_request(on_request_completed).request(
			ENDPOINTS[current_action], 
			GodotSupabase.CONFIGURATION["global"]["headers"],
			HTTPClient.METHOD_GET,
		)

	
func add_jwt_token(token: String) -> void:
	if _user_is_authenticated() and token:
		var headers = Array(GodotSupabase.CONFIGURATION["global"]["headers"])
		GodotSupabase.CONFIGURATION["global"]["headers"] = PackedStringArray(headers.map(
			func(header: String): 
				if header.begins_with("Authorization"):
					return "Authorization: Bearer " + user.access_token
				else:
					return header
		))
	
	
func remove_jwt_token() -> void:
	var headers = Array(GodotSupabase.CONFIGURATION["global"]["headers"])
	GodotSupabase.CONFIGURATION["global"]["headers"] = PackedStringArray(headers.map(
		func(header: String): 
			if header.begins_with("Authorization"):
					return "Authorization: Bearer "
			else:
				return header	
	))

func _set_auth_user(data: Dictionary, overwrite: bool = false) -> void:
	if user == null or overwrite:
		user = GodotSupabaseUser.new()
		user.initialize(data)
		add_jwt_token(user.access_token)
		
		
func _user_is_authenticated() -> bool:
	return user != null and user is GodotSupabaseUser


func on_request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray, http_handler: HTTPRequest) -> void:
	var data: String = body.get_string_from_utf8()
	var content = {} if data.is_empty() else JSON.parse_string(data)

	if result == HTTPRequest.RESULT_SUCCESS and response_code in [200, 201, 204]:
		match(current_action):
			ACTION_TYPE.USER:
				_set_auth_user(content)
			ACTION_TYPE.SIGNUP_EMAIL:
				_set_auth_user(content)
				signed_up_with_email.emit(user)
			ACTION_TYPE.SIGNUP_PHONE:
				_set_auth_user(content)
				signed_up_with_phone.emit(user)
			ACTION_TYPE.SIGNIN_EMAIL:
				_set_auth_user(content)
				signed_in_with_email.emit(user)
			ACTION_TYPE.SIGNIN_PHONE:
				_set_auth_user(content)
				signed_in_with_phone.emit(user)
			ACTION_TYPE.SIGNOUT:
				user = null
				remove_jwt_token()
				signed_out.emit()
	else:
		var supabase_error = GodotSupabaseError.new(content, ACTIONS[current_action])
		error.emit(supabase_error)
		push_error(supabase_error)
		
	current_action = ACTION_TYPE.NONE
	http_handler.queue_free()
