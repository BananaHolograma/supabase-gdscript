class_name GodotSupabaseRealtimeChannel extends Node

## A channel is the basic building block of Realtime
# and narrows the scope of data flow to subscribed clients.
# You can think of a channel as a chatroom where participants are able to see who's online
## and send and receive messages

class ListenTypes:
	const BROADCAST = "broadcast"
	const PRESENCE = "presence"
	const POSTGRES_CHANGES = "postgres_changes"
	
	static func allowed_values() -> Array[String]:
		return [BROADCAST, PRESENCE, POSTGRES_CHANGES]


class RealtimePostgressChangesListenEvent:
	const ALL = "*"
	const INSERT = "INSERT"
	const UPDATE = "UPDATE"
	const DELETE = "DELETE"
	
	static func allowed_values() -> Array[String]:
		return [ALL, INSERT, UPDATE, DELETE]
		
		
class SubscribeStates:
	const SUBSCRIBED = "SUBSCRIBED"
	const TIMED_OUT = "TIMED_OUT"
	const CLOSED = "CLOSED"
	const CHANNEL_ERROR = "CHANNEL_ERROR"
	
	
class RealtimeChannelSendResponse:
	const OK = "ok"
	const TIMED_OUT = "ok"
	const RATE_LIMITED = "rate_limited"
	

var client: GodotSupabaseRealtimeClient

var listen_type: String = ListenTypes.BROADCAST
var schema: String = "any"
var table: String = ""
var event: String = RealtimePostgressChangesListenEvent.ALL
var payload_callback: Callable = _default_callback


var subscribed: bool = false:
	set(value):
		if value != subscribed:
			if value:
				client.add_channel(self)
			else:
				client.remove_channel(self)
		subscribed = value


func _init(realtime_client: GodotSupabaseRealtimeClient, target_schema: String = schema):
	client = realtime_client as GodotSupabaseRealtimeClient
	schema = target_schema


func on(
	selected_listen_type: String = listen_type, 
	filters: Dictionary = {"event": event, "schema": schema, "table": table},
	callback: Callable = payload_callback
	) -> GodotSupabaseRealtimeChannel:
	
	payload_callback = callback 
	
	if selected_listen_type in ListenTypes.allowed_values():
		listen_type = selected_listen_type
			
		for filter in filters.keys():
			if filter == "event" and not filter in RealtimePostgressChangesListenEvent.allowed_values():
				push_error("GodotSupabaseRealtimeChannel: The event {value} is not a valid value, allowed values are ".format({"value": filters[filter], "allowed_values":  RealtimePostgressChangesListenEvent.allowed_values()}))
				continue
				
			self[filter] = filters[filter]
	else:
		push_error("GodotSupabaseRealtimeChannel: The topic {listen_type} is not a valid value, allowed values are {values}".format({"listen_type": listen_type, "values": ",".join(ListenTypes.allowed_values())}))
		
	return self


func subscribe() -> GodotSupabaseRealtimeChannel:
	if subscribed:
		push_error("GodotSupabaseRealtimeChannel: Already subscribed to the channel {schema}".format({"schema": schema}))
	
		client.send_message({
		topic = schema,
		event = client.PhxEvents.JOIN,
		payload = {},
		ref = null
	})
	
	subscribed = true
	
	
	return self

func unsubscribe() -> GodotSupabaseRealtimeChannel:
	if not subscribed:
		push_error("GodotSupabaseRealtimeChannel: Already unsubscribed from channel {schema}".format({"schema": schema}))
	
		client.send_message({
		topic = schema,
		event = client.PhxEvents.LEAVE,
		payload = {},
		ref = null
	})
	
	subscribed = false
	
	return self

func _default_callback(payload):
	push_warning("GodotSupabaseRealtimeChannel: The realtime channel {schema}-{listen_type}-{table} does not have a callback to handle the payload".format({"schema": schema, "listen_type": listen_type, "table": table}))
