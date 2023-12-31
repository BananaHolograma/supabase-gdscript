extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	await GodotSupabase.auth.sign_in_with_email("hola4@amigos.com", "password").signed_in_with_email
#	GodotSupabase.storage.list_buckets()
#	GodotSupabase.storage.create_bucket("buckethell2")
#	GodotSupabase.storage.update_bucket("mi-bucket", {"public": false, "file_size_limit": 2048, "allowed_mime_types": ["image/jpeg"]})
#	GodotSupabase.storage.empty_bucket("testing-bucket").delete_bucket("testing-bucket")
#	GodotSupabase.storage.upload_file("buckethell2", "icon.svg", "res://icon.svg")
	GodotSupabase.storage.download_file("buckethell2", "icon.svg")
#	GodotSupabase.storage.get_bucket("mi-bucket")
#	GodotSupabase.realtime.client.connected.connect(on_connected)
#	GodotSupabase.realtime.client.connect_client()
#	GodotSupabase.database.from("countries").select(["id"]).Not("name", "is", null).exec()
#	GodotSupabase.database.from("countries").select(["id"]).Or('id.eq.3,name.eq.Algeria').exec()
#	GodotSupabase.database.query("countries").select(["name", "cities!inner(name)"]).Or('country_id.eq.1,name.eq.Beijing', 'cities').exec()
## THE SELECT ALLOW RETURN ON UPDATE
#	GodotSupabase.database.query("cities").delete().eq("id", "1").exec()
#	GodotSupabase.database.query("countries").select(["name", "cities(name)"]).limit(1, "cities").order("name", {"ascending": false, "foreign_table": "cities"}).exec()
#	GodotSupabase.database.query("countries").select().limit_range(0,1).exec()
#	GodotSupabase.database.Rpc("echo", {"say": "HI BRO"}, {"head": false}).exec()
#	GodotSupabase.database.query("rooms").select().eq("private", "false").neq("waiting_for_players", "false").exec()
#	GodotSupabase.database.query("issues").select(["title"]).contains("tags", ["is:open", "severity:low"]).exec()
#	GodotSupabase.database.query("clowns").select(["name"]).contains("address", {"postcode": 90210}).exec()
#	GodotSupabase.database.query("issues").select(["title"]).overlaps("tags", ['is:closed', 'severity:high']).exec()
#	GodotSupabase.database.query("issues").select(["title"]).text_search("title", "'Cache' & 'cat'", {"type": "plain", "config": "english"}).exec()
#	GodotSupabase.database.query("rooms").select(["code", "host"]).Match({"host": "godgamedev", "scenario": "Dungeon", "server_name": "POLITOXICOMANO"}).exec()
#	GodotSupabase.database.query("reservations").select(["room_name"]).range_gt("during", "[2000-01-01 13:00, 2000-01-01 13:30)").exec()
#	GodotSupabase.database.query("rooms").select(["code"]).In("host", ["AMIYO"]).exec()
#	GodotSupabase.database.query("classes").select(["name"]).contained_by("days", ['monday', 'tuesday', 'wednesday', 'friday']).exec()
#	GodotSupabase.database.query("rooms").select().filters([
#		{"column": "private", "type": "eq", "value": false },
#		{"column": "host", "type": "eq", "value": "AMIYO" },
#		{"column": "max_players", "type": "gt", "value": 14 }
#	]).exec()
#	GodotSupabase.database.query("rooms").insert([{
#		"code": "AAAA",
#		"host":"AMIYO",
#		"server_name": "urologos retirados",
#		"max_players": 13,
#		"players_count": 1,
#		"players": [{"username": "amiyo", "is_host": true}],
#		"rounds": 5,
#		"round_time": 15,
#		"action_queue_limit": 3,
#		"scenario": "Dungeon",
#		"mode": "all_vs_all",
#		"private":  false
#	}]).exec()
##
#	await get_tree().create_timer(1.5).timeout
#
#	GodotSupabase.auth.sign_out()

func on_connected(client: GodotSupabaseRealtimeClient):
	client.channel("schema-db-changes")\
	.on(GodotSupabaseRealtimeChannel.ListenTypes.POSTGRES_CHANGES, 
		{
			"event": GodotSupabaseRealtimeClient.RealtimePostgressChangesListenEvent.INSERT, 
			"schema": "public", 
			"table": "countries"
		},
		 on_payload)\
	.subscribe()

func on_payload(new, channel):
	print("payload received: ", new, channel)

