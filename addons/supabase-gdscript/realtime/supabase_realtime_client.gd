class_name GodotSupabaseRealtimeClient extends Node


var channels := []
var last_state := WebSocketPeer.STATE_CLOSED
var ws_client := WebSocketPeer.new()
var heartbeat_timer := Timer.new()



func _init(timeout: float = 30.0):
	heartbeat_timer.wait_time = timeout
	heartbeat_timer.name = "GodotSupabasePhxHeartbeat"

func _ready():
	add_child(heartbeat_timer)
	heartbeat_timer.timeout.connect(on_heartbeat_timer_timeout)


func send_message(content : Dictionary) -> int:
	return ws_client.send(JSON.stringify(content).to_utf8_buffer())


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
