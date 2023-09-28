class_name GodotSupabaseRealtimeClient extends Node

signal connected
signal disconnected(code: int, reason: String)
signal message_received(message)

class PhxEvents:
	const JOIN := "phx_join"
	const REPLY := "phx_reply"
	const LEAVE := "phx_leave"
	const ERROR := "phx_error"
	const CLOSE := "phx_close"


class RealtimePostgressChangesListenEvent:
	const ALL = "*"
	const INSERT = "INSERT"
	const UPDATE = "UPDATE"
	const DELETE = "DELETE"
	
	static func allowed_values() -> Array[String]:
		return [ALL, INSERT, UPDATE, DELETE]
		
		
var channels: Array[GodotSupabaseRealtimeChannel] = []
var last_state := WebSocketPeer.STATE_CLOSED
var socket := WebSocketPeer.new()
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
	
	message_received.connect(on_message_received)
	set_process(false)


func _process(_delta : float) -> void:
	socket.poll()
	var state := socket.get_ready_state()
	
	if last_state != state:
		last_state = state
		
	match(state): 
		socket.STATE_OPEN, socket.STATE_CLOSING:
			heartbeat_timer.start()
			while socket.get_available_packet_count():
				message_received.emit(JSON.parse_string(_get_socket_message()))
		socket.STATE_CLOSED:
			disconnect_client(socket.get_close_code(), socket.get_close_reason())
		


func connect_client() -> int:
	var result = socket.connect_to_url(
		GodotSupabase["CONFIGURATION"]["db"]["url"] + "?apikey=" + GodotSupabase["CONFIGURATION"]["anon_key"]
	)
	
	if result == OK:
		last_state = socket.get_ready_state()
		is_connected = true
		connected.emit()
		set_process(true)
	else:
		is_connected = false
		push_error("GodotSupabaseRealTimeClient: An error happened connecting the client with code: {error}".format({"error": result}) )
		set_process(false)
		
	return result
	
## Defined status codes websocket protocol https://datatracker.ietf.org/doc/rfc6455/
func disconnect_client(code : int = 1000, reason : String = "") -> void:
	socket.close(code, reason)
	last_state = socket.get_ready_state()
	is_connected = false
	set_process(false)
	disconnected.emit(code, reason)


func channel(schema: String = "any") -> GodotSupabaseRealtimeChannel:
	if not is_connected:
		connect_client()
		
	return GodotSupabaseRealtimeChannel.new(self, schema)


func add_channel(channel: GodotSupabaseRealtimeChannel) -> void:
	if channels.find(channel) == -1:
		channels.append(channel)
	
	
func remove_channel(channel: GodotSupabaseRealtimeChannel) -> void:
	channels.erase(channel)
	

func send_message(content : Dictionary = {}) -> int:
	var message := JSON.stringify(content)
	var result := socket.send(message.to_utf8_buffer())
	
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
	
func _get_socket_message() -> Variant:
	if socket.get_available_packet_count() < 1:
		return null
		
	var socket_packet := socket.get_packet()
	
	if socket.was_string_packet():
		return socket_packet.get_string_from_utf8()
		
	return bytes_to_var(socket_packet)


func on_heartbeat_timer_timeout() -> void:
	if last_state == socket.STATE_OPEN:
		_send_heartbeat()


func on_message_received(message: Dictionary) -> void:
	print(message)
	match(message.event):
		PhxEvents.JOIN:
			print("event joined")
		PhxEvents.LEAVE:
			print("event leave")
		PhxEvents.REPLY:
			print("event reply")
		PhxEvents.CLOSE:
			print("event close")
		PhxEvents.ERROR:
			print("event error")
		RealtimePostgressChangesListenEvent.ALL,\
		RealtimePostgressChangesListenEvent.INSERT,\
		RealtimePostgressChangesListenEvent.UPDATE,\
		RealtimePostgressChangesListenEvent.DELETE:
			print("Postgres changes event received ")
