class_name GodotEnvironmentHelper extends Node


@export var ENVIRONMENT_FILES_PATH: String = "res://"


## Retrieve the value of an environment variable by its key.
func get_var(key: String) -> String:
	return OS.get_environment(key)
	
## Retrieve the value of an environment variable by its key or null it if it doesn't.
func get_var_or_null(key: String):
	var value: String = get_var(key)
	
	return null if value.is_empty() else value

## Set an environment variable with a key and an optional value.
## If the variable already exists, it will be replaced.
func set_var(key: String, value: String = "") -> void:
	OS.set_environment(key, value)

## Remove an environment variable by its key.
func remove_var(key: String)-> void:
	OS.unset_environment(key)


## Load environment variables from an environment file with the specified filename.
func load_env_file(filename: String = ".env") -> void:
	_read_file_with_callback(filename, _set_environment_from_line)


## Check if an environment file with the specified filename exists.
func _env_file_exists(filename: String) -> bool:
	return FileAccess.file_exists(_env_path(filename))

## Get the full path to an environment file.
func _env_path(filename: String) -> String:
	return "{filepath}/{file}".format({"filepath": ENVIRONMENT_FILES_PATH, "file": filename})

## Callback to remove environment variables from a line in the environment file.
func _remove_environment_from_line(line: PackedStringArray) -> void:
	if line.size() > 1:
		var key: String = line[0].strip_edges()	
		remove_var(key)
	
## Callback to set environment variables from a line in the environment file.
func _set_environment_from_line(line: PackedStringArray) -> void:
	if line.size() > 1:
		var key: String = line[0].strip_edges()
		var value: String = line[1].strip_edges()
		set_var(key, value)

## Read an environment file with a callback function.
func _read_file_with_callback(filename: String = ".env", callback: Callable = func(line): pass):
	if _env_file_exists(filename):
		var env_file = FileAccess.open(_env_path(filename), FileAccess.READ)
		var error = FileAccess.get_open_error()
		if error:
			push_error("Godotenv plugin: {error}".format({"error": error}))
			return
			
		while env_file.get_position() < env_file.get_length():
			var line = env_file.get_line().split("=")		
			callback.call(line)
	
		env_file.close()
		
func _default_path_from_settings() -> String:
	var settings_path: String = "{project_name}/config/godotenv".format({"project_name": ProjectSettings.get_setting("application/config/name")})
	return ProjectSettings.get_setting(settings_path + "/root_directory")
