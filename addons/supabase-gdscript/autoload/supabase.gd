class_name GodotSupabaseSDK extends Node

const API_V1 = "rest/v1"

var current_api_version = API_V1

var HTTP_REQUEST:  HTTPRequest

var CONFIGURATION: Dictionary = {
	"api_url": "",
	"url": "",
	"anon_key": "",
	"db": {
		"schema": "public"
	},
	"auth": {
	"refresh_token": true,
	"persist_session": true,
	"detect_session_in_url": true,
	"flow_type": "implicit"
	},
	"global": {
		"headers": {
			"X-Client-Info": "supabase-gdscript/{version}".format({"version": Helpers.get_plugin_version()}),
			"Content-Type": "application/json",
			"Accept": "application/json",
		}
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
	
	add_http_node()



func create_client(url, anon_key, config: Dictionary = {}):
	if url == null:
		push_error("GodotSupabase: The supabase project url is not defined, make sure you have the .env file with the correct values")
		return
		
	if anon_key == null:
		push_error("GodotSupabase: The supabase key is not defined, make sure you have the .env file with the correct values")
		return
		
	CONFIGURATION.merge(config, true)
	
	CONFIGURATION["api_url"] = "{project}/{api_version}".format({"project": url, "api_version": current_api_version})
	CONFIGURATION["url"] = url
	CONFIGURATION["key"] = anon_key

func add_http_node():
	var http_request = HTTPRequest.new()
	http_request.name = "GodotSupabaseHttpRequest"
	add_child(http_request)
	HTTP_REQUEST = get_child(0)
	
	print(HTTP_REQUEST)

