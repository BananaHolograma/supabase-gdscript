class_name GodotSupabaseRealtime extends Node

var realtime_client: GodotSupabaseRealtimeClient

func _init(timeout: float = 30.0):
	self.name = "GodotSupabaseRealtime"
	realtime_client = GodotSupabaseRealtimeClient.new(timeout)
	realtime_client.name = "GodotSupabaseRealtimeClient"
	add_child(realtime_client)	

