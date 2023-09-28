class_name GodotSupabaseSDK extends Node

const API_VERSIONS = {
	"V1": "v1"
}

var current_api_version = API_VERSIONS["V1"]

## MODULES ##
var auth: GodotSupabaseAuth
var database: GodotSupabaseDatabase
var realtime: GodotSupabaseRealtime

var CONFIGURATION: Dictionary = {
	"url": "",
	"anon_key": "",
	"db": {
		"url": "",
		"schema": "public"
	},
	"auth": {
		"refresh_token": true,
		"persist_session": true,
		"detect_session_in_url": true,
		"flow_type": "implicit"
	},
	"global": {
		"headers": PackedStringArray([
			"X-Client-Info: supabase-gdscript/{version}".format({"version": Helpers.get_plugin_version()}),
			"Content-Type: application/json",
			"Accept: application/json",
		])
	},
	"realtime": {
		"transport": "websocket",
		"timeout": 10000,
		"ws_close_normal": 1000
	}
}


func _ready():
	GodotEnvironment.load_env_file(".env")
	
	create_client(
	 GodotEnvironment.get_var_or_null("supabaseUrl"),
	 GodotEnvironment.get_var_or_null("supabaseKey"),
	 CONFIGURATION
	)
	
	GodotEnvironment.remove_var("supabaseUrl")
	GodotEnvironment.remove_var("supabaseKey")
	
	auth = GodotSupabaseAuth.new()
	database = GodotSupabaseDatabase.new()
	realtime = GodotSupabaseRealtime.new(CONFIGURATION["db"]["url"] + "?apikey=" + CONFIGURATION["anon_key"])
	add_child(realtime)
	

func create_client(url, anon_key, config: Dictionary = {}):
	if url == null:
		push_error("GodotSupabase: The supabase project url is not defined, make sure you have the .env file with the correct values")
		return
		
	if anon_key == null:
		push_error("GodotSupabase: The supabase key is not defined, make sure you have the .env file with the correct values")
		return
	
	
	CONFIGURATION["url"] = url
	CONFIGURATION["anon_key"] = anon_key
	CONFIGURATION["global"]["headers"].append("apikey: {key}".format({"key": anon_key}))
	CONFIGURATION["global"]["headers"].append("Authorization: Bearer ")
	CONFIGURATION["db"]["url"] = url.replace("http","ws")+ "/realtime/{version}/websocket".format({"version": current_api_version})
	
	CONFIGURATION.merge(config, true)


func http_request(on_request_completed: Callable) -> HTTPRequest:
	var http_request = HTTPRequest.new()
	
	http_request.use_threads = true
	add_child(http_request)
	http_request.request_completed.connect(on_request_completed.bind(http_request))
	
	return http_request
	

