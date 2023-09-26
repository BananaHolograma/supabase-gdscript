class_name GodotSupabaseSDK extends Node

const API_V1 = "rest/v1"

var CONFIGURATION: Dictionary = {
	"url": "",
	"key": "",
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



func create_client(url, anon_key, config: Dictionary = {}):
	if url == null:
		push_error("GodotSupabase: The supabase project url is not defined, make sure you have the .env file with the correct values")
		return
		
	if anon_key == null:
		push_error("GodotSupabase: The supabase key is not defined, make sure you have the .env file with the correct values")
		return
		
	CONFIGURATION.merge(config, true)
	
	CONFIGURATION["url"] = url
	CONFIGURATION["key"] = anon_key


