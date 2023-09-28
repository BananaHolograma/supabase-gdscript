class_name GodotSupabaseAuth extends Node

signal signed_up_with_email(user: GodotSupabaseUser)
signal signed_up_with_phone(user: GodotSupabaseUser)
signal signed_in_with_email(user: GodotSupabaseUser)
signal signed_in_with_phone(user: GodotSupabaseUser)
signal signed_out
signal error(error: GodotSupabaseError)


class ActionTypes: 
	const NONE = "NONE"
	const SIGNUP_EMAIL = "SIGNUP_EMAIL"
	const SIGNUP_PHONE = "SIGNUP_PHONE"
	const SIGNIN_EMAIL = "SIGNIN_EMAIL"
	const SIGNIN_PHONE = "SIGNIN_PHONE"
	const SIGNOUT = "SIGNOUT"
	const USER = "USER"


var auth_endpoint: String = "{url}/auth/{version}".format({"url":GodotSupabase.CONFIGURATION["url"] , "version": GodotSupabase.current_api_version})

var ENDPOINTS: Dictionary = {
	ActionTypes.SIGNUP_EMAIL: auth_endpoint + "/signup",
	ActionTypes.SIGNUP_PHONE: auth_endpoint + "/signup",
	ActionTypes.SIGNIN_EMAIL: auth_endpoint + "/token?grant_type=password",
	ActionTypes.SIGNIN_PHONE: auth_endpoint + "/token?grant_type=password",
	ActionTypes.SIGNOUT: auth_endpoint + "/logout",
	ActionTypes.USER: auth_endpoint + "/user"
}

var current_action = ActionTypes.NONE
var user: GodotSupabaseUser


func sign_up_with_email(email: String, password: String, metadata: Dictionary = {}) -> GodotSupabaseAuth:
	if not _user_is_authenticated():
		current_action = ActionTypes.SIGNUP_EMAIL
		
		GodotSupabase.http_request(on_request_completed).request(
			ENDPOINTS[current_action], 
			GodotSupabase.CONFIGURATION["global"]["headers"],
			HTTPClient.METHOD_POST,
			JSON.stringify({"email": email, "password": password, "data": metadata})
		)
	
	return self

func sign_up_with_phone(phone: String, password: String, metadata: Dictionary = {}) -> void:
	if not _user_is_authenticated():
		current_action = ActionTypes.SIGNUP_PHONE
		
		GodotSupabase.http_request(on_request_completed).request(
			ENDPOINTS[current_action], 
			GodotSupabase.CONFIGURATION["global"]["headers"],
			HTTPClient.METHOD_POST,
			JSON.stringify({"phone": phone, "password": password, "data": metadata})
		)
		
		
func sign_in_with_email(email: String, password: String) -> GodotSupabaseAuth:
	if not _user_is_authenticated():
		current_action = ActionTypes.SIGNIN_EMAIL
		
		GodotSupabase.http_request(on_request_completed).request(
			ENDPOINTS[current_action], 
			GodotSupabase.CONFIGURATION["global"]["headers"],
			HTTPClient.METHOD_POST,
			JSON.stringify({"email": email, "password": password})
		)

	return self

func sign_in_with_phone(phone: String, password: String) -> void:
	if not _user_is_authenticated():
		current_action = ActionTypes.SIGNIN_PHONE
		
		GodotSupabase.http_request(on_request_completed).request(
			ENDPOINTS[current_action], 
			GodotSupabase.CONFIGURATION["global"]["headers"],
			HTTPClient.METHOD_POST,
			JSON.stringify({"phone": phone, "password": password})
		)


func sign_out() -> void:
	if _user_is_authenticated():
		current_action = ActionTypes.SIGNOUT
		GodotSupabase.http_request(on_request_completed).request(
			ENDPOINTS[current_action], 
			GodotSupabase.CONFIGURATION["global"]["headers"],
			HTTPClient.METHOD_POST,
		)


func fetch_user() -> void:
	if _user_is_authenticated():
		current_action = ActionTypes.USER
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
			ActionTypes.USER:
				_set_auth_user(content)
			ActionTypes.SIGNUP_EMAIL:
				_set_auth_user(content)
				signed_up_with_email.emit(user)
			ActionTypes.SIGNUP_PHONE:
				_set_auth_user(content)
				signed_up_with_phone.emit(user)
			ActionTypes.SIGNIN_EMAIL:
				_set_auth_user(content)
				signed_in_with_email.emit(user)
			ActionTypes.SIGNIN_PHONE:
				_set_auth_user(content)
				signed_in_with_phone.emit(user)
			ActionTypes.SIGNOUT:
				user = null
				remove_jwt_token()
				signed_out.emit()
	else:
		var supabase_error = GodotSupabaseError.new(content, current_action)
		push_error(supabase_error)
		error.emit(supabase_error)
		
	current_action = ActionTypes.NONE
	http_handler.queue_free()
