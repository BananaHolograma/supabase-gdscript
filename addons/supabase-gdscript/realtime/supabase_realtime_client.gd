class_name GodotSupabaseRealtimeClient extends Node


var channels := []
var last_state := WebSocketPeer.STATE_CLOSED
var ws_client := WebSocketPeer.new()
var heartbeat_timer := Timer.new()


func _init(timeout: float = 30.0):
	heartbeat_timer.wait_time = timeout
	heartbeat_timer.name = "GodotSupabasePhxHeartbeat"

func _exit_tree():
	disconnect_client(1000, "The GodotSupabaseRealtimeClient scene was removed from tree")

func _ready():
	add_child(heartbeat_timer)
	heartbeat_timer.timeout.connect(on_heartbeat_timer_timeout)
	connect_client()

func connect_client() -> int:
	var result = ws_client.connect_to_url(
		GodotSupabase["CONFIGURATION"]["db"]["url"] + "?apikey=" + GodotSupabase["CONFIGURATION"]["anon_key"]
	)
	
	if result == OK:
		last_state = ws_client.get_ready_state()
	else:
		push_error("GodotSupabaseRealTimeClient: An error happened connecting the client with code: {error}".format({"error": result}) )

	return result
	
	
func disconnect_client(code : int = 1000, reason : String = "") -> void:
	ws_client.close(code, reason)
	last_state = ws_client.get_ready_state()


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
