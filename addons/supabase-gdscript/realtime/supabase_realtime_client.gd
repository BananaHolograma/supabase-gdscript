class_name GodotSupabaseRealtimeClient extends Node

class PhxEvents:
	const JOIN := "phx_join"
	const REPLY := "phx_reply"
	const LEAVE := "phx_leave"
	const ERROR := "phx_error"
	const CLOSE := "phx_close"


var channels: Array[GodotSupabaseRealtimeChannel] = []
var last_state := WebSocketPeer.STATE_CLOSED
var ws_client := WebSocketPeer.new()
var heartbeat_timer := Timer.new()
var is_connected: bool = false

func _init(timeout: float = 30.0):
	heartbeat_timer.wait_time = timeout
	heartbeat_timer.name = "GodotSupabasePhxHeartbeat"


func _exit_tree():
	disconnect_client(1000, "The GodotSupabaseRealtimeClient scene was removed from tree")


func _ready():
	add_child(heartbeat_timer)
	heartbeat_timer.timeout.connect(on_heartbeat_timer_timeout)


func connect_client() -> int:
	var result = ws_client.connect_to_url(
		GodotSupabase["CONFIGURATION"]["db"]["url"] + "?apikey=" + GodotSupabase["CONFIGURATION"]["anon_key"]
	)
	
	if result == OK:
		last_state = ws_client.get_ready_state()
		is_connected = true
	else:
		is_connected = false
		push_error("GodotSupabaseRealTimeClient: An error happened connecting the client with code: {error}".format({"error": result}) )

	return result
	
## Defined status codes websocket protocol https://datatracker.ietf.org/doc/rfc6455/
func disconnect_client(code : int = 1000, reason : String = "") -> void:
	ws_client.close(code, reason)
	last_state = ws_client.get_ready_state()
	is_connected = false


func channel(schema: String = "any") -> GodotSupabaseRealtimeChannel:
	if not is_connected:
		connect_client()
		
	var new_channel := GodotSupabaseRealtimeChannel.new(self, schema)
	channels.append(new_channel)
	
	return new_channel


func add_channel(channel: GodotSupabaseRealtimeChannel) -> void:
	channels.append(channel)
	
	
func remove_channel(channel: GodotSupabaseRealtimeChannel) -> void:
	channels.erase(channel)
	

func send_message(content : Dictionary = {}) -> int:
	var message := JSON.stringify(content)
	var result := ws_client.send(message.to_utf8_buffer())
	
	if result != OK:
		push_error("GodotSupabaseRealTimeClient: An error happened with code: {error} sending the message {message}".format({"message": message, "error": result}) )

	return result


func _send_heartbeat() -> void:
	send_message({
		topic = "phoenix",
		event = "heartbeat",
		payload = {},
		ref = null
	})


func on_heartbeat_timer_timeout() -> void:
	if last_state == ws_client.STATE_OPEN:
		_send_heartbeat()
