class_name GodotSupabaseRealtimeClient extends Node

signal connected(GodotSupabaseRealtimeClient)
signal disconnected(code: int, reason: String)
signal message_received(message)

class ChannelEvents:
	const JOIN := "phx_join"
	const REPLY := "phx_reply"
	const LEAVE := "phx_leave"
	const ERROR := "phx_error"
	const CLOSE := "phx_close"
	const SYSTEM := "system"
	const ACCESS_TOKEN := "access_token"

class RealtimePostgressChangesListenEvent:
	const ALL = "*"
	const INSERT = "INSERT"
	const UPDATE = "UPDATE"
	const DELETE = "DELETE"
	
	static func allowed_values() -> Array[String]:
		return [ALL, INSERT, UPDATE, DELETE]
	
	static func signal_name(event: String) -> String:
		if event in allowed_values():
			match(event):
				INSERT:
					return "inserted"
				UPDATE:
					return "updated"
				DELETE:
					return "updated"
					
		return ""
		
var realtime_url: String

var channels: Array[GodotSupabaseRealtimeChannel] = []
var last_state := WebSocketPeer.STATE_CLOSED
var socket := WebSocketPeer.new()
var heartbeat_timer := Timer.new()

var is_connected: bool = false

func _init(url: String, params: Dictionary = {"timeout":  30.0, "events_per_second": 10}):
	realtime_url = url
	heartbeat_timer.wait_time = params["timeout"] if params.has("timeout") else 30.0
	heartbeat_timer.name = "GodotSupabasePhxHeartbeat"


func _exit_tree():
	disconnect_client(1000, "The GodotSupabaseRealtimeClient scene was removed from tree")


func _ready():
	add_child(heartbeat_timer)
	heartbeat_timer.timeout.connect(on_heartbeat_timer_timeout)
	
	message_received.connect(on_message_received)
	connected.connect(on_connected)
	set_process(false)


func _process(_delta : float) -> void:
	socket.poll()
	var state := socket.get_ready_state()
	
	if state == socket.STATE_OPEN and not is_connected:
		connected.emit(self)
		
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
	var result = socket.connect_to_url(realtime_url)
	
	if result == OK:
		last_state = socket.get_ready_state()
		set_process(true)
	else:
		is_connected = false
		push_error("GodotSupabaseRealTimeClient: An error happened connecting the client with code: {error}".format({"error": result}) )
		set_process(false)
		
	return result
	
## Defined status codes websocket protocol https://datatracker.ietf.org/doc/rfc6455/
func disconnect_client(code : int = 1000, reason : String = "") -> void:
	heartbeat_timer.stop()
	socket.close(code, reason)
	last_state = socket.get_ready_state()
	is_connected = false
	set_process(false)
	disconnected.emit(code, reason)

## Setting ack to true means that the channel.send promise will resolve once server replies with acknowledgement that it received the broadcast message request.
## Setting self to true means that the client will receive the broadcast message it sent out
func channel(name: String = "any", params: Dictionary = {"broadcast": { "ack": false, "self": false }}) -> GodotSupabaseRealtimeChannel:
	if not is_connected:
		push_error("GodotSupabaseRealTimeClient: The socket is not connected yet, use connect_client() first before subscribe to events")
	
	var channel = get_channel_by_name(name)
	
	if channel:
		return channel
	
	return GodotSupabaseRealtimeChannel.new(self, name)


func add_channel(channel: GodotSupabaseRealtimeChannel) -> void:
	if channels.find(channel) == -1:
		channels.append(channel)
	
	
func remove_channel(channel: GodotSupabaseRealtimeChannel) -> void:
	channel.unsubscribe()
	channels.erase(channel)


func flush_channels() -> void:
	for channel in channels:
		channel.unsubscribe()
	
	channels.clear()

func get_channel_by_topic(topic: String):
	var channel_found = null
	
	for channel in channels:
		if channel._build_topic() == topic:
			channel_found = channel
			break
			
	return channel_found
	
func get_channel_by_name(name: String):
	var channel_found = null
	
	for channel in channels:
		if channel.internal_name == name:
			channel_found = channel
			break
			
	return channel_found
	
	
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

## Example realtime payload
## {
## "event": "phx_reply", 
## "payload": { "response": { "reason": "unmatched topic" },
## "status": "error" }, 
## "ref": <null>, 
## "topic": "mensajitos"
# }
func on_message_received(message: Dictionary) -> void:
	print("message received from socket ", message)
	match(message.event):
		ChannelEvents.JOIN:
			print("event joined")
		ChannelEvents.LEAVE:
			print("event leave")
		ChannelEvents.REPLY:
			print("event reply")
		ChannelEvents.CLOSE:
			print("event close")
		ChannelEvents.SYSTEM:
			print("event system")
		ChannelEvents.ERROR:
			print("event error")
		RealtimePostgressChangesListenEvent.INSERT:
			var channel = get_channel_by_topic(message.topic) as GodotSupabaseRealtimeChannel
			if channel:
				channel.inserted.emit(message.payload.record, channel)
		RealtimePostgressChangesListenEvent.UPDATE:
			var channel = get_channel_by_topic(message.topic)
			if channel:
				channel.updated.emit(message.payload.old_record, message.payload.record, channel)
		RealtimePostgressChangesListenEvent.DELETE:
			var channel = get_channel_by_topic(message.topic)
			if channel:
				channel.deleted.emit(message.payload.old_record, channel)


func on_connected(_client: GodotSupabaseRealtimeClient) -> void:
	is_connected = true
