class_name GodotSupabaseRealtime extends Node

var client: GodotSupabaseRealtimeClient

func _init(timeout: float = 30.0):
	self.name = "GodotSupabaseRealtime"
	
	client = GodotSupabaseRealtimeClient.new(timeout)
	client.name = "GodotSupabaseRealtimeClient"
	add_child(client)	

