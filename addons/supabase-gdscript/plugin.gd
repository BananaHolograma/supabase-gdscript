@tool
extends EditorPlugin

const PLUGIN_PREFIX = "GodotSupabase"


func _enter_tree():
	add_autoload_singleton(PLUGIN_PREFIX, "res://addons/supabase-gdscript/autoload/supabase.gd")


func _exit_tree():
	remove_autoload_singleton(PLUGIN_PREFIX)
