class_name GlobalHelpers extends Node


func get_plugin_version() -> Variant:
	var config: ConfigFile = ConfigFile.new()
	config.load("res://addons/supabase-gdscript/plugin.cfg")

	return config.get_value("plugin", "version")

func load_env_file(filename: String = ".env") -> void:
	_read_file_with_callback(filename, _set_environment_from_line)


func _set_environment_from_line(line: PackedStringArray) -> void:
	if line.size() > 1:
		var key: String = line[0].strip_edges()
		var value: String = line[1].strip_edges()
		set_var(key, value)


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
		
