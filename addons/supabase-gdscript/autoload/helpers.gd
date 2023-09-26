class_name GlobalHelpers extends Node


func get_plugin_version() -> Variant:
	var config: ConfigFile = ConfigFile.new()
	config.load("res://addons/supabase-gdscript/plugin.cfg")

	return config.get_value("plugin", "version")
