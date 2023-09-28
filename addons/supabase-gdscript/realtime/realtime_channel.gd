class_name GodotSupabaseRealtimeChannel extends Node

## A channel is the basic building block of Realtime
# and narrows the scope of data flow to subscribed clients.
# You can think of a channel as a chatroom where participants are able to see who's online
## and send and receive messages

#signal all(old_record, new_record, channel: GodotSupabaseRealtimeChannel)
signal inserted(new_record, channel: GodotSupabaseRealtimeChannel)
signal updated(old_record, new_record, channel: GodotSupabaseRealtimeChannel)
signal deleted(old_record, channel: GodotSupabaseRealtimeChannel)

## Broadcast: sends rapid, ephemeral messages to other connected clients. You can use it to track mouse movements, for example.
## Presence: sends user state between connected clients. You can use it to show an "online" status, which disappears when a user is disconnected.
## Postgres Changes: receives database changes in real-time.
class ListenTypes:
	const BROADCAST = "broadcast"
	const PRESENCE = "presence"
	const POSTGRES_CHANGES = "postgres_changes"
	
	static func allowed_values() -> Array[String]:
		return [BROADCAST, PRESENCE, POSTGRES_CHANGES]
		
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
var config: Dictionary

var topic: String
var internal_name: String
var listen_type: String = ListenTypes.BROADCAST
var schema: String = GodotSupabase.CONFIGURATION["db"]["schema"]
var table: String = ""
var events: Array[String] = ["*"]
var payload_callback: Callable = _default_callback
var filter: String = ""


var subscribed: bool = false:
	set(value):
		if value != subscribed:
			if value:
				client.add_channel(self)
			else:
				client.remove_channel(self)
		subscribed = value


func _init(
	realtime_client: GodotSupabaseRealtimeClient, 
	channel_name: String, 
	params: Dictionary = {"broadcast": { "ack": false, "self": false }}
):
	client = realtime_client as GodotSupabaseRealtimeClient
	internal_name = channel_name
	config = params


func on(
	selected_listen_type: String = listen_type, 
	filters: Dictionary = {"event": events[0], "schema": schema, "table": table, "filter": filter},
	callback: Callable = payload_callback
	) -> GodotSupabaseRealtimeChannel:
	
	payload_callback = callback 
	
	if selected_listen_type in ListenTypes.allowed_values():
		listen_type = selected_listen_type
		schema = filters["schema"] if filters.has("schema") else schema
		table = filters["table"] if filters.has("table") else table
		filter = filters["filter"] if filters.has("filter") else filter
		topic = _build_topic()
		
		var event = filters["event"] if filters.has("event") else events[0]
		if not event in client.RealtimePostgressChangesListenEvent.allowed_values():
			push_error("GodotSupabaseRealtimeChannel: The event {value} is not a valid value, allowed values are ".format({"value": filters[filter], "allowed_values":  client.RealtimePostgressChangesListenEvent.allowed_values()}))
		else:
			if not event in events:
				if event != client.RealtimePostgressChangesListenEvent.ALL:
					events.erase(client.RealtimePostgressChangesListenEvent.ALL)
					events.append(event)
					connect(client.RealtimePostgressChangesListenEvent.signal_name(event), callback)
				else:
					events = [client.RealtimePostgressChangesListenEvent.ALL]
					connect(client.RealtimePostgressChangesListenEvent.signal_name(client.RealtimePostgressChangesListenEvent.INSERT), callback)
					connect(client.RealtimePostgressChangesListenEvent.signal_name(client.RealtimePostgressChangesListenEvent.UPDATE), callback)
					connect(client.RealtimePostgressChangesListenEvent.signal_name(client.RealtimePostgressChangesListenEvent.DELETE), callback)
	else:
		push_error("GodotSupabaseRealtimeChannel: The topic {listen_type} is not a valid value, allowed values are {values}".format({"listen_type": listen_type, "values": ",".join(ListenTypes.allowed_values())}))
	
	return self

## You can use this function to send data
## For example on broadcast
#  channel.send({
#    type: 'broadcast',
#    event: 'test-my-messages',
#    payload: { message: 'talking to myself' },
#  })
##
func send(data: Dictionary) -> void:
	if subscribed:
		client.send_message(data)
	else:
		push_error("GodotSupabaseRealtimeChannel: you need to subscribe on this channel {name} to be able send data".format({"name": internal_name}))


func subscribe() -> GodotSupabaseRealtimeChannel:
	if subscribed:
		push_error("GodotSupabaseRealtimeChannel: Already subscribed to the channel {schema}".format({"schema": schema}))
	else:
		client.send_message({
			"topic": _build_topic(),
			"event": client.ChannelEvents.JOIN,
			"payload": {},
			"ref": null
		})
		
		subscribed = true
	
	
	return self

func unsubscribe() -> GodotSupabaseRealtimeChannel:
	if subscribed:
		client.send_message({
			"topic": _build_topic(),
			"event": client.ChannelEvents.LEAVE,
			"payload": {},
			"ref": null
		})
		
		subscribed = false
	else:
		push_error("GodotSupabaseRealtimeChannel: Already unsubscribed from channel {schema}".format({"schema": schema}))
	
	return self

## realtime:{schema}- where {schema} is the Postgres Schema
## realtime:{schema}:{table} - where {table} is the Postgres table name
## realtime:{schema}:{table}:{col}=eq.{val} where {col} is the column name, and {val} is the value which you want to match
func _build_topic() -> String:
	var topic := "realtime:" + schema
	
	if not table.is_empty():
		topic += ":{table}{filter}".format({"table": table, "filter": "" if filter.is_empty() else ":" + filter})
	
	return topic


func _default_callback(payload):
	push_warning("GodotSupabaseRealtimeChannel: The realtime channel {topic} does not have a callback to handle the payload {payload}".format({"topic": topic, "payload": JSON.stringify(payload)}))
