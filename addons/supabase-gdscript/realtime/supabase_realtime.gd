class_name GodotSupabaseRealtime extends Node

var client: GodotSupabaseRealtimeClient

func _init(url: String):
	self.name = "GodotSupabaseRealtime"
	
	client = GodotSupabaseRealtimeClient.new(url)
	client.name = "GodotSupabaseRealtimeClient"
	add_child(client)	

